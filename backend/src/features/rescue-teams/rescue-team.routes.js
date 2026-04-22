import express from 'express';
import {
  getMyMissions,
  updateMissionStatus,
  updateLocation,
  requestMissionAssignment,
  getOrganizationMembers
} from './rescue-team.controller.js';
import { authenticateToken, requireRole } from '../../middleware/auth.middleware.js';
import { prisma } from '../../config/prisma.js';
import { upload } from '../../middleware/upload.middleware.js';

const router = express.Router();

// Custom middleware to attach io instance to request
const attachIo = (io) => (req, res, next) => {
  req.io = io;
  next();
};

export const setupRescueTeamRoutes = (io) => {
  router.use(authenticateToken);
  router.use(requireRole('responder', 'rescue_team', 'admin'));
  router.use(attachIo(io));

  router.get('/missions', getMyMissions);
  router.get('/organization/members', getOrganizationMembers);
  router.post('/missions/:id/request', requestMissionAssignment);

  router.put('/missions/:id/status', upload.single('image'), async (req, res) => {
    try {
      await updateMissionStatus(req, res);
      // Emit socket event if response was successful
      if (res.statusCode === 200 && res.locals.missionUpdate) {
        req.io.emit('mission_status_updated', res.locals.missionUpdate);
      }
    } catch (error) {
      // Error handling is done in the controller
    }
  });

  router.post('/location', async (req, res) => {
    try {
      await updateLocation(req, res);
      // Emit socket event if response was successful
      if (res.statusCode === 200 && res.locals.locationUpdate) {
        try {
          // Fetch role IDs for secure broadcasting
          const roles = await prisma.role.findMany({
            where: {
              roleName: {
                in: ['responder', 'rescue_team', 'admin']
              }
            }
          });

          const responderRole = roles.find(
            (r) => r.roleName === 'responder' || r.roleName === 'rescue_team'
          );
          const adminRole = roles.find(r => r.roleName === 'admin');

          // Broadcast to relevant rooms only
          if (responderRole && adminRole) {
            req.io.to(`role_${responderRole.roleId}`)
                  .to(`role_${adminRole.roleId}`)
                  .emit('responder_location', res.locals.locationUpdate);
            req.io.to(`role_${responderRole.roleId}`)
                  .to(`role_${adminRole.roleId}`)
                  .emit('rescue_team_location', res.locals.locationUpdate);
          } else if (responderRole) {
             req.io.to(`role_${responderRole.roleId}`)
                   .emit('responder_location', res.locals.locationUpdate);
             req.io.to(`role_${responderRole.roleId}`)
                   .emit('rescue_team_location', res.locals.locationUpdate);
          } else if (adminRole) {
             req.io.to(`role_${adminRole.roleId}`)
                   .emit('responder_location', res.locals.locationUpdate);
             req.io.to(`role_${adminRole.roleId}`)
                   .emit('rescue_team_location', res.locals.locationUpdate);
          }
        } catch (socketError) {
          console.error('Socket broadcast error:', socketError);
        }
      }
    } catch (error) {
      // Error handling is done in the controller
    }
  });

  return router;
};

