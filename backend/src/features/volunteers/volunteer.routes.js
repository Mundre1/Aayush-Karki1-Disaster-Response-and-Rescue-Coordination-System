import express from 'express';
import {
  registerAsVolunteer,
  getMyVolunteerProfile,
  getMyMissionRequests,
  requestToJoinMission,
  updateAvailability
} from './volunteer.controller.js';
import { authenticateToken } from '../../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticateToken);

router.post('/register', registerAsVolunteer);
router.get('/profile', getMyVolunteerProfile);
router.get('/mission-requests', getMyMissionRequests);
router.post('/missions/:id/request', requestToJoinMission);
router.put('/availability', updateAvailability);

export default router;

