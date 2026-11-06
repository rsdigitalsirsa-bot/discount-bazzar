const express = require('express');
const router = express.Router();

function validateBusinessInput({
  ownerName,
  businessName,
  mobile,
  email,
  category,
  subcategory,
  address,
  city,
  pincode,
  businessPhone,
  whatsapp,
  description,
  openingTime,
  closingTime,
  weeklyHoliday,
  terms,
  images,
}) {
  const strings = [
    ['Owner name', ownerName, 100],
    ['Business name', businessName, 150],
    ['Category', category, 100],
    ['Subcategory', subcategory, 100],
    ['Address', address, 250],
    ['City', city, 100],
    ['Description', description, 1000],
    ['Opening time', openingTime, 30],
    ['Closing time', closingTime, 30],
    ['Weekly holiday', weeklyHoliday, 30],
    ['Terms', terms, 2000],
  ];

  for (const [label, value, max] of strings) {
    if (value !== undefined && value !== null && typeof value !== 'string') {
      return `${label} must be a string`;
    }

    if (typeof value === 'string' && value.length > max) {
      return `${label} cannot exceed ${max} characters`;
    }
  }

  if (email !== undefined && email !== null && email !== '') {
    if (typeof email !== 'string') {
      return 'Email must be a string';
    }

    if (email.length > 254) {
      return 'Email cannot exceed 254 characters';
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return 'Invalid email address';
    }
  }

  const phone = businessPhone || mobile;

  if (phone !== undefined && phone !== null && phone !== '') {
    if (typeof phone !== 'string' && typeof phone !== 'number') {
      return 'Business phone must be a valid phone number';
    }

    if (!/^[0-9]{10}$/.test(String(phone))) {
      return 'Business phone must be a valid 10-digit number';
    }
  }

  if (whatsapp !== undefined && whatsapp !== null && whatsapp !== '') {
    if (typeof whatsapp !== 'string' && typeof whatsapp !== 'number') {
      return 'WhatsApp number must be a valid phone number';
    }

    if (!/^[0-9]{10}$/.test(String(whatsapp))) {
      return 'WhatsApp number must be a valid 10-digit number';
    }
  }

  if (pincode !== undefined && pincode !== null && pincode !== '') {
    if (typeof pincode !== 'string' && typeof pincode !== 'number') {
      return 'Pincode must be a valid 6-digit number';
    }

    if (!/^[0-9]{6}$/.test(String(pincode))) {
      return 'Pincode must be a valid 6-digit number';
    }
  }

  if (images !== undefined && images !== null) {
    if (!Array.isArray(images)) {
      return 'Images must be an array';
    }

    if (images.length > 20) {
      return 'Maximum 20 images are allowed';
    }
  }

  return null;
}


const db = require('../config/database');
const { authenticate, requireRole } = require('../middleware/auth.middleware');

// ============================================================
// GET PUBLIC BUSINESSES
// ============================================================
router.get('/', async (req, res) => {
  try {
    const result = await db.query(
      `SELECT *
       FROM businesses
       WHERE is_public = true
       ORDER BY created_at DESC`
    );

    return res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error('Business listing error:', error);

    return res.status(500).json({
      success: false,
      message: 'Failed to load businesses',
    });
  }
});


