import express from 'express';
import notificationController from './notification.controller.improved.js';
import { authenticateToken } from '../../middleware/auth.middleware.js';

const router = express.Router();

export const setupNotificationRoutes = (io) => {
  router.use(authenticateToken);

  // Notification management
  router.get('/', (req, res) => notificationController.getMyNotifications(req, res));
  router.get('/unread-count', (req, res) => notificationController.getUnreadCount(req, res));
  router.get('/type/:type', (req, res) => notificationController.getNotificationsByType(req, res));
  
  // Notification actions
  router.put('/:id/read', (req, res) => notificationController.markAsRead(req, res));
  router.put('/read-all', (req, res) => notificationController.markAllAsRead(req, res));
  router.delete('/:id', (req, res) => notificationController.deleteNotification(req, res));

  return router;
};