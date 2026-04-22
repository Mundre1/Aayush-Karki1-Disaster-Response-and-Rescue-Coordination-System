import express from 'express';
import {
  getAllIncidents,
  assignRescueTeam,
  deleteIncident,
  getDashboardStats,
  approveVolunteer,
  getVolunteers,
  getRescueTeams,
  assignUserToTeam,
  verifyIncident,
  getPendingBankDonations,
  confirmBankDonation,
  rejectBankDonation,
  getVolunteerMissionRequests,
  approveVolunteerMissionRequest,
  rejectVolunteerMissionRequest,
  getPendingResponderApprovals,
  reviewResponderRegistration,
  reviewOrganizationRequest,
  getOrganizationDetails
} from './admin.controller.js';
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

  router.get('/donations/bank/pending', getPendingBankDonations);
  router.put('/donations/bank/:donationId/confirm', confirmBankDonation);
  router.put('/donations/bank/:donationId/reject', rejectBankDonation);

  router.get('/volunteer-mission-requests', getVolunteerMissionRequests);
  router.put('/volunteer-mission-requests/:requestId/approve', approveVolunteerMissionRequest);
  router.put('/volunteer-mission-requests/:requestId/reject', rejectVolunteerMissionRequest);
  router.get('/responder-approvals/pending', getPendingResponderApprovals);
  router.put('/responders/:id/review', reviewResponderRegistration);
  router.put('/organizations/:id/review', reviewOrganizationRequest);

  router.get('/incidents', getAllIncidents);
  router.post('/incidents/:id/verify', verifyIncident);
  router.get('/dashboard/stats', getDashboardStats);
  router.get('/volunteers', getVolunteers);
  router.get('/rescue-teams', getRescueTeams);
  router.get('/organizations', getRescueTeams);
  router.get('/organizations/:id/details', getOrganizationDetails);

  router.put('/users/:id/team', assignUserToTeam);
  router.put('/users/:id/organization', assignUserToTeam);

  const assignOrganizationWithRealtime = async (req, res) => {
    try {
      await assignRescueTeam(req, res);

      // If successful, emit real-time mission alert to assigned organization members.
      if (res.statusCode === 200) {
        const missionData = res.locals.mission;
        if (missionData && req.io) {
          const memberIds = res.locals.organizationMemberUserIds || [];
          for (const memberId of memberIds) {
            req.io.to(`user_${memberId}`).emit('mission_assigned', missionData);
          }
        }
      }
    } catch (error) {
      console.error('Assign organization route error:', error);
      if (!res.headersSent) {
        res.status(500).json({ message: 'Internal server error' });
      }
    }
  };
  router.post('/incidents/:id/assign', assignOrganizationWithRealtime);
  router.post('/incidents/:id/assign-organization', assignOrganizationWithRealtime);

  router.delete('/incidents/:id', deleteIncident);
  router.put('/volunteers/:id/approve', approveVolunteer);

  return router;
};

