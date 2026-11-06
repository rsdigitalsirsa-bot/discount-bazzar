const express = require('express');
const db = require('../config/database');
const { authenticate, requireRole } = require('../middleware/auth.middleware');

const router = express.Router();

function isValidUuid(value) {
  return typeof value === 'string' &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}


/*
 * SHOPKEEPER
 * Calculate transaction for a claimed coupon.
 */
router.post(
  '/calculate',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    const { couponId, billAmount } = req.body;

    if (!couponId || billAmount === undefined) {
      return res.status(400).json({
        success: false,
        message: 'couponId and billAmount are required',
      });
    }

    if (!isValidUuid(couponId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid coupon ID',
      });
    }

    const originalBill = Number(billAmount);

    if (
      !Number.isFinite(originalBill) ||
      originalBill < 0 ||
      originalBill > 9999999999.99 ||
      Math.round(originalBill * 100) / 100 !== originalBill
    ) {
      return res.status(400).json({
        success: false,
        message: 'Invalid bill amount. Maximum ₹9,999,999,999.99 and up to 2 decimal places allowed.',
      });
    }

    const userId = req.user.userId || req.user.id || req.user.sub;

    try {
      const result = await db.query(
        `
        SELECT
          c.id AS coupon_id,
          c.coupon_number,
          c.discount_percent,
          c.status AS coupon_status,

          cc.min_bill,
          cc.validity_start,
          cc.validity_end,

          b.id AS business_id,
          b.business_name,

          s.id AS shopkeeper_id,
          s.user_id AS shopkeeper_user_id,

          cl.id AS claim_id,
          cl.customer_id,
          cl.verification_code,
          cl.status AS claim_status

        FROM coupons c

        JOIN coupon_campaigns cc
          ON cc.id = c.campaign_id

        JOIN businesses b
          ON b.id = cc.business_id

        JOIN shopkeepers s
          ON s.id = b.shopkeeper_id

        JOIN coupon_claims cl
          ON cl.coupon_id = c.id

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
          message: 'Coupon not found or does not belong to this shop',
        });
      }

      const coupon = result.rows[0];

      if (coupon.coupon_status !== 'CLAIMED') {
        return res.status(400).json({
          success: false,
          message: `Coupon cannot be used. Current status: ${coupon.coupon_status}`,
        });
      }

      if (coupon.claim_status !== 'CLAIMED') {
        return res.status(400).json({
          success: false,
          message: `Coupon claim is not active. Current status: ${coupon.claim_status}`,
        });
      }

      const now = new Date();

      if (
        now < new Date(coupon.validity_start) ||
        now > new Date(coupon.validity_end)
      ) {
        return res.status(400).json({
          success: false,
          message: 'Coupon validity has expired or has not started',
        });
      }

      const minBill = Number(coupon.min_bill || 0);
      const discountPercent = Number(coupon.discount_percent);
      if (
        !Number.isFinite(discountPercent) ||
        discountPercent < 0 ||
        discountPercent > 100
      ) {
        return res.status(400).json({
          success: false,
          message: 'Invalid discount percentage',
        });
      }
      if (originalBill < minBill) {
        return res.status(400).json({
          success: false,
          message: `Minimum bill amount is ₹${minBill.toFixed(2)}`,
        });
      }

const discountAmount = Number(
  (originalBill * (discountPercent / 100)).toFixed(2)
);

const finalAmount = Number(
  (originalBill - discountAmount).toFixed(2)
);

      return res.json({
        success: true,
        message: 'Transaction calculated successfully',
        data: {
          couponId: coupon.coupon_id,
          couponNumber: coupon.coupon_number,
          customerId: coupon.customer_id,
          businessId: coupon.business_id,
          businessName: coupon.business_name,
          originalBill: Number(originalBill.toFixed(2)),
          discountPercent,
          discountAmount: Number(discountAmount.toFixed(2)),
          finalAmount: Number(finalAmount.toFixed(2)),
          minBill,
        },
      });
    } catch (error) {
      console.error('Transaction calculation error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to calculate transaction',
      });
    }
  }
);

/*
 * SHOPKEEPER
 * Confirm transaction and mark coupon as USED.
 */
router.post(
  '/confirm',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    const {
      couponId,
      billAmount,
      verificationCode,
    } = req.body;

    if (!couponId || billAmount === undefined) {
      return res.status(400).json({
        success: false,
        message: 'couponId and billAmount are required',
      });
    }

    if (!isValidUuid(couponId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid coupon ID',
      });
    }

    const originalBill = Number(billAmount);

    if (
      !Number.isFinite(originalBill) ||
      originalBill < 0 ||
      originalBill > 9999999999.99 ||
      Math.round(originalBill * 100) / 100 !== originalBill
    ) {
      return res.status(400).json({
        success: false,
        message: 'Invalid bill amount. Maximum ₹9,999,999,999.99 and up to 2 decimal places allowed.',
      });
    }

    const userId = req.user.userId || req.user.id || req.user.sub;
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

          cc.min_bill,
          cc.validity_start,
          cc.validity_end,

          b.id AS business_id,
          b.business_name,

          s.id AS shopkeeper_id,
          s.user_id AS shopkeeper_user_id,

          cl.id AS claim_id,
          cl.customer_id,
          cl.status AS claim_status,
          cl.verification_code

        FROM coupons c

        JOIN coupon_campaigns cc
          ON cc.id = c.campaign_id

        JOIN businesses b
          ON b.id = cc.business_id

        JOIN shopkeepers s
          ON s.id = b.shopkeeper_id

        JOIN coupon_claims cl
          ON cl.coupon_id = c.id

        WHERE c.id = $1
          AND s.user_id = $2
          AND c.status = 'CLAIMED'
          AND cl.status = 'CLAIMED'

          FOR UPDATE
        `,
        [couponId, userId]
      );

      if (result.rows.length === 0) {
        await client.query('ROLLBACK');

        return res.status(404).json({
          success: false,
          message: 'Coupon not found or does not belong to this shop',
        });
      }

      const coupon = result.rows[0];

      if (coupon.coupon_status !== 'CLAIMED') {
        await client.query('ROLLBACK');

        return res.status(400).json({
          success: false,
          message: `Coupon cannot be used. Current status: ${coupon.coupon_status}`,
        });
      }

      if (coupon.claim_status !== 'CLAIMED') {
        await client.query('ROLLBACK');

        return res.status(400).json({
          success: false,
          message: `Coupon claim is not active. Current status: ${coupon.claim_status}`,
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
          message: 'Coupon validity has expired or has not started',
        });
      }

      const minBill = Number(coupon.min_bill || 0);
      const discountPercent = Number(coupon.discount_percent);

      if (
        !Number.isFinite(discountPercent) ||
        discountPercent < 0 ||
        discountPercent > 100
      ) {
        await client.query('ROLLBACK');

        return res.status(400).json({
          success: false,
          message: 'Invalid discount percentage',
        });
      }

      if (originalBill < minBill) {
        await client.query('ROLLBACK');

        return res.status(400).json({
          success: false,
          message: `Minimum bill amount is ₹${minBill.toFixed(2)}`,
        });
      }

const discountAmount = Number(
  (originalBill * (discountPercent / 100)).toFixed(2)
);

const finalAmount = Number(
  (originalBill - discountAmount).toFixed(2)
);

      // Verification code is mandatory and must match the code
      // generated when the customer claimed the coupon.
      if (!verificationCode) {
        await client.query('ROLLBACK');

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
        await client.query('ROLLBACK');

        return res.status(400).json({
          success: false,
          message: 'Invalid verification code',
        });
      }

      const transactionCode =
        `DB-${Date.now()}-${Math.floor(Math.random() * 10000)}`;

      const transactionResult = await client.query(
        `
        INSERT INTO transactions
        (
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
        VALUES
        ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'COMPLETED', NOW())
        RETURNING *
        `,
        [
          transactionCode,
          coupon.coupon_id,
          coupon.customer_id,
          coupon.business_id,
          originalBill.toFixed(2),
          discountPercent,
          discountAmount.toFixed(2),
          finalAmount.toFixed(2),
          String(coupon.verification_code),
        ]
      );

      await client.query(
        `
        UPDATE coupon_claims
        SET
          transaction_id = $1,
          status = 'USED'
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

      // Create customer notification after successful transaction
      await client.query(
        `
        INSERT INTO notifications
        (
          user_id,
          title,
          message,
          type,
          is_read
        )
        VALUES
        ($1, $2, $3, $4, false)
        `,
        [
          coupon.customer_id,
          'Transaction Completed',
          `Your transaction at ${coupon.business_name} has been completed successfully. Bill ₹${originalBill.toFixed(2)} | Discount ₹${discountAmount.toFixed(2)} | Final Amount ₹${finalAmount.toFixed(2)}`,
          'TRANSACTION',
        ]
      );

      // Create shopkeeper notification after successful transaction
      await client.query(
        `
        INSERT INTO notifications
        (
          user_id,
          title,
          message,
          type,
          is_read
        )
        VALUES
        ($1, $2, $3, $4, false)
        `,
        [
          coupon.shopkeeper_user_id,
          'Transaction Completed',
          `Transaction completed at ${coupon.business_name}. Bill ₹${originalBill.toFixed(2)} | Discount ₹${discountAmount.toFixed(2)} | Final Amount ₹${finalAmount.toFixed(2)}`,
          'TRANSACTION',
        ]
      );

      await client.query('COMMIT');

      return res.status(201).json({
        success: true,
        message: 'Transaction confirmed successfully',
        data: {
          transaction: transactionResult.rows[0],
          couponNumber: coupon.coupon_number,
          originalBill: Number(originalBill.toFixed(2)),
          discountPercent,
          discountAmount: Number(discountAmount.toFixed(2)),
          finalAmount: Number(finalAmount.toFixed(2)),
        },
      });
    } catch (error) {
      await client.query('ROLLBACK');

      if (error.code === '23505' &&
          error.constraint === 'transactions_coupon_id_unique') {
        return res.status(409).json({
          success: false,
          message: 'This coupon has already been used in a transaction',
        });
      }

      console.error('Transaction confirmation error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to confirm transaction',
      });
    } finally {
      client.release();
    }
  }
);

/*
 * ============================================================
 * CUSTOMER TRANSACTION HISTORY
 * ============================================================
 */
router.get(
  '/customer-history',
  authenticate,
  requireRole('CUSTOMER'),
  async (req, res) => {
    try {
      const customerId =
        req.user.userId || req.user.id || req.user.sub;

      const result = await db.query(
        `
        SELECT
          t.id,
          t.transaction_code,
          t.coupon_id,
          c.coupon_number,
          t.business_id,
          b.business_name,
          t.original_bill,
          t.discount_percent,
          t.discount_amount,
          t.final_amount,
          t.verification_code,
          t.status,
          t.created_at,
          t.completed_at
        FROM transactions t
        JOIN coupons c
          ON c.id = t.coupon_id
        JOIN businesses b
          ON b.id = t.business_id
        WHERE t.customer_id = $1
        ORDER BY t.created_at DESC
        `,
        [customerId]
      );

      return res.json({
        success: true,
        data: result.rows,
      });
    } catch (error) {
      console.error('Customer transaction history error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to load transaction history',
      });
    }
  }
);

/*
 * SHOPKEEPER DASHBOARD STATS
 */

router.get(
  '/dashboard-stats',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    try {
      const userId =
        req.user.userId || req.user.id || req.user.sub;

      const result = await db.query(
        `
        WITH my_businesses AS (
          SELECT b.id
          FROM businesses b
          JOIN shopkeepers s
            ON s.id = b.shopkeeper_id
          WHERE s.user_id = $1
        )
        SELECT
          (
            SELECT COUNT(*)
            FROM coupons c
            JOIN coupon_campaigns cc
              ON cc.id = c.campaign_id
            WHERE cc.business_id IN (SELECT id FROM my_businesses)
          )::integer AS total_coupons,

          (
            SELECT COUNT(*)
            FROM coupons c
            JOIN coupon_campaigns cc
              ON cc.id = c.campaign_id
            WHERE cc.business_id IN (SELECT id FROM my_businesses)
              AND c.status = 'USED'
          )::integer AS used_coupons,

          (
            SELECT COUNT(*)
            FROM transactions t
            WHERE t.business_id IN (SELECT id FROM my_businesses)
              AND t.status = 'COMPLETED'
              AND t.created_at >= CURRENT_DATE
              AND t.created_at < CURRENT_DATE + INTERVAL '1 day'
          )::integer AS today_transactions,

          COALESCE(
            (
              SELECT SUM(t.discount_amount)
              FROM transactions t
              WHERE t.business_id IN (SELECT id FROM my_businesses)
                AND t.status = 'COMPLETED'
                AND t.created_at >= CURRENT_DATE
                AND t.created_at < CURRENT_DATE + INTERVAL '1 day'
            ),
            0
          )::numeric(12,2) AS today_discount
        `,
        [userId]
      );

      const stats = result.rows[0];

      return res.json({
        success: true,
        data: {
          totalCoupons: Number(stats.total_coupons || 0),
          usedCoupons: Number(stats.used_coupons || 0),
          todayTransactions: Number(stats.today_transactions || 0),
          todayDiscount: Number(stats.today_discount || 0),
        },
      });
    } catch (error) {
      console.error('Shopkeeper dashboard stats error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to load dashboard statistics',
      });
    }
  }
);


/*
 * ============================================================
 * SHOPKEEPER TRANSACTION HISTORY
 * ============================================================
 */
router.get(
  '/shopkeeper-history',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    try {
      const shopkeeperUserId =
  req.user.userId || req.user.id || req.user.sub;

      const result = await db.query(
        `
        SELECT
          t.id,
          t.transaction_code,
          t.coupon_id,
          c.coupon_number,
          t.customer_id,
          u.mobile AS customer_mobile,
          t.business_id,
          b.business_name,
          t.original_bill,
          t.discount_percent,
          t.discount_amount,
          t.final_amount,
          t.verification_code,
          t.status,
          t.created_at,
          t.completed_at
        FROM transactions t
        JOIN coupons c
          ON c.id = t.coupon_id
        JOIN users u
          ON u.id = t.customer_id
        JOIN businesses b
          ON b.id = t.business_id
        JOIN shopkeepers s
          ON s.id = b.shopkeeper_id
        WHERE s.user_id = $1
        ORDER BY t.created_at DESC
        `,
        [shopkeeperUserId]
      );

      return res.json({
        success: true,
        data: result.rows,
      });
    } catch (error) {
      console.error('Shopkeeper transaction history error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to load transaction history',
      });
    }
  }
);

module.exports = router;
