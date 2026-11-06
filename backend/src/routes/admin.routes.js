const express = require('express');
const router = express.Router();

const db = require('../config/database');
const { authenticate, requireRole } = require('../middleware/auth.middleware');

// ==========================================
// ADMIN DASHBOARD
// ==========================================
router.get(
  '/dashboard',
  authenticate,
  requireRole('ADMIN'),
  async (req, res) => {
  try {
    const result = await db.query(`
      SELECT
        (SELECT COUNT(*)
         FROM businesses b
         JOIN shopkeepers s ON s.id = b.shopkeeper_id
         WHERE s.verification_status = 'PENDING'
           AND b.is_public = false) AS pending_businesses,

        (SELECT COUNT(*)
         FROM businesses b
         JOIN shopkeepers s ON s.id = b.shopkeeper_id
         WHERE s.verification_status = 'VERIFIED'
           AND b.is_public = true) AS approved_businesses,

        (SELECT COUNT(*)
         FROM users
         WHERE role = 'CUSTOMER') AS customers,

        (SELECT COUNT(*)
         FROM users
         WHERE role = 'SHOPKEEPER') AS shopkeepers,

        (SELECT COUNT(*)
         FROM shopkeepers
         WHERE verification_status = 'REJECTED') AS rejected_businesses
    `);

    const row = result.rows[0];

    res.json({
      success: true,
      data: {
        pendingBusinesses: Number(row.pending_businesses || 0),
        approvedBusinesses: Number(row.approved_businesses || 0),
        customers: Number(row.customers || 0),
        shopkeepers: Number(row.shopkeepers || 0),
        rejectedBusinesses: Number(row.rejected_businesses || 0),
      },
    });
  } catch (error) {
    console.error('Admin dashboard error:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to load admin dashboard',
      error:
        process.env.NODE_ENV === 'development'
          ? error.message
          : undefined,
    });
  }
});

// ==========================================
// PENDING BUSINESSES
// ==========================================
router.get(
  '/pending-businesses',
  authenticate,
  requireRole('ADMIN'),
  async (req, res) => {
  try {
    const result = await db.query(`
      SELECT
        b.id AS business_id,
        b.business_name,
        b.address,
        b.city_id,
        b.pincode,
        b.phone,
        b.email,
        b.description,
        b.created_at,
        s.id AS shopkeeper_id,
        s.owner_name,
        s.business_phone,
        s.email AS shopkeeper_email,
        s.verification_status
      FROM businesses b
      JOIN shopkeepers s
        ON s.id = b.shopkeeper_id
      WHERE s.verification_status = 'PENDING'
      ORDER BY b.created_at DESC
    `);

    res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error('Pending businesses error:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to load pending businesses',
    });
  }
});

// ==========================================
// APPROVED BUSINESSES
// ==========================================
router.get(
  '/approved-businesses',
  authenticate,
  requireRole('ADMIN'),
  async (req, res) => {
  try {
    const result = await db.query(`
      SELECT
        b.id AS business_id,
        b.business_name,
        b.address,
        b.city_id,
        b.pincode,
        b.phone,
        b.email,
        b.description,
        b.created_at,
        b.updated_at,
        s.id AS shopkeeper_id,
        s.owner_name,
        s.business_phone,
        s.email AS shopkeeper_email,
        s.verification_status
      FROM businesses b
      JOIN shopkeepers s
        ON s.id = b.shopkeeper_id
      WHERE s.verification_status = 'VERIFIED'
        AND b.is_public = true
      ORDER BY b.updated_at DESC
    `);

    res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error('Approved businesses error:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to load approved businesses',
    });
  }
});

// ==========================================
// APPROVE BUSINESS
// ==========================================
router.put(
  '/businesses/:businessId/approve',
  authenticate,
  requireRole('ADMIN'),
  async (req, res) => {
  const client = await db.connect();

  try {
    await client.query('BEGIN');

    const businessResult = await client.query(
      `
      SELECT shopkeeper_id
      FROM businesses
      WHERE id = $1
      LIMIT 1
      `,
      [req.params.businessId]
    );

    if (businessResult.rows.length === 0) {
      await client.query('ROLLBACK');

      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    const shopkeeperId = businessResult.rows[0].shopkeeper_id;

    await client.query(
      `
      UPDATE shopkeepers
      SET verification_status = 'VERIFIED'
      WHERE id = $1
      `,
      [shopkeeperId]
    );

    await client.query(
      `
      UPDATE businesses
      SET is_public = true,
          updated_at = now()
      WHERE id = $1
      `,
      [req.params.businessId]
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Business approved successfully',
    });
  } catch (error) {
    await client.query('ROLLBACK');

    console.error('Approve business error:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to approve business',
    });
  } finally {
    client.release();
  }
});

// ==========================================
// REJECT BUSINESS
// ==========================================
router.put(
  '/businesses/:businessId/reject',
  authenticate,
  requireRole('ADMIN'),
  async (req, res) => {
  const client = await db.connect();

  try {
    await client.query('BEGIN');

    const businessResult = await client.query(
      `
      SELECT shopkeeper_id
      FROM businesses
      WHERE id = $1
      LIMIT 1
      `,
      [req.params.businessId]
    );

    if (businessResult.rows.length === 0) {
      await client.query('ROLLBACK');

      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    const shopkeeperId = businessResult.rows[0].shopkeeper_id;

    await client.query(
      `
      UPDATE shopkeepers
      SET verification_status = 'REJECTED'
      WHERE id = $1
      `,
      [shopkeeperId]
    );

    await client.query(
      `
      UPDATE businesses
      SET is_public = false,
          updated_at = now()
      WHERE id = $1
      `,
      [req.params.businessId]
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Business rejected successfully',
    });
  } catch (error) {
    await client.query('ROLLBACK');

    console.error('Reject business error:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to reject business',
    });
  } finally {
    client.release();
  }
});

module.exports = router;