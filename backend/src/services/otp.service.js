const crypto = require('crypto');

const otpStore = new Map();
const OTP_EXPIRY_MS = 5 * 60 * 1000;

function generateOtp() {
  return crypto.randomInt(100000, 1000000).toString();
}

function createOtp(mobile) {
  const otp = generateOtp();

  otpStore.set(mobile, {
    otp,
    expiresAt: Date.now() + OTP_EXPIRY_MS,
    attempts: 0,
  });

  return otp;
}

function verifyOtp(mobile, otp) {
  const record = otpStore.get(mobile);

  if (!record) {
    return { success: false, message: 'OTP not found or expired' };
  }

  if (Date.now() > record.expiresAt) {
    otpStore.delete(mobile);
    return { success: false, message: 'OTP expired' };
  }

  if (record.attempts >= 5) {
    otpStore.delete(mobile);
    return { success: false, message: 'Too many attempts' };
  }

  record.attempts += 1;

  if (record.otp !== otp) {
    return { success: false, message: 'Invalid OTP' };
  }

  otpStore.delete(mobile);

  return { success: true };
}

module.exports = {
  createOtp,
  verifyOtp,
};
