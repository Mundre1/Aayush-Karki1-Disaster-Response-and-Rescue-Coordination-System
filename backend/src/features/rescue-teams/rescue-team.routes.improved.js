import express from 'express';
import rescueTeamController from './rescue-team.controller.improved.js';
import { authenticateToken, requireRole } from '../../middleware/auth.middleware.js';

const router = express.Router();

// Custom middleware to attach io instance to request
const attachIo = (io) => (req, res, next) => {
  req.io = io;
  next();
};

export const setupRescueTeamRoutes = (io) => {
  router.use(authenticateToken);
  router.use(requireRole('rescue_team', 'admin'));
  router.use(attachIo(io));

  // Mission management
  router.get('/missions', (req, res) => rescueTeamController.getMyMissions(req, res));
  
  router.put('/missions/:id/status', async (req, res) => {
    try {
      await rescueTeamController.updateMissionStatus(req, res);
      // Emit socket event if response was successful
      if ((res.statusCode === 200 || res.statusCode === 201) && res.locals.missionUpdate) {
        req.io.emit('mission_status_updated', res.locals.missionUpdate);
      }
    } catch (error) {
      console.error('Socket emission error:', error);
    }
  });

  // Location tracking
  router.post('/location', async (req, res) => {
    try {
      await rescueTeamController.updateLocation(req, res);
      // Emit socket event if response was successful
      if ((res.statusCode === 200 || res.statusCode === 201) && res.locals.locationUpdate) {
        req.io.emit('rescue_team_location', res.locals.locationUpdate);
      }
    } catch (error) {
      console.error('Socket emission error:', error);
    }
  });

  // Profile management
  router.get('/profile', (req, res) => rescueTeamController.getProfile(req, res));
  router.put('/availability', (req, res) => rescueTeamController.updateAvailability(req, res));

  return router;
};