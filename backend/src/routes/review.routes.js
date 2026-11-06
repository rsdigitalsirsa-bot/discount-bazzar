const express = require('express');
const router = express.Router();

const db = require('../config/database');
const { authenticate, requireRole } = require('../middleware/auth.middleware');

function isValidUuid(value) {
  return typeof value === 'string' &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

// GET REVIEWS + RATING SUMMARY FOR A SHOP
router.get(
  '/business/:businessId',
  async (req, res) => {
    try {
      const { businessId } = req.params;

      const summary = await db.query(`
        SELECT
          COUNT(*)::int AS review_count,
          COALESCE(ROUND(AVG(rating)::numeric, 1), 0) AS average_rating
        FROM reviews
        WHERE business_id = $1
      `, [businessId]);

      const reviews = await db.query(`
        SELECT
          r.id,
          r.customer_id,
          r.rating,
          r.review_text,
          r.created_at,
          COALESCE(NULLIF(TRIM(u.name), ''), 'Customer') AS customer_name
        FROM reviews r
        LEFT JOIN users u ON u.id = r.customer_id
        WHERE r.business_id = $1
        ORDER BY r.created_at DESC
      `, [businessId]);

      return res.json({
        success: true,
        data: {
          averageRating: Number(summary.rows[0]?.average_rating || 0),
          reviewCount: Number(summary.rows[0]?.review_count || 0),
          reviews: reviews.rows,
        },
      });
    } catch (error) {
      console.error('Get reviews error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to load reviews',
      });
    }
  }
);

// ADD OR UPDATE CUSTOMER REVIEW
router.post(
  '/',
  authenticate,
  requireRole('CUSTOMER'),
  async (req, res) => {
    try {
      const userId = req.user.userId || req.user.id || req.user.sub;
      const { businessId, rating, reviewText } = req.body;

      const numericRating = Number(rating);

      if (!businessId) {
        return res.status(400).json({
          success: false,
          message: 'Business ID is required',
        });
      }

      if (!isValidUuid(businessId)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid business ID',
        });
      }

      if (
        !Number.isInteger(numericRating) ||
        numericRating < 1 ||
        numericRating > 5
      ) {
        return res.status(400).json({
          success: false,
          message: 'Rating must be between 1 and 5',
        });
      }

      let normalizedReviewText = null;

      if (reviewText !== undefined && reviewText !== null) {
        if (typeof reviewText !== 'string') {
          return res.status(400).json({
            success: false,
            message: 'Review text must be a string',
          });
        }

        normalizedReviewText = reviewText.trim();

        if (normalizedReviewText.length > 500) {
          return res.status(400).json({
            success: false,
            message: 'Review text cannot exceed 500 characters',
          });
        }

        if (normalizedReviewText.length === 0) {
          normalizedReviewText = null;
        }
      }

      const business = await db.query(
        `SELECT id FROM businesses WHERE id = $1 LIMIT 1`,
        [businessId]
      );

      if (business.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Business not found',
        });
      }

      const existing = await db.query(
        `SELECT id
         FROM reviews
         WHERE customer_id = $1
           AND business_id = $2
         LIMIT 1`,
        [userId, businessId]
      );

      let result;

      if (existing.rows.length > 0) {
        result = await db.query(
          `UPDATE reviews
           SET rating = $1,
               review_text = $2
           WHERE id = $3
           RETURNING id, customer_id, business_id, rating, review_text, created_at`,
          [
            numericRating,
            normalizedReviewText,
            existing.rows[0].id,
          ]
        );
      } else {
        result = await db.query(
          `INSERT INTO reviews
             (customer_id, business_id, rating, review_text)
           VALUES ($1, $2, $3, $4)
           RETURNING id, customer_id, business_id, rating, review_text, created_at`,
          [
            userId,
            businessId,
            numericRating,
            normalizedReviewText,
          ]
        );
      }

      return res.json({
        success: true,
        message:
          existing.rows.length > 0
            ? 'Review updated successfully'
            : 'Review submitted successfully',
        data: {
          review: result.rows[0],
        },
      });
    } catch (error) {
      console.error('Save review error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to save review',
      });
    }
  }
);

// DELETE CUSTOMER'S OWN REVIEW
router.delete(
  '/:reviewId',
  authenticate,
  requireRole('CUSTOMER'),
  async (req, res) => {
    try {
      const userId = req.user.userId || req.user.id || req.user.sub;
      const { reviewId } = req.params;

      const result = await db.query(
        `DELETE FROM reviews
         WHERE id = $1
           AND customer_id = $2
         RETURNING id`,
        [reviewId, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Review not found',
        });
      }

      return res.json({
        success: true,
        message: 'Review deleted successfully',
      });
    } catch (error) {
      console.error('Delete review error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to delete review',
      });
    }
  }
);

module.exports = router;
