import express from 'express';
import volunteerController from './volunteer.controller.improved.js';
import { authenticateToken, requireRole } from '../../middleware/auth.middleware.js';

const router = express.Router();

export const setupVolunteerRoutes = (io) => {
  router.use(authenticateToken);
  router.use(requireRole('volunteer', 'citizen', 'admin'));

  // Volunteer registration and profile
  router.post('/register', (req, res) => volunteerController.registerAsVolunteer(req, res));
  router.get('/profile', (req, res) => volunteerController.getMyVolunteerProfile(req, res));
  
  // Profile updates
  router.put('/availability', (req, res) => volunteerController.updateAvailability(req, res));
  router.put('/skills', (req, res) => volunteerController.updateSkills(req, res));
  
  // Mission participation
  router.get('/missions/available', (req, res) => volunteerController.getAvailableMissions(req, res));
  router.post('/missions/:id/request', (req, res) => volunteerController.requestToJoinMission(req, res));

  return router;
};