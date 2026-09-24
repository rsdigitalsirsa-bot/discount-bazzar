const express = require('express');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');

const { createOtp, verifyOtp } = require('../services/otp.service');
const { query } = require('../config/database');

const router = express.Router();

const JWT_SECRET =
  process.env.JWT_SECRET || 'discount-bazzar-development-secret';

const otpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many OTP requests. Please try again later.',
  },
});

router.post('/request-otp', otpLimiter, (req, res) => {
  const { mobile } = req.body;

  if (!mobile || !/^[0-9]{10}$/.test(String(mobile))) {
    return res.status(400).json({
      success: false,
      message: 'Valid 10-digit mobile number is required',
    });
  }

  const otp = createOtp(String(mobile));

  console.log(`[DEV OTP] ${mobile}: ${otp}`);

  return res.json({
    success: true,
    message: 'OTP generated successfully',
    developmentOtp: otp,
  });
});

router.post('/verify-otp', async (req, res) => {
  const { mobile, otp, role = 'CUSTOMER' } = req.body;

  const allowedRoles = ['CUSTOMER', 'SHOPKEEPER', 'ADMIN'];

  if (!mobile || !otp) {
    return res.status(400).json({
      success: false,
      message: 'Mobile and OTP are required',
    });
  }

  if (!/^[0-9]{10}$/.test(String(mobile))) {
    return res.status(400).json({
      success: false,
      message: 'Valid 10-digit mobile number is required',
    });
  }

  if (!allowedRoles.includes(role)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid role',
    });
  }

  const result = verifyOtp(String(mobile), String(otp));

  if (!result.success) {
    return res.status(401).json(result);
  }

  try {
    const existingUser = await query(
      `SELECT id, mobile, role, name, email, profile_photo, city_id, is_active
       FROM users
       WHERE mobile = $1
       LIMIT 1`,
      [String(mobile)]
    );

    let user;

    if (existingUser.rows.length === 0) {
      const created = await query(
        `INSERT INTO users (mobile, role)
         VALUES ($1, $2)
         RETURNING id, mobile, role, name, email, profile_photo, city_id, is_active`,
        [String(mobile), role]
      );

      user = created.rows[0];
    } else {
      user = existingUser.rows[0];

      if (!user.is_active) {
        return res.status(403).json({
          success: false,
          message: 'User account is inactive',
        });
      }
    }

    const token = jwt.sign(
      {
        userId: user.id,
        mobile: user.mobile,
        role: user.role,
      },
      JWT_SECRET,
      {
        expiresIn: '7d',
      }
    );

    return res.json({
      success: true,
      message: 'OTP verified successfully',
      token,
      user,
    });
  } catch (error) {
    console.error('AUTH DB ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to save user information',
      error: error.message,
    });
  }
});

module.exports = router;
