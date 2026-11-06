const crypto = require('crypto');
const express = require('express');
const db = require('../config/database');
const { authenticate, requireRole } = require('../middleware/auth.middleware');

const router = express.Router();

function isValidUuid(value) {
  return (
    typeof value === 'string' &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)
  );
}


function generateCouponNumber() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = 'DB-';

  for (let i = 0; i < 8; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }

  return code;
}

async function getUniqueCouponNumber(client) {
  let couponNumber = generateCouponNumber();

  let exists = await client.query(
    `SELECT id FROM coupons WHERE coupon_number = $1`,
    [couponNumber]
  );

  while (exists.rows.length > 0) {
    couponNumber = generateCouponNumber();

    exists = await client.query(
      `SELECT id FROM coupons WHERE coupon_number = $1`,
      [couponNumber]
    );
  }

  return couponNumber;
}

/*
 * ============================================================
 * SHOPKEEPER
 * Create coupon campaign
 *
 * NEW RULE:
 * Shopkeeper selects ONLY maximum discount percentage.
 *
 * Example:
 * Max 25%:
 * 15% x 2
 * 20% x 2
 * 25% x 2
 *
 * Total = exactly 6 coupons.
 * ============================================================
 */

router.post(
  '/campaigns',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    const {
      name,
      maxDiscountPercent,
      validityStart,
      validityEnd,
      minBill,
      terms,
    } = req.body;

    if (
      !name ||
      maxDiscountPercent === undefined ||
      !validityStart ||
      !validityEnd
    ) {
      return res.status(400).json({
        success: false,
        message:
          'Name, maximum discount percentage and validity are required',
      });
    }

    if (typeof name !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Campaign name must be a string',
      });
    }

    const campaignName = name.trim();

    if (!campaignName) {
      return res.status(400).json({
        success: false,
        message: 'Campaign name is required',
      });
    }

    if (campaignName.length > 150) {
      return res.status(400).json({
        success: false,
        message: 'Campaign name cannot exceed 150 characters',
      });
    }

    const startDate = new Date(validityStart);
    const endDate = new Date(validityEnd);

    if (
      Number.isNaN(startDate.getTime()) ||
      Number.isNaN(endDate.getTime())
    ) {
      return res.status(400).json({
        success: false,
        message: 'Validity dates must be valid dates',
      });
    }

    if (endDate <= startDate) {
      return res.status(400).json({
        success: false,
        message: 'Validity end must be after validity start',
      });
    }

    const maximumDiscountPercent = Number(maxDiscountPercent);
    const minimumBill =
      minBill === undefined || minBill === null
        ? 0
        : Number(minBill);

    if (
      !Number.isFinite(minimumBill) ||
      minimumBill < 0 ||
      minimumBill > 9999999999.99 ||
      !/^\\d+(?:\\.\\d{1,2})?$/.test(String(minBill ?? 0).trim())
    ) {
      return res.status(400).json({
        success: false,
        message:
          'Minimum bill must be between 0 and 9,999,999,999.99 with up to 2 decimal places',
      });
    }

    if (
      !Number.isFinite(maximumDiscountPercent) ||
      maximumDiscountPercent <= 0 ||
      maximumDiscountPercent > 100
    ) {
      return res.status(400).json({
        success: false,
        message:
          'Maximum discount must be between 1 and 100 percent',
      });
    }

    if (!Number.isFinite(minimumBill) || minimumBill < 0) {
      return res.status(400).json({
        success: false,
        message: 'Minimum bill must be 0 or greater',
      });
    }

    /*
     * Fixed 6 coupon formula:
     *
     * 60% of maximum x 2
     * 80% of maximum x 2
     * 100% of maximum x 2
     *
     * Example max 25:
     * 15, 15, 20, 20, 25, 25
     */
    const discount60 = Number(
      (maximumDiscountPercent * 0.6).toFixed(2)
    );

    const discount80 = Number(
      (maximumDiscountPercent * 0.8).toFixed(2)
    );

    const discount100 = Number(
      maximumDiscountPercent.toFixed(2)
    );

    const couponDiscounts = [
      discount60,
      discount60,
      discount80,
      discount80,
      discount100,
      discount100,
    ];

    const userId = req.user.userId || req.user.id || req.user.sub;

    const client = await db.connect();

    try {
      await client.query('BEGIN');

      /*
       * Find shopkeeper's business.
       */
      const businessResult = await client.query(
        `
        SELECT
          b.id,
          b.business_name
        FROM businesses b
        JOIN shopkeepers s
          ON s.id = b.shopkeeper_id
        WHERE s.user_id = $1
        ORDER BY b.created_at DESC
        LIMIT 1
        `,
        [userId]
      );

      if (businessResult.rows.length === 0) {

        return res.status(404).json({
          success: false,
          message: 'Business not found',
        });
      }

      const business = businessResult.rows[0];

      /*
       * Every campaign always contains exactly 6 coupons.
       */
      const campaignResult = await client.query(
        `
        INSERT INTO coupon_campaigns
        (
          business_id,
          name,
          selection_mode,
          validity_start,
          validity_end,
          usage_limit,
          min_bill,
          max_discount,
          terms,
          is_active
        )
        VALUES
        ($1, $2, 'SEQUENTIAL', $3, $4, 6, $5, $6, $7, true)
        RETURNING *
        `,
        [
          business.id,
          campaignName,
          validityStart,
          validityEnd,
          minimumBill,
          maximumDiscountPercent,
          terms || null,
        ]
      );

      const campaign = campaignResult.rows[0];

      const coupons = [];

      /*
       * Generate exactly 6 scratch coupons.
       */
      for (const discount of couponDiscounts) {
        const couponNumber = await getUniqueCouponNumber(client);

        const couponResult = await client.query(
          `
          INSERT INTO coupons
          (
            campaign_id,
            coupon_number,
            discount_percent,
            coupon_type,
            status
          )
          VALUES
          ($1, $2, $3, 'PERCENTAGE', 'AVAILABLE')
          RETURNING
            id,
            coupon_number,
            discount_percent,
            coupon_type,
            status
          `,
          [
            campaign.id,
            couponNumber,
            discount,
          ]
        );

        coupons.push(couponResult.rows[0]);
      }

      await client.query('COMMIT');

      return res.status(201).json({
        success: true,
        message: '6 scratch coupons created successfully',
        data: {
          campaign,
          business,
          totalCoupons: 6,
          maximumDiscountPercent,
          couponDistribution: {
            sixtyPercent: {
              discount: discount60,
              quantity: 2,
            },
            eightyPercent: {
              discount: discount80,
              quantity: 2,
            },
            maximum: {
              discount: discount100,
              quantity: 2,
            },
          },
          coupons,
        },
      });
    } catch (error) {

      console.error('Create coupon campaign error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to create coupon campaign',
      });
    } finally {
      client.release();
    }
  }
);