// ============================================================
// CUSTOMER - PUBLIC VERIFIED BUSINESSES
// ============================================================
router.get('/public', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT
        b.id,
        b.business_name,
        b.subcategory,
        b.address,
        b.pincode,
        b.phone,
        b.whatsapp,
        b.email,
        b.description,
        b.logo_url,
        b.weekly_holiday,
        b.opening_time,
        b.closing_time,
        b.images,
        b.terms,
        b.shop_tier,
        cat.name AS category,
        city.name AS city,
        COALESCE(cc.max_discount, 0) AS max_discount,
        cc.id AS campaign_id,
        cc.name AS campaign_name
      FROM businesses b
      JOIN shopkeepers s
        ON s.id = b.shopkeeper_id
      LEFT JOIN categories cat
        ON cat.id = b.category_id
      LEFT JOIN cities city
        ON city.id = b.city_id
      LEFT JOIN LATERAL (
        SELECT
          cc.id,
          cc.name,
          cc.max_discount
        FROM coupon_campaigns cc
        WHERE cc.business_id = b.id
          AND cc.is_active = true
          AND cc.validity_start <= NOW()
          AND cc.validity_end >= NOW()
        ORDER BY cc.created_at DESC
        LIMIT 1
      ) cc ON true
      WHERE b.is_public = true
        AND s.verification_status = 'VERIFIED'
      ORDER BY
        CASE
          WHEN b.shop_tier = 'GOLD' THEN 0
          ELSE 1
        END,
        b.business_name ASC
    `);

    return res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error('Public businesses error:', error);

    return res.status(500).json({
      success: false,
      message: 'Failed to load public businesses',
    });
  }
});

// ------------------------------------------------------
// SHOPKEEPER BUSINESS STATUS
// ------------------------------------------------------
router.get('/my-status', authenticate, requireRole('SHOPKEEPER'), async (req, res) => {
  try {
    const userId = req.user.userId || req.user.id || req.user.sub;

    const result = await db.query(
      `
      SELECT
        b.id AS business_id,
        b.business_name,
        b.is_public,
        s.verification_status
      FROM shopkeepers s
      LEFT JOIN businesses b
        ON b.shopkeeper_id = s.id
      WHERE s.user_id = $1
      ORDER BY b.created_at DESC NULLS LAST
      LIMIT 1
      `,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.json({
        success: true,
        data: {
          hasBusiness: false,
          verificationStatus: null,
        },
      });
    }

    const row = result.rows[0];

    return res.json({
      success: true,
      data: {
        hasBusiness: true,
        businessId: row.business_id,
        businessName: row.business_name,
        verificationStatus: row.verification_status,
        isPublic: row.is_public,
      },
    });
  } catch (error) {
    console.error('Business status error:', error);

    return res.status(500).json({
      success: false,
      message: 'Failed to load business status',
    });
  }
});
// ============================================================
// SHOPKEEPER BUSINESS PROFILE
// ============================================================

router.get(
  '/my-business',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    try {
      const userId =
        req.user?.userId ||
        req.user?.id ||
        req.user?.sub;

      const result = await db.query(
        `
        SELECT
          b.id AS business_id,
          s.id AS shopkeeper_id,
          s.owner_name,
          s.business_phone,
          s.email AS shopkeeper_email,
          s.verification_status,

          b.business_name,
          b.subcategory,
          b.address,
          b.pincode,
          b.phone,
          b.whatsapp,
          b.email,
          b.description,
          b.logo_url,
          b.weekly_holiday,
          b.opening_time,
          b.closing_time,
          b.images,
          b.terms,
          b.is_public,

          c.name AS category,
          ci.name AS city

        FROM shopkeepers s
        LEFT JOIN businesses b
          ON b.shopkeeper_id = s.id
        LEFT JOIN categories c
          ON c.id = b.category_id
        LEFT JOIN cities ci
          ON ci.id = b.city_id

        WHERE s.user_id = $1
        ORDER BY b.created_at DESC NULLS LAST
        LIMIT 1
        `,
        [userId]
      );

      if (result.rows.length === 0) {
        return res.json({
          success: true,
          data: {
            hasBusiness: false,
          },
        });
      }

      const row = result.rows[0];

      return res.json({
        success: true,
        data: {
          hasBusiness: !!row.business_id,
          businessId: row.business_id,
          shopkeeperId: row.shopkeeper_id,
          ownerName: row.owner_name,
          businessPhone: row.business_phone,
          shopkeeperEmail: row.shopkeeper_email,
          verificationStatus: row.verification_status,

          businessName: row.business_name,
          category: row.category,
          subcategory: row.subcategory,
          address: row.address,
          city: row.city,
          pincode: row.pincode,
          phone: row.phone,
          whatsapp: row.whatsapp,
          email: row.email,
          description: row.description,
          logoUrl: row.logo_url,
          weeklyHoliday: row.weekly_holiday,
          openingTime: row.opening_time,
          closingTime: row.closing_time,
          images: row.images ?? [],
          terms: row.terms,
          isPublic: row.is_public,
        },
      });
    } catch (error) {
      console.error('My business profile error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to load business profile',
      });
    }
  }
);

router.post(
  '/register',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    const userId =
      req.user?.userId ||
      req.user?.id ||
      req.user?.sub;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Shopkeeper user ID not found',
      });
    }

    const {
      ownerName,
      businessName,
      mobile,
      email,
      category,
      subcategory,
      address,
      city,
      pincode,
      businessPhone,
      whatsapp,
      description,
      openingTime,
      closingTime,
      weeklyHoliday,
      logoUrl,
      images,
      terms,
    } = req.body;

    // --------------------------------------------------------
    // VALIDATION
    // --------------------------------------------------------
    if (!ownerName || !businessName || !address) {
      return res.status(400).json({
        success: false,
        message: 'Owner name, business name and address are required',
      });
    }

    const validationError = validateBusinessInput({
      ownerName,
      businessName,
      mobile,
      email,
      category,
      subcategory,
      address,
      city,
      pincode,
      businessPhone,
      whatsapp,
      description,
      openingTime,
      closingTime,
      weeklyHoliday,
      terms,
      images,
    });

    if (validationError) {
      return res.status(400).json({
        success: false,
        message: validationError,
      });
    }

    // Always send valid JSON to PostgreSQL JSONB column.
    const safeImages = Array.isArray(images) ? images : [];

    const client = await db.connect();

    try {
      await client.query('BEGIN');

      // ------------------------------------------------------
      // 1. FIND EXISTING SHOPKEEPER
      // ------------------------------------------------------
      const existingShopkeeper = await client.query(
        `SELECT id
         FROM shopkeepers
         WHERE user_id = $1
         LIMIT 1`,
        [userId]
      );

      let shopkeeperId;

      // ------------------------------------------------------
      // 2. UPDATE OR CREATE SHOPKEEPER
      // ------------------------------------------------------
      if (existingShopkeeper.rows.length > 0) {
        shopkeeperId = existingShopkeeper.rows[0].id;

        await client.query(
          `UPDATE shopkeepers
           SET owner_name = $1,
               business_phone = $2,
               email = $3,
               verification_status = 'PENDING'
           WHERE id = $4`,
          [
            ownerName,
            businessPhone || mobile || null,
            email || null,
            shopkeeperId,
          ]
        );
      } else {
        const shopkeeperResult = await client.query(
          `INSERT INTO shopkeepers
             (
               user_id,
               owner_name,
               business_phone,
               email,
               verification_status
             )
           VALUES
             ($1, $2, $3, $4, 'PENDING')
           RETURNING id`,
          [
            userId,
            ownerName,
            businessPhone || mobile || null,
            email || null,
          ]
        );

        shopkeeperId = shopkeeperResult.rows[0].id;
      }

      // ------------------------------------------------------
      // 3. FIND CATEGORY
      // ------------------------------------------------------
      let categoryId = null;

      if (category) {
        const categoryResult = await client.query(
          `SELECT id
           FROM categories
           WHERE LOWER(name) = LOWER($1)
           LIMIT 1`,
          [category]
        );

        if (categoryResult.rows.length > 0) {
          categoryId = categoryResult.rows[0].id;
        }
      }

      // ------------------------------------------------------
      // 4. FIND CITY
      // ------------------------------------------------------
      let cityId = null;

      if (city) {
        const cityResult = await client.query(
          `SELECT id
           FROM cities
           WHERE LOWER(name) = LOWER($1)
           LIMIT 1`,
          [city]
        );

        if (cityResult.rows.length > 0) {
          cityId = cityResult.rows[0].id;
        }
      }

      // ------------------------------------------------------
      // 5. CHECK EXISTING BUSINESS
      // ------------------------------------------------------
      const existingBusiness = await client.query(
        `SELECT id
         FROM businesses
         WHERE shopkeeper_id = $1
         LIMIT 1`,
        [shopkeeperId]
      );

      let business;

      // ------------------------------------------------------
      // 6. UPDATE EXISTING BUSINESS
      // ------------------------------------------------------
      if (existingBusiness.rows.length > 0) {
        const businessResult = await client.query(
          `UPDATE businesses
           SET category_id = $1,
               city_id = $2,
               business_name = $3,
               subcategory = $4,
               address = $5,
               pincode = $6,
               phone = $7,
               whatsapp = $8,
               email = $9,
               description = $10,
               logo_url = $11,
               weekly_holiday = $12,
               opening_time = $13,
               closing_time = $14,
               images = $15::jsonb,
               terms = $16,
               is_public = false,
               updated_at = now()
           WHERE id = $17
           RETURNING *`,
          [
            categoryId,
            cityId,
            businessName,
            subcategory || null,
            address,
            pincode || null,
            mobile || businessPhone || null,
            whatsapp || null,
            email || null,
            description || null,
            logoUrl || null,
            weeklyHoliday || null,
            openingTime || null,
            closingTime || null,
            JSON.stringify(safeImages),
            terms || null,
            existingBusiness.rows[0].id,
          ]
        );

        business = businessResult.rows[0];
      }

      // ------------------------------------------------------
      // 7. CREATE NEW BUSINESS
      // ------------------------------------------------------
      else {
        const businessResult = await client.query(
          `INSERT INTO businesses
             (
               shopkeeper_id,
               category_id,
               city_id,
               business_name,
               subcategory,
               address,
               pincode,
               phone,
               whatsapp,
               email,
               description,
               logo_url,
               weekly_holiday,
               opening_time,
               closing_time,
               images,
               terms,
               is_public
             )
           VALUES
             (
               $1,
               $2,
               $3,
               $4,
               $5,
               $6,
               $7,
               $8,
               $9,
               $10,
               $11,
               $12,
               $13,
               $14,
               $15,
               $16::jsonb,
               $17,
               false
             )
           RETURNING *`,
          [
            shopkeeperId,
            categoryId,
            cityId,
            businessName,
            subcategory || null,
            address,
            pincode || null,
            mobile || businessPhone || null,
            whatsapp || null,
            email || null,
            description || null,
            logoUrl || null,
            weeklyHoliday || null,
            openingTime || null,
            closingTime || null,
            JSON.stringify(safeImages),
            terms || null,
          ]
        );

        business = businessResult.rows[0];
      }

      // ------------------------------------------------------
      // 8. COMMIT
      // ------------------------------------------------------
      await client.query('COMMIT');

      return res.status(201).json({
        success: true,
        message: 'Business submitted for approval',
        data: {
          shopkeeperId,
          business,
          verificationStatus: 'PENDING',
        },
      });
    } catch (error) {
      await client.query('ROLLBACK');

      console.error('Business registration error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to submit business registration',
        error:
          process.env.NODE_ENV === 'development'
            ? error.message
            : undefined,
      });
    } finally {
      client.release();
    }
  }
);


// ========================================================
// UPDATE SHOPKEEPER BUSINESS PROFILE
// ========================================================
router.put(
  '/my-business',
  authenticate,
  requireRole('SHOPKEEPER'),
  async (req, res) => {
    const userId =
      req.user?.userId ||
      req.user?.id ||
      req.user?.sub;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Shopkeeper user ID not found',
      });
    }

    const {
      ownerName,
      businessName,
      email,
      businessPhone,
      category,
      subcategory,
      address,
      city,
      pincode,
      whatsapp,
      description,
      openingTime,
      closingTime,
      weeklyHoliday,
      logoUrl,
      images,
      terms,
    } = req.body;

    if (!ownerName || !businessName || !address) {
      return res.status(400).json({
        success: false,
        message: 'Owner name, business name and address are required',
      });
    }

    const validationError = validateBusinessInput({
      ownerName,
      businessName,
      email,
      category,
      subcategory,
      address,
      city,
      pincode,
      businessPhone,
      whatsapp,
      description,
      openingTime,
      closingTime,
      weeklyHoliday,
      terms,
      images,
    });

    if (validationError) {
      return res.status(400).json({
        success: false,
        message: validationError,
      });
    }

    const safeImages = Array.isArray(images) ? images : [];

    const client = await db.connect();

    try {
      await client.query('BEGIN');

      const shopkeeperResult = await client.query(
        `
        SELECT id
        FROM shopkeepers
        WHERE user_id = $1
        LIMIT 1
        `,
        [userId]
      );

      if (shopkeeperResult.rows.length === 0) {
        await client.query('ROLLBACK');

        return res.status(404).json({
          success: false,
          message: 'Shopkeeper profile not found',
        });
      }

      const shopkeeperId = shopkeeperResult.rows[0].id;

      let categoryId = null;

      if (category) {
        const categoryResult = await client.query(
          `
          SELECT id
          FROM categories
          WHERE LOWER(name) = LOWER($1)
          LIMIT 1
          `,
          [category]
        );

        if (categoryResult.rows.length > 0) {
          categoryId = categoryResult.rows[0].id;
        }
      }

      let cityId = null;

      if (city) {
        const cityResult = await client.query(
          `
          SELECT id
          FROM cities
          WHERE LOWER(name) = LOWER($1)
          LIMIT 1
          `,
          [city]
        );

        if (cityResult.rows.length > 0) {
          cityId = cityResult.rows[0].id;
        }
      }

      const businessResult = await client.query(
        `
        UPDATE businesses
        SET
          category_id = $1,
          city_id = $2,
          business_name = $3,
          subcategory = $4,
          address = $5,
          pincode = $6,
          phone = $7,
          whatsapp = $8,
          email = $9,
          description = $10,
          logo_url = $11,
          weekly_holiday = $12,
          opening_time = $13,
          closing_time = $14,
          images = $15::jsonb,
          terms = $16,
          is_public = false,
          updated_at = now()
        WHERE shopkeeper_id = $17
        RETURNING id
        `,
        [
          categoryId,
          cityId,
          businessName,
          subcategory || null,
          address,
          pincode || null,
          businessPhone || null,
          whatsapp || null,
          email || null,
          description || null,
          logoUrl || null,
          weeklyHoliday || null,
          openingTime || null,
          closingTime || null,
          JSON.stringify(safeImages),
          terms || null,
          shopkeeperId,
        ]
      );

      if (businessResult.rows.length === 0) {
        await client.query('ROLLBACK');

        return res.status(404).json({
          success: false,
          message: 'Business not found',
        });
      }

      await client.query(
        `
        UPDATE shopkeepers
        SET
          owner_name = $1,
          business_phone = $2,
          email = $3,
          verification_status = 'PENDING'
        WHERE id = $4
        `,
        [
          ownerName,
          businessPhone || null,
          email || null,
          shopkeeperId,
        ]
      );

      await client.query('COMMIT');

      return res.json({
        success: true,
        message: 'Business updated successfully and sent for approval',
        data: {
          businessId: businessResult.rows[0].id,
          verificationStatus: 'PENDING',
          isPublic: false,
        },
      });
    } catch (error) {
      await client.query('ROLLBACK');

      console.error('Update business error:', error);

      return res.status(500).json({
        success: false,
        message: 'Failed to update business',
      });
    } finally {
      client.release();
    }
  }
);

module.exports = router;