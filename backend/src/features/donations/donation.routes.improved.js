import express from 'express';
import donationController from './donation.controller.improved.js';

const router = express.Router();

export const setupDonationRoutes = (io) => {
  // Public donation endpoints
  router.post('/', (req, res) => donationController.createDonation(req, res));
  router.get('/stats', (req, res) => donationController.getDonationStats(req, res));
  
  // Protected endpoints (require authentication)
  router.use((req, res, next) => {
    // Add authentication middleware here if needed
    next();
  });
  
  router.get('/', (req, res) => donationController.getDonations(req, res));
  router.get('/:id', (req, res) => donationController.getDonationById(req, res));
  router.put('/:id/status', (req, res) => donationController.updateDonationStatus(req, res));
  router.get('/user/donations', (req, res) => donationController.getUserDonations(req, res));

  return router;
};