/*
 * ============================================================
 * SHOPKEEPER
 * View own coupon campaigns
 * ============================================================
 */

router.get(
  '/my-campaigns',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    try {
      const userId =
        req.user.userId || req.user.id || req.user.sub;

      const result = await db.query(
        `
        SELECT
          cc.*,
          b.business_name,

          COUNT(c.id)::integer AS total_coupons,

          COUNT(c.id)
            FILTER (WHERE c.status = 'AVAILABLE')::integer
            AS available_coupons,

          COUNT(c.id)
            FILTER (WHERE c.status = 'CLAIMED')::integer
            AS claimed_coupons,

          COUNT(c.id)
            FILTER (WHERE c.status = 'USED')::integer
            AS used_coupons

        FROM coupon_campaigns cc

        JOIN businesses b
          ON b.id = cc.business_id

        JOIN shopkeepers s
          ON s.id = b.shopkeeper_id

        LEFT JOIN coupons c
          ON c.campaign_id = cc.id

        WHERE s.user_id = $1

        GROUP BY
          cc.id,
          b.business_name

        ORDER BY cc.created_at DESC
        `,
        [userId]
      );

      return res.json({
        success: true,
        data: result.rows,
      });
    } catch (error) {
      console.error('My campaigns error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to load coupon campaigns',
      });
    }
  }
);

/*
 * ============================================================
 * SHOPKEEPER
 * View individual coupons of own campaign
 * ============================================================
 */

