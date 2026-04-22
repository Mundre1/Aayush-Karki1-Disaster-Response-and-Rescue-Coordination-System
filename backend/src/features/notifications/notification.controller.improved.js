import { prisma } from '../../config/prisma.js';
import { ApiResponse, ErrorHandler } from '../../core/utils/response.handler.js';

// Improved Notification Controller with generic patterns
class NotificationController {
  // Get user's notifications
  async getMyNotifications(req, res) {
    try {
      const { isRead, type, page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const where = { userId: req.user.userId };
      
      if (isRead !== undefined) {
        where.isRead = isRead === 'true';
      }
      
      if (type) {
        where.type = type;
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

      ApiResponse.paginated(res, notifications, {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }, 'Notifications retrieved successfully');

    } catch (error) {
      console.error('Get notifications error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Mark notification as read
  async markAsRead(req, res) {
    try {
      const { id } = req.params;

      const notification = await prisma.notification.update({
        where: { notificationId: parseInt(id) },
        data: { isRead: true },
        include: {
          incident: {
            select: {
              incidentId: true,
              title: true,
              status: true
            }
          }
        }
      });

      ApiResponse.success(res, notification, 'Notification marked as read');

    } catch (error) {
      console.error('Mark as read error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Mark all notifications as read
  async markAllAsRead(req, res) {
    try {
      const result = await prisma.notification.updateMany({
        where: { 
          userId: req.user.userId,
          isRead: false
        },
        data: { isRead: true }
      });

      ApiResponse.success(res, { count: result.count }, 'All notifications marked as read');

    } catch (error) {
      console.error('Mark all as read error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Delete notification
  async deleteNotification(req, res) {
    try {
      const { id } = req.params;

      await prisma.notification.delete({
        where: { notificationId: parseInt(id) }
      });

      ApiResponse.success(res, null, 'Notification deleted successfully');

    } catch (error) {
      console.error('Delete notification error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Get unread notification count
  async getUnreadCount(req, res) {
    try {
      const count = await prisma.notification.count({
        where: { 
          userId: req.user.userId,
          isRead: false
        }
      });

      ApiResponse.success(res, { count }, 'Unread notification count retrieved');

    } catch (error) {
      console.error('Get unread count error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Create notification (internal use)
  async createNotification(userId, incidentId, type, message) {
    try {
      const notification = await prisma.notification.create({
        data: {
          userId,
          incidentId,
          type,
          message,
          isRead: false
        }
      });

      return notification;
    } catch (error) {
      console.error('Create notification error:', error);
      throw error;
    }
  }

  // Bulk create notifications
  async createBulkNotifications(notifications) {
    try {
      const result = await prisma.notification.createMany({
        data: notifications,
        skipDuplicates: true
      });

      return result;
    } catch (error) {
      console.error('Bulk create notifications error:', error);
      throw error;
    }
  }

  // Get notifications by type
  async getNotificationsByType(req, res) {
    try {
      const { type, page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      if (!type) {
        return ApiResponse.badRequest(res, 'Notification type is required');
      }

      const [notifications, total] = await Promise.all([
        prisma.notification.findMany({
          where: { 
            userId: req.user.userId,
            type
          },
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
        prisma.notification.count({
          where: { 
            userId: req.user.userId,
            type
          }
        })
      ]);

      ApiResponse.paginated(res, notifications, {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }, `Notifications of type '${type}' retrieved successfully`);

    } catch (error) {
      console.error('Get notifications by type error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }
}

export default new NotificationController();