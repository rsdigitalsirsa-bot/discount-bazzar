const express = require('express');
const { pool } = require('../config/database');
const { authenticate, requireRole } = require('../middleware/auth.middleware');

const router = express.Router();

router.put('/me', authenticate, requireRole('CUSTOMER'), async (req, res) => {
  try {
    const userId =
      req.user.userId ||
      req.user.id ||
      req.user.sub ||
      req.user.user?.id;

    if (!userId) {
      console.error('Profile update: user ID missing', req.user);

      return res.status(400).json({
        success: false,
        message: 'User ID missing from authentication token',
      });
    }

    if (
      req.body.name !== undefined &&
      req.body.name !== null &&
      typeof req.body.name !== 'string'
    ) {
      return res.status(400).json({
        success: false,
        message: 'Name must be a string',
      });
    }

    if (
      req.body.email !== undefined &&
      req.body.email !== null &&
      typeof req.body.email !== 'string'
    ) {
      return res.status(400).json({
        success: false,
        message: 'Email must be a string',
      });
    }

    if (
      req.body.city !== undefined &&
      req.body.city !== null &&
      typeof req.body.city !== 'string'
    ) {
      return res.status(400).json({
        success: false,
        message: 'City must be a string',
      });
    }

    const name = typeof req.body.name === 'string'
      ? req.body.name.trim()
      : '';

    const email = typeof req.body.email === 'string'
      ? req.body.email.trim()
      : '';

    const city = typeof req.body.city === 'string'
      ? req.body.city.trim()
      : '';

    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Name is required',
      });
    }

    if (name.length > 100) {
      return res.status(400).json({
        success: false,
        message: 'Name cannot exceed 100 characters',
      });
    }

    if (email.length > 254) {
      return res.status(400).json({
        success: false,
        message: 'Email cannot exceed 254 characters',
      });
    }

    if (
      email &&
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    ) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email address',
      });
    }

    if (city.length > 100) {
      return res.status(400).json({
        success: false,
        message: 'City cannot exceed 100 characters',
      });
    }

    // Find city only when a city was supplied.
    // If the city is not present in the cities table, keep the
    // existing city_id so profile update itself does not fail.
    let cityId = null;

    if (city) {
      try {
        const cityResult = await pool.query(
          `SELECT id
           FROM cities
           WHERE LOWER(name) = LOWER($1)
           LIMIT 1`,
          [city]
        );

        if (cityResult.rows.length > 0) {
          cityId = cityResult.rows[0].id;
        }
      } catch (cityError) {
        console.error('City lookup skipped:', cityError.message);
      }
    }

    let result;

    if (cityId) {
      result = await pool.query(
        `UPDATE users
         SET name = $1,
             email = $2,
             city_id = $3,
             updated_at = NOW()
         WHERE id = $4
         RETURNING id, mobile, role, name, email, profile_photo, city_id, is_active`,
        [name, email || null, cityId, userId]
      );
    } else {
      result = await pool.query(
        `UPDATE users
         SET name = $1,
             email = $2,
             updated_at = NOW()
         WHERE id = $3
         RETURNING id, mobile, role, name, email, profile_photo, city_id, is_active`,
        [name, email || null, userId]
      );
    }

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    return res.json({
      success: true,
      message: 'Profile updated successfully',
      user: result.rows[0],
    });
  } catch (error) {
    console.error('Profile update error:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to update profile',
    });
  }
});

module.exports = router;