router.get(
  '/my-campaigns/:campaignId/coupons',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    try {
      const userId =
        req.user.userId || req.user.id || req.user.sub;

      const { campaignId } = req.params;

      const result = await db.query(
        `
        SELECT
          c.id,
          c.campaign_id,
          c.coupon_number,
          c.discount_percent,
          c.coupon_type,
          c.status,

          cc.name AS campaign_name,
          cc.validity_start,
          cc.validity_end,
          cc.min_bill,
          cc.max_discount,
          cc.terms

        FROM coupons c

        JOIN coupon_campaigns cc
          ON cc.id = c.campaign_id

        JOIN businesses b
          ON b.id = cc.business_id

        JOIN shopkeepers s
          ON s.id = b.shopkeeper_id

        WHERE cc.id = $1
          AND s.user_id = $2

        ORDER BY c.created_at ASC
        `,
        [campaignId, userId]
      );

      return res.json({
        success: true,
        data: result.rows,
      });
    } catch (error) {
      console.error('My campaign coupons error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to load campaign coupons',
      });
    }
  }
);

/*
 * ============================================================
 * CUSTOMER
 * Public active coupon campaigns
 *
 * NOTE:
 * Individual coupon discounts are NOT exposed here.
 * Customer will later receive coupons according to
 * General/Premium membership rules.
 * ============================================================
 */


/*
 * CUSTOMER
 * Get customer-specific scratch coupons.
 *
 * Every customer gets a separate 6-coupon set for each active shop campaign.
 * Discount pattern:
 * 60% of maximum x2
 * 80% of maximum x2
 * 100% of maximum x2
 */
router.get(
  '/my-coupons',
  authenticate,
  requireRole('CUSTOMER'),
  async (req, res) => {
    const customerId = req.user.userId || req.user.id || req.user.sub;
    const client = await db.connect();

    try {
      await client.query('BEGIN');

      const campaignsResult = await client.query(
        `
        SELECT
          cc.id,
          cc.business_id,
          cc.name,
          cc.validity_start,
          cc.validity_end,
          cc.min_bill,
          cc.max_discount,
          cc.terms,
          cc.selection_mode,
          b.business_name,
          b.address,
          b.city_id
        FROM coupon_campaigns cc
        JOIN businesses b
          ON b.id = cc.business_id
        JOIN shopkeepers s
          ON s.id = b.shopkeeper_id
        WHERE cc.is_active = true
          AND b.is_public = true
          AND s.verification_status = 'VERIFIED'
          AND cc.validity_start <= NOW()
          AND cc.validity_end >= NOW()
        ORDER BY cc.created_at DESC
        `
      );

      for (const campaign of campaignsResult.rows) {
        const existingResult = await client.query(
          `
          SELECT COUNT(*)::integer AS count
          FROM coupons
          WHERE campaign_id = $1
            AND customer_id = $2
          `,
          [campaign.id, customerId]
        );

        const existingCount = existingResult.rows[0].count;

        if (existingCount < 6) {
          const maxDiscount = Number(campaign.max_discount || 0);

          let discounts = [];

          if (maxDiscount > 0) {
            discounts = [
              maxDiscount * 0.60,
              maxDiscount * 0.60,
              maxDiscount * 0.80,
              maxDiscount * 0.80,
              maxDiscount,
              maxDiscount,
            ];
          } else {
            const templateResult = await client.query(
              `
              SELECT discount_percent
              FROM coupons
              WHERE campaign_id = $1
                AND customer_id IS NULL
              ORDER BY created_at ASC
              LIMIT 6
              `,
              [campaign.id]
            );

            discounts = templateResult.rows.map(
              (row) => Number(row.discount_percent)
            );
          }

          if (discounts.length === 6) {
            for (let i = 0; i < 6; i++) {
              const discount = Math.min(
                Number(discounts[i]),
                Number(maxDiscount || discounts[i])
              );

              await client.query(
                `
                INSERT INTO coupons
                (
                  campaign_id,
                  customer_id,
                  slot_number,
                  coupon_number,
                  discount_percent,
                  coupon_type,
                  status
                )
                VALUES
                ($1, $2, $3, $4, $5, 'PERCENTAGE', 'AVAILABLE')
                ON CONFLICT (campaign_id, customer_id, slot_number)
                WHERE customer_id IS NOT NULL
                DO NOTHING
                `,
                [
                  campaign.id,
                  customerId,
                  i + 1,
                  generateCouponNumber(),
                  discount.toFixed(2),
                ]
              );
            }
          }
        }
      }

      const couponsResult = await client.query(
        `
        SELECT
          c.id,
          c.campaign_id,
          c.customer_id,
          c.slot_number,
          c.coupon_number,
          c.discount_percent,
          c.coupon_type,
          c.status,
          cc.name AS campaign_name,
          cc.validity_start,
          cc.validity_end,
          cc.min_bill,
          cc.max_discount,
          cc.terms,
          b.id AS business_id,
          b.business_name,
          b.address,
          b.city_id
        FROM coupons c
        JOIN coupon_campaigns cc
          ON cc.id = c.campaign_id
        JOIN businesses b
          ON b.id = cc.business_id
        WHERE c.customer_id = $1
        ORDER BY b.business_name, cc.created_at DESC, c.slot_number ASC
        `,
        [customerId]
      );

      await client.query('COMMIT');

      return res.json({
        success: true,
        data: couponsResult.rows,
      });
    } catch (error) {

      console.error('Customer coupons error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to load customer coupons',
      });
    } finally {
      client.release();
    }
  }
);


