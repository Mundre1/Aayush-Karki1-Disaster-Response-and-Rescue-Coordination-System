import express from 'express';
import {
  createIncident,
  getIncidents,
  getIncidentById,
  updateIncidentStatus,
  getMyIncidents,
  updateIncident,
  deleteIncident
} from './incident.controller.js';
import { authenticateToken } from '../../middleware/auth.middleware.js';
import { upload } from '../../middleware/upload.middleware.js';

const router = express.Router();

// Custom middleware to attach io instance to request
const attachIo = (io) => (req, res, next) => {
  req.io = io;
  next();
};

export const setupIncidentRoutes = (io) => {
  router.post('/', attachIo(io), authenticateToken, upload.single('image'), async (req, res) => {
    try {
      // Call the controller function
      await createIncident(req, res);

      // If the response was successful (status 201), emit socket event
      if (res.statusCode === 201) {
        const incidentData = res.locals.incident;
        if (incidentData) {
          // Emit real-time notifications to relevant stakeholders
          io.to('role_admin').emit('new_incident', {
            incident: incidentData,
            timestamp: new Date(),
            type: 'incident_reported'
          });
        }
      }
    } catch (error) {
      // Error handling is done in the controller
    }
  });

  router.get('/', authenticateToken, getIncidents);
  router.get('/my-incidents', authenticateToken, getMyIncidents);
  router.get('/:id', authenticateToken, getIncidentById);
  router.put('/:id/status', attachIo(io), authenticateToken, updateIncidentStatus);
  router.put('/:id', attachIo(io), authenticateToken, upload.single('image'), updateIncident);
  router.delete('/:id', authenticateToken, deleteIncident);

  return router;
};

export default router;

