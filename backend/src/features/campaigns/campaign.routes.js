import { Router } from 'express';
import campaignController from './campaign.controller.js';
import { authenticateToken, requireRole } from '../../middleware/auth.middleware.js';

const router = Router();

// Register concrete paths before /:id so e.g. GET /request is not captured as an id.
router.get('/', authenticateToken, campaignController.getCampaigns);
router.post('/request', authenticateToken, campaignController.requestCampaign);
router.get('/:id', authenticateToken, campaignController.getCampaignById);

// Admin specific
router.patch('/:id/status', authenticateToken, requireRole('admin'), campaignController.updateCampaignStatus);

export default router;
