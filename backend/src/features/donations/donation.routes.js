import express from 'express';
import {
  createDonation,
  getDonations,
  getMyDonations,
  getDonationById,
  initiateEsewaDonation,
  confirmEsewaDonation,
  failEsewaDonation,
  getBankInfo
} from './donation.controller.js';
import { authenticateToken, optionalAuthenticateToken, requireRole } from '../../middleware/auth.middleware.js';

const router = express.Router();

router.get('/bank-info', getBankInfo);

router.post('/', optionalAuthenticateToken, createDonation);
router.post('/esewa/initiate', optionalAuthenticateToken, initiateEsewaDonation);
router.post('/esewa/confirm', confirmEsewaDonation);
router.post('/esewa/fail', failEsewaDonation);

router.get('/', authenticateToken, requireRole('admin'), getDonations);
router.get('/my', authenticateToken, getMyDonations);
router.get('/:id', authenticateToken, getDonationById);

export default router;
