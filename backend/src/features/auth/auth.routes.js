import express from 'express';
import {
  register,
  login,
  getProfile,
  updateProfile,
  getAvailableOrganizations
} from './auth.controller.js';
import { authenticateToken } from '../../middleware/auth.middleware.js';

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.get('/organizations', getAvailableOrganizations);
router.get('/profile', authenticateToken, getProfile);
router.put('/profile', authenticateToken, updateProfile);

export default router;

