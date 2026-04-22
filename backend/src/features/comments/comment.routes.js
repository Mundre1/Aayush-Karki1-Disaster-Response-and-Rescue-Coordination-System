import express from 'express';
import { authenticateToken } from '../../middleware/auth.middleware.js';
import { createComment, getComments } from './comment.controller.js';

export const setupCommentRoutes = (io) => {
  const router = express.Router();

  // Get comments for an incident
  router.get('/:incidentId', authenticateToken, getComments);

  // Post a comment
  router.post('/:incidentId', authenticateToken, (req, res) => createComment(req, res, io));

  return router;
};