/*
 * CUSTOMER
 * Open coupons for one specific shop/business.
 *
 * Every shop has its own 6-coupon set per customer.
 * Discount pattern is based ONLY on that shopkeeper's max_discount:
 * 60%, 60%, 80%, 80%, 100%, 100%.
 */
router.post(
  '/shop/:businessId/open',
  authenticate,
  requireRole('CUSTOMER'),
  async (req, res) => {
    const customerId = req.user.userId || req.user.id || req.user.sub;
    const { businessId } = req.params;

    const client = await db.connect();

    try {
      await client.query('BEGIN');

      const businessResult = await client.query(
        `
        SELECT
          b.id,
          b.business_name,
          b.address,
          b.city_id,
          cc.id AS campaign_id,
          cc.name AS campaign_name,
          cc.validity_start,
          cc.validity_end,
          cc.min_bill,
          cc.max_discount,
          cc.terms,
          cc.selection_mode
        FROM businesses b
        JOIN shopkeepers s
          ON s.id = b.shopkeeper_id
        JOIN coupon_campaigns cc
          ON cc.business_id = b.id
        WHERE b.id = $1
          AND b.is_public = true
          AND s.verification_status = 'VERIFIED'
          AND cc.is_active = true
          AND cc.validity_start <= NOW()
          AND cc.validity_end >= NOW()
        ORDER BY cc.created_at DESC
        LIMIT 1
        `,
        [businessId]
      );

      if (businessResult.rows.length === 0) {

        return res.status(404).json({
          success: false,
          message: 'No active coupon offer found for this shop',
        });
      }

      const campaign = businessResult.rows[0];

      const existingResult = await client.query(
        `
        SELECT
          id,
          campaign_id,
          customer_id,
          slot_number,
          coupon_number,
          discount_percent,
          coupon_type,
          status
        FROM coupons
        WHERE campaign_id = $1
          AND customer_id = $2
        ORDER BY slot_number ASC
        `,
        [campaign.campaign_id, customerId]
      );

      const existingSlots = new Set(
        existingResult.rows.map((row) => Number(row.slot_number))
      );

      const maxDiscount = Number(campaign.max_discount);

      if (!Number.isFinite(maxDiscount) || maxDiscount <= 0) {

        return res.status(400).json({
          success: false,
          message: 'Shop maximum discount is not configured correctly',
        });
      }

      const discounts = [
        maxDiscount * 0.60,
        maxDiscount * 0.60,
        maxDiscount * 0.80,
        maxDiscount * 0.80,
        maxDiscount,
        maxDiscount,
      ];

      for (let i = 0; i < discounts.length; i++) {
        const slot = i + 1;

        if (existingSlots.has(slot)) {
          continue;
        }

        const discount = Math.min(discounts[i], maxDiscount);

        await client.query(
          `
          INSERT INTO coupons
          (
            campaign_id,
            customer_id,
            slot_number,
            coupon_number,
            discount_percent,
            coupon_type,
            status
          )
          VALUES
          ($1, $2, $3, $4, $5, 'PERCENTAGE', 'AVAILABLE')
          ON CONFLICT DO NOTHING
          `,
          [
            campaign.campaign_id,
            customerId,
            slot,
            generateCouponNumber(),
            discount.toFixed(2),
          ]
        );
      }

      const couponsResult = await client.query(
        `
        SELECT
          c.id,
          c.campaign_id,
          c.customer_id,
          c.slot_number,
          c.coupon_number,
          c.discount_percent,
          c.coupon_type,
          c.status,
          cc.name AS campaign_name,
          cc.validity_start,
          cc.validity_end,
          cc.min_bill,
          cc.max_discount,
          cc.terms,
          b.id AS business_id,
          b.business_name,
          b.address,
          b.city_id
        FROM coupons c
        JOIN coupon_campaigns cc
          ON cc.id = c.campaign_id
        JOIN businesses b
          ON b.id = cc.business_id
        WHERE c.campaign_id = $1
          AND c.customer_id = $2
        ORDER BY c.slot_number ASC
        `,
        [campaign.campaign_id, customerId]
      );

      await client.query('COMMIT');

      return res.json({
        success: true,
        message: 'Shop coupons opened successfully',
        data: {
          businessId: campaign.id,
          businessName: campaign.business_name,
          campaignId: campaign.campaign_id,
          campaignName: campaign.campaign_name,
          maxDiscount: campaign.max_discount,
          coupons: couponsResult.rows,
        },
      });
    } catch (error) {
      await client.query('ROLLBACK');

      console.error('Shop coupon open error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to open shop coupons',
      });
    } finally {
      client.release();
    }
  }
);

