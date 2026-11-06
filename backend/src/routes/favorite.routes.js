const express = require('express');
const router = express.Router();

const db = require('../config/database');
const { authenticate, requireRole } = require('../middleware/auth.middleware');

// GET CUSTOMER FAVORITES
router.get(
  '/',
  authenticate,
  requireRole('CUSTOMER'),
  async (req, res) => {
    try {
      const userId = req.user.userId || req.user.id || req.user.sub;

      const result = await db.query(`
        SELECT
          f.id AS favorite_id,
          f.created_at AS favorited_at,
          b.id AS business_id,
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
          COALESCE(cc.max_discount, 0) AS max_discount
        FROM favorites f
        JOIN businesses b
          ON b.id = f.business_id
        LEFT JOIN categories cat
          ON cat.id = b.category_id
        LEFT JOIN cities city
          ON city.id = b.city_id
        LEFT JOIN LATERAL (
          SELECT max_discount
          FROM coupon_campaigns
          WHERE business_id = b.id
            AND is_active = true
            AND validity_start <= NOW()
            AND validity_end >= NOW()
          ORDER BY created_at DESC
          LIMIT 1
        ) cc ON true
        WHERE f.customer_id = $1
          AND b.is_public = true
          AND EXISTS (
  SELECT 1
  FROM shopkeepers s
  WHERE s.id = b.shopkeeper_id
    AND s.verification_status = 'VERIFIED'
)
        ORDER BY f.created_at DESC
      `, [userId]);

      return res.json({
        success: true,
        data: result.rows,
      });
    } catch (error) {
      console.error('Get favorites error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to load favorites',
      });
    }
  }
);

// ADD FAVORITE
router.post(
  '/:businessId',
  authenticate,
  requireRole('CUSTOMER'),
  async (req, res) => {
    try {
      const userId = req.user.userId || req.user.id || req.user.sub;
      const { businessId } = req.params;

      const business = await db.query(
        `SELECT b.id
         FROM businesses b
         JOIN shopkeepers s ON s.id = b.shopkeeper_id
         WHERE b.id = $1
           AND b.is_public = true
           AND s.verification_status = 'VERIFIED'
         LIMIT 1`,
        [businessId]
      );

      if (business.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Business not found',
        });
      }

      const result = await db.query(
        `INSERT INTO favorites (customer_id, business_id)
         VALUES ($1, $2)
         ON CONFLICT (customer_id, business_id)
         DO NOTHING
         RETURNING id`,
        [userId, businessId]
      );

      return res.json({
        success: true,
        message: 'Shop added to favorites',
        data: {
          favorite: result.rows.length > 0,
        },
      });
    } catch (error) {
      console.error('Add favorite error:', error);
      console.error('Favorite DB details:', error.message, error.code, error.detail);
      return res.status(500).json({
        success: false,
        message: 'Failed to add favorite',
      });
    }
  }
);

// REMOVE FAVORITE
router.delete(
  '/:businessId',
  authenticate,
  requireRole('CUSTOMER'),
  async (req, res) => {
    try {
      const userId = req.user.userId || req.user.id || req.user.sub;
      const { businessId } = req.params;

      await db.query(
        `DELETE FROM favorites
         WHERE customer_id = $1
           AND business_id = $2`,
        [userId, businessId]
      );

      return res.json({
        success: true,
        message: 'Shop removed from favorites',
      });
    } catch (error) {
      console.error('Remove favorite error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to remove favorite',
      });
    }
  }
);

module.exports = router;
