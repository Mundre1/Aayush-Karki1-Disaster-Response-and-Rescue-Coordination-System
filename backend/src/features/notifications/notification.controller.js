import { prisma } from '../../config/prisma.js';

export const getMyNotifications = async (req, res) => {
  try {
    const { isRead, page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = { userId: req.user.userId };
    if (isRead !== undefined) {
      where.isRead = isRead === 'true';
    }

    const [notifications, total] = await Promise.all([
      prisma.notification.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { createdAt: 'desc' },
        include: {
          incident: {
            select: {
              incidentId: true,
              title: true,
              status: true
            }
          }
        }
      }),
      prisma.notification.count({ where })
    ]);

    res.json({
      notifications,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;

    const notification = await prisma.notification.update({
      where: { notificationId: parseInt(id) },
      data: { isRead: true }
    });

    res.json({
      message: 'Notification marked as read',
      notification
    });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const markAllAsRead = async (req, res) => {
  try {
    await prisma.notification.updateMany({
      where: { 
        userId: req.user.userId,
        isRead: false
      },
      data: { isRead: true }
    });

    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    console.error('Mark all as read error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

