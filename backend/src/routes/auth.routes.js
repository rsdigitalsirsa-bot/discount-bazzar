const express = require('express');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const { createOtp, verifyOtp } = require('../services/otp.service');

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

  // Development mode only.
  // Production SMS provider will be connected later.
  console.log(`[DEV OTP] ${mobile}: ${otp}`);

  return res.json({
    success: true,
    message: 'OTP generated successfully',
    developmentOtp: otp,
  });
});

router.post('/verify-otp', (req, res) => {
  const { mobile, otp, role = 'CUSTOMER' } = req.body;

  const allowedRoles = ['CUSTOMER', 'SHOPKEEPER', 'ADMIN'];

  if (!mobile || !otp) {
    return res.status(400).json({
      success: false,
      message: 'Mobile and OTP are required',
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

  const token = jwt.sign(
    {
      mobile: String(mobile),
      role,
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
    user: {
      mobile: String(mobile),
      role,
    },
  });
});

module.exports = router;