router.get('/available', async (req, res) => {
  try {
    const result = await db.query(
      `
      SELECT
        cc.id,
        cc.business_id,
        cc.name,
        cc.validity_start,
        cc.validity_end,
        cc.usage_limit,
        cc.min_bill,
        cc.max_discount,
        cc.terms,

        b.business_name,
        b.address,
        b.city

      FROM coupon_campaigns cc

      JOIN businesses b
        ON b.id = cc.business_id

      WHERE cc.is_active = true
        AND b.is_public = true
        AND cc.validity_start <= NOW()
        AND cc.validity_end >= NOW()

      ORDER BY cc.created_at DESC
      `,
      []
    );

    return res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error('Available coupons error:', error);

    return res.status(500).json({
      success: false,
      message: 'Failed to load available coupons',
    });
  }
});

/*
 * ============================================================
 * CUSTOMER
 * Claim one scratch coupon
 * ============================================================
 */

router.post(
  '/claim',
  authenticate,
  requireRole('CUSTOMER'),
  async (req, res) => {
    const { couponId } = req.body;

    if (!couponId) {
      return res.status(400).json({
        success: false,
        message: 'couponId is required',
      });
    }

    if (!isValidUuid(couponId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid coupon ID',
      });
    }

    const customerId =
      req.user.userId || req.user.id || req.user.sub;

    const client = await db.connect();

    try {
      await client.query('BEGIN');

      const couponResult = await client.query(
        `
        SELECT
          c.id,
          c.coupon_number,
          c.slot_number,
          c.customer_id,
          c.discount_percent,
          c.coupon_type,
          c.status,

          cc.id AS campaign_id,
          cc.validity_start,
          cc.validity_end,
          cc.min_bill,
          cc.max_discount,
          cc.terms,
          cc.is_active AS campaign_is_active,
          b.is_public AS business_is_public,
          s.verification_status AS shop_verification_status

        FROM coupons c

        JOIN coupon_campaigns cc
          ON cc.id = c.campaign_id

        JOIN businesses b
          ON b.id = cc.business_id

        JOIN shopkeepers s
          ON s.id = b.shopkeeper_id

        WHERE c.id = $1

        FOR UPDATE
        `,
        [couponId]
      );

      if (couponResult.rows.length === 0) {
        await client.query('ROLLBACK');

        return res.status(404).json({
          success: false,
          message: 'Coupon not found',
        });
      }

      const coupon = couponResult.rows[0];

      if (coupon.status !== 'AVAILABLE') {
        await client.query('ROLLBACK');

        return res.status(400).json({
          success: false,
          message: 'Coupon is no longer available',
        });
      }

      const now = new Date();

      if (
        now < new Date(coupon.validity_start) ||
        now > new Date(coupon.validity_end)
      ) {
        await client.query('ROLLBACK');

        return res.status(400).json({
          success: false,
          message:
            'Coupon validity has expired or has not started',
        });
      }

      // ------------------------------------------------------
      // PUBLIC + VERIFIED SHOP + ACTIVE CAMPAIGN PROTECTION
      // ------------------------------------------------------

      if (!coupon.business_is_public) {
        await client.query('ROLLBACK');

        return res.status(403).json({
          success: false,
          message: 'This shop is not publicly available',
        });
      }

      if (coupon.shop_verification_status !== 'VERIFIED') {
        await client.query('ROLLBACK');

        return res.status(403).json({
          success: false,
          message: 'This shop is not verified',
        });
      }

      if (!coupon.campaign_is_active) {
        await client.query('ROLLBACK');

        return res.status(400).json({
          success: false,
          message: 'This coupon campaign is inactive',
        });
      }

      // ------------------------------------------------------
      // CUSTOMER OWNERSHIP + SEQUENTIAL COUPON PROTECTION
      // ------------------------------------------------------

      // A customer can only claim their own coupon.
      if (String(coupon.customer_id) !== String(customerId)) {
        await client.query('ROLLBACK');

        return res.status(403).json({
          success: false,
          message: 'This coupon does not belong to this customer',
        });
      }

      // Coupon #1 can be claimed directly.
      // Coupon #2-#6 require the previous coupon to be
      // already claimed or used by the same customer.
      if (Number(coupon.slot_number) > 1) {
        const previousSlot = Number(coupon.slot_number) - 1;

        const previousCouponResult = await client.query(
          `
          SELECT id, status
          FROM coupons
          WHERE campaign_id = $1
            AND customer_id = $2
            AND slot_number = $3
          FOR UPDATE
          `,
          [
            coupon.campaign_id,
            customerId,
            previousSlot,
          ]
        );

        if (previousCouponResult.rows.length === 0) {
          await client.query('ROLLBACK');

          return res.status(400).json({
            success: false,
            message: 'Previous coupon must be claimed first',
          });
        }

        const previousCoupon = previousCouponResult.rows[0];

        if (
          previousCoupon.status !== 'CLAIMED' &&
          previousCoupon.status !== 'USED'
        ) {
          await client.query('ROLLBACK');

          return res.status(400).json({
            success: false,
            message: 'Previous coupon must be claimed first',
          });
        }
      }

      const verificationCode = crypto
        .randomInt(1000, 10000)
        .toString();

      const claimResult = await client.query(
        `
        INSERT INTO coupon_claims
        (
          coupon_id,
          customer_id,
          verification_code,
          status
        )
        VALUES
        ($1, $2, $3, 'CLAIMED')
        RETURNING *
        `,
        [coupon.id, customerId, verificationCode]
      );

      await client.query(
        `
        UPDATE coupons
        SET status = 'CLAIMED'
        WHERE id = $1
        `,
        [coupon.id]
      );

      await client.query('COMMIT');

      return res.status(201).json({
        success: true,
        message: 'Coupon claimed successfully',
        data: {
          claim: claimResult.rows[0],
          coupon: {
            id: coupon.id,
            couponNumber: coupon.coupon_number,
            discountPercent: coupon.discount_percent,
            couponType: coupon.coupon_type,
            minBill: coupon.min_bill,
            maxDiscount: coupon.max_discount,
            terms: coupon.terms,
          },
        },
      });
    } catch (error) {
      await client.query('ROLLBACK');

      console.error('Coupon claim error:', error);

      if (error.code === '23505') {
        return res.status(400).json({
          success: false,
          message: 'This coupon has already been claimed',
        });
      }

      return res.status(500).json({
        success: false,
        message: 'Failed to claim coupon',
      });
    } finally {
      client.release();
    }
  }
);


