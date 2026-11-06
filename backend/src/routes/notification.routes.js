const express = require('express');
const router = express.Router();

const db = require('../config/database');
const {
  authenticate,
} = require('../middleware/auth.middleware');

/*
 * GET MY NOTIFICATIONS
 */
router.get('/my', authenticate, async (req, res) => {
  try {
    const userId =
      req.user.userId || req.user.id || req.user.sub;

    const result = await db.query(
      `
      SELECT
        id,
        title,
        message,
        type,
        is_read,
        created_at
      FROM notifications
      WHERE user_id = $1
      ORDER BY created_at DESC
      `,
      [userId]
    );

    res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error('Notifications error:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to load notifications',
    });
  }
});

/*
 * GET UNREAD COUNT
 */
router.get('/unread-count', authenticate, async (req, res) => {
  try {
    const userId =
      req.user.userId || req.user.id || req.user.sub;

    const result = await db.query(
      `
      SELECT COUNT(*)::integer AS unread_count
      FROM notifications
      WHERE user_id = $1
        AND is_read = false
      `,
      [userId]
    );

    res.json({
      success: true,
      data: {
        unreadCount: Number(result.rows[0].unread_count || 0),
      },
    });
  } catch (error) {
    console.error('Unread notification count error:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to load unread count',
    });
  }
});

/*
 * MARK ONE NOTIFICATION AS READ
 */
router.put('/:notificationId/read', authenticate, async (req, res) => {
  try {
    const userId =
      req.user.userId || req.user.id || req.user.sub;

    const { notificationId } = req.params;

    const result = await db.query(
      `
      UPDATE notifications
      SET is_read = true
      WHERE id = $1
        AND user_id = $2
      RETURNING *
      `,
      [notificationId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }

    res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Mark notification read error:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to mark notification as read',
    });
  }
});

/*
 * MARK ALL AS READ
 */
router.put('/read-all', authenticate, async (req, res) => {
  try {
    const userId =
      req.user.userId || req.user.id || req.user.sub;

    await db.query(
      `
      UPDATE notifications
      SET is_read = true
      WHERE user_id = $1
        AND is_read = false
      `,
      [userId]
    );

    res.json({
      success: true,
      message: 'All notifications marked as read',
    });
  } catch (error) {
    console.error('Mark all notifications read error:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to mark notifications as read',
    });
  }
});

module.exports = router;
