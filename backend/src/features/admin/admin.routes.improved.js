import express from 'express';
import adminController from './admin.controller.improved.js';
import { authenticateToken, requireRole } from '../../middleware/auth.middleware.js';

const router = express.Router();

// Custom middleware to attach io instance to request
const attachIo = (io) => (req, res, next) => {
  req.io = io;
  next();
};

export const setupAdminRoutes = (io) => {
  // All admin routes require authentication and admin role
  router.use(authenticateToken);
  router.use(requireRole('admin'));
  router.use(attachIo(io));

  // Incident management
  router.get('/incidents', (req, res) => adminController.getAllIncidents(req, res));
  router.delete('/incidents/:id', (req, res) => adminController.deleteIncident(req, res));
  
  router.post('/incidents/:id/assign', async (req, res) => {
    try {
      await adminController.assignRescueTeam(req, res);
      // If the response was successful, emit socket event
      if (res.statusCode === 200 || res.statusCode === 201) {
        const missionData = res.locals.mission;
        if (missionData && req.io) {
          req.io.emit('mission_assigned', missionData);
        }
      }
    } catch (error) {
      console.error('Socket emission error:', error);
    }
  });

  // Dashboard and statistics
  router.get('/dashboard/stats', (req, res) => adminController.getDashboardStats(req, res));
  
  // Volunteer management
  router.put('/volunteers/:id/approve', (req, res) => adminController.approveVolunteer(req, res));
  router.get('/volunteers', (req, res) => adminController.getVolunteers(req, res));
  
  // Rescue team management
  router.get('/rescue-teams', (req, res) => adminController.getRescueTeams(req, res));
  
  // Other entity management
  router.get('/notifications', (req, res) => {
    // This would use notification controller
    res.json({ message: 'Notifications endpoint - to be implemented' });
  });
  
  router.get('/donations', (req, res) => {
    // This would use donation controller
    res.json({ message: 'Donations endpoint - to be implemented' });
  });

  return router;
};