/*
 * ============================================================
 * SHOPKEEPER
 * Get claimed coupons for this shop
 * ============================================================
 */
router.get(
  '/shopkeeper/claimed',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    const userId = req.user.userId || req.user.id || req.user.sub;

    try {
      const result = await db.query(
        `
        SELECT
          c.id AS coupon_id,
          c.coupon_number,
          c.discount_percent,
          c.status AS coupon_status,

          cl.id AS claim_id,
          cl.customer_id,
          cl.claimed_at,
          cl.verification_code,
          cl.status AS claim_status,

          cc.id AS campaign_id,
          cc.name AS campaign_name,
          cc.min_bill,
          cc.max_discount,
          cc.validity_start,
          cc.validity_end,

          b.id AS business_id,
          b.business_name

        FROM coupon_claims cl

        JOIN coupons c
          ON c.id = cl.coupon_id

        JOIN coupon_campaigns cc
          ON cc.id = c.campaign_id

        JOIN businesses b
          ON b.id = cc.business_id

        JOIN shopkeepers s
          ON s.id = b.shopkeeper_id

        WHERE s.user_id = $1
          AND cl.status = 'CLAIMED'
          AND c.status = 'CLAIMED'

        ORDER BY cl.claimed_at DESC
        `,
        [userId]
      );

      return res.json({
        success: true,
        data: result.rows,
      });
    } catch (error) {
      console.error('Shopkeeper claimed coupons error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to load claimed coupons',
      });
    }
  }
);


