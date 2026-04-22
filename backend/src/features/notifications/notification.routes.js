import express from 'express';
import { 
  getMyNotifications, 
  markAsRead,
  markAllAsRead 
} from './notification.controller.js';
import { authenticateToken } from '../../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticateToken);

router.get('/', getMyNotifications);
router.put('/:id/read', markAsRead);
router.put('/read-all', markAllAsRead);

export default router;