/*
 * ============================================================
 * SHOPKEEPER
 * Calculate transaction / discount
 * ============================================================
 */
/*
 * Verify scanned coupon QR for the logged-in shopkeeper
 */
router.get(
  '/shopkeeper/verify-qr/:couponId',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    const userId = req.user.userId || req.user.id || req.user.sub;
    const { couponId } = req.params;

    if (!isValidUuid(couponId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid coupon ID',
      });
    }

    try {
      const result = await db.query(
        `
        SELECT
          c.id AS coupon_id,
          c.coupon_number,
          c.discount_percent,
          cl.customer_id,
          cl.status AS claim_status,
          cc.min_bill,
          cc.validity_start,
          cc.validity_end,
          b.id AS business_id,
          b.business_name
        FROM coupons c
        JOIN coupon_claims cl ON cl.coupon_id = c.id
        JOIN coupon_campaigns cc ON cc.id = c.campaign_id
        JOIN businesses b ON b.id = cc.business_id
        JOIN shopkeepers s ON s.id = b.shopkeeper_id
        WHERE c.id = $1
          AND s.user_id = $2
          AND c.status = 'CLAIMED'
          AND cl.status = 'CLAIMED'
        LIMIT 1
        `,
        [couponId, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Coupon is invalid, already used, or does not belong to your shop.',
        });
      }

      return res.json({
        success: true,
        data: result.rows[0],
      });
    } catch (error) {
      console.error('QR coupon verification error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to verify QR coupon',
      });
    }
  }
);

router.post(
  '/calculate',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    const userId = req.user.userId || req.user.id || req.user.sub;
    const { couponId, originalBill, verificationCode } = req.body;

    const bill = Number(originalBill);

    if (!couponId || !Number.isFinite(bill) || bill < 0) {
      return res.status(400).json({
        success: false,
        message: 'Coupon ID and valid bill amount are required',
      });
    }

    try {
      const result = await db.query(
        `
        SELECT
          c.id AS coupon_id,
          c.coupon_number,
          c.discount_percent,
          c.status AS coupon_status,

          cl.id AS claim_id,
          cl.customer_id,
          cl.verification_code,
          cl.status AS claim_status,

          cc.id AS campaign_id,
          cc.name AS campaign_name,
          cc.min_bill,
          cc.max_discount,
          cc.validity_start,
          cc.validity_end,

          b.id AS business_id,
          b.business_name

        FROM coupons c

        JOIN coupon_claims cl
          ON cl.coupon_id = c.id

        JOIN coupon_campaigns cc
          ON cc.id = c.campaign_id

        JOIN businesses b
          ON b.id = cc.business_id

        JOIN shopkeepers s
          ON s.id = b.shopkeeper_id

        WHERE c.id = $1
          AND s.user_id = $2
          AND c.status = 'CLAIMED'
          AND cl.status = 'CLAIMED'
        `,
        [couponId, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Valid claimed coupon not found for this shop',
        });
      }

      const coupon = result.rows[0];

      if (!verificationCode) {
        return res.status(400).json({
          success: false,
          message: 'Verification code is required',
        });
      }

      if (
        !coupon.verification_code ||
        String(verificationCode).trim() !==
          String(coupon.verification_code).trim()
      ) {
        return res.status(400).json({
          success: false,
          message: 'Invalid verification code',
        });
      }

      const now = new Date();
      const start = new Date(coupon.validity_start);
      const end = new Date(coupon.validity_end);

      if (now < start || now > end) {
        return res.status(400).json({
          success: false,
          message: 'This coupon is not currently valid',
        });
      }

      const minBill = Number(coupon.min_bill || 0);

      if (bill < minBill) {
        return res.status(400).json({
          success: false,
          message: `Minimum bill amount is ₹${minBill.toFixed(2)}`,
        });
      }

      const discountPercent = Number(coupon.discount_percent || 0);
      const discountAmount = Number(
        ((bill * discountPercent) / 100).toFixed(2)
      );
      const finalAmount = Number(
        (bill - discountAmount).toFixed(2)
      );

      return res.json({
        success: true,
        data: {
          couponId: coupon.coupon_id,
          couponNumber: coupon.coupon_number,
          businessId: coupon.business_id,
          businessName: coupon.business_name,
          originalBill: bill,
          discountPercent,
          discountAmount,
          finalAmount,
          minBill,
        },
      });
    } catch (error) {
      console.error('Calculate transaction error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to calculate transaction',
      });
    }
  }
);


/*
 * ============================================================
 * SHOPKEEPER
 * Confirm / complete transaction
 * ============================================================
 */
router.post(
  '/confirm',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    const userId = req.user.userId || req.user.id || req.user.sub;
    const { couponId, originalBill } = req.body;

    const bill = Number(originalBill);

    if (!couponId || !Number.isFinite(bill) || bill < 0) {
      return res.status(400).json({
        success: false,
        message: 'Coupon ID and valid bill amount are required',
      });
    }

    const client = await db.connect();

    try {
      await client.query('BEGIN');

      const result = await client.query(
        `
        SELECT
          c.id AS coupon_id,
          c.coupon_number,
          c.discount_percent,
          c.status AS coupon_status,

          cl.id AS claim_id,
          cl.customer_id,
          cl.verification_code,
          cl.status AS claim_status,

          cc.id AS campaign_id,
          cc.min_bill,
          cc.validity_start,
          cc.validity_end,

          b.id AS business_id,
          b.business_name

        FROM coupons c

        JOIN coupon_claims cl
          ON cl.coupon_id = c.id

        JOIN coupon_campaigns cc
          ON cc.id = c.campaign_id

        JOIN businesses b
          ON b.id = cc.business_id

        JOIN shopkeepers s
          ON s.id = b.shopkeeper_id

        WHERE c.id = $1
          AND s.user_id = $2
          AND c.status = 'CLAIMED'
          AND cl.status = 'CLAIMED'

        FOR UPDATE OF c, cl
        `,
        [couponId, userId]
      );

      if (result.rows.length === 0) {
        await client.query('ROLLBACK');

        return res.status(404).json({
          success: false,
          message: 'Valid claimed coupon not found for this shop',
        });
      }

      const coupon = result.rows[0];

      const now = new Date();
      const start = new Date(coupon.validity_start);
      const end = new Date(coupon.validity_end);

      if (now < start || now > end) {
        await client.query('ROLLBACK');

        return res.status(400).json({
          success: false,
          message: 'This coupon is not currently valid',
        });
      }

      const minBill = Number(coupon.min_bill || 0);

      if (bill < minBill) {
        await client.query('ROLLBACK');

        return res.status(400).json({
          success: false,
          message: `Minimum bill amount is ₹${minBill.toFixed(2)}`,
        });
      }

      const discountPercent = Number(coupon.discount_percent || 0);
      const discountAmount = Number(
        ((bill * discountPercent) / 100).toFixed(2)
      );
      const finalAmount = Number(
        (bill - discountAmount).toFixed(2)
      );

      const transactionCode =
        `DB-TXN-${Date.now()}-${Math.floor(Math.random() * 10000)
          .toString()
          .padStart(4, '0')}`;

      const transactionVerificationCode =
        String(coupon.verification_code);

      const transactionResult = await client.query(
        `
        INSERT INTO transactions (
          transaction_code,
          coupon_id,
          customer_id,
          business_id,
          original_bill,
          discount_percent,
          discount_amount,
          final_amount,
          verification_code,
          status,
          completed_at
        )
        VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, 'COMPLETED', NOW()
        )
        RETURNING *
        `,
        [
          transactionCode,
          coupon.coupon_id,
          coupon.customer_id,
          coupon.business_id,
          bill,
          discountPercent,
          discountAmount,
          finalAmount,
          transactionVerificationCode,
        ]
      );

      await client.query(
        `
        UPDATE coupon_claims
        SET
          status = 'USED',
          transaction_id = $1
        WHERE id = $2
        `,
        [transactionResult.rows[0].id, coupon.claim_id]
      );

      await client.query(
        `
        UPDATE coupons
        SET status = 'USED'
        WHERE id = $1
        `,
        [coupon.coupon_id]
      );

      await client.query('COMMIT');

      return res.json({
        success: true,
        message: 'Transaction completed successfully',
        data: {
          transaction: transactionResult.rows[0],
          couponNumber: coupon.coupon_number,
          originalBill: bill,
          discountPercent,
          discountAmount,
          finalAmount,
          verificationCode: transactionVerificationCode,
        },
      });
    } catch (error) {
      await client.query('ROLLBACK');

      console.error('Confirm transaction error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to complete transaction',
      });
    } finally {
      client.release();
    }
  }
);

module.exports = router;