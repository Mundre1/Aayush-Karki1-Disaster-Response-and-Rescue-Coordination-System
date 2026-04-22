import { prisma } from '../../config/prisma.js';

export const createComment = async (req, res, io) => {
  try {
    const { incidentId } = req.params;
    const { content } = req.body;

    console.log(`💬 Creating comment for incident ${incidentId}...`);

    if (!content || content.trim() === '') {
      return res.status(400).json({ message: 'Comment content is required' });
    }

    // Ensure req.user exists (set by auth middleware)
    if (!req.user || !req.user.userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const userId = req.user.userId;

    // Check if incident exists
    const incident = await prisma.incident.findUnique({
      where: { incidentId: parseInt(incidentId) }
    });

    if (!incident) {
      return res.status(404).json({ message: 'Incident not found' });
    }

    const comment = await prisma.comment.create({
      data: {
        content,
        incidentId: parseInt(incidentId),
        userId,
      },
      include: {
        user: {
          select: {
            name: true,
            role: {
              select: {
                roleName: true
              }
            }
          }
        }
      }
    });

    console.log(`✅ Comment created: ${comment.commentId}`);

    // Emit socket event for real-time updates
    if (io) {
      try {
        // Emit to the specific incident room and to admins
        io.to(`incident_${incidentId}`).emit('comment_added', { incidentId: parseInt(incidentId), comment });
        io.to('role_3').emit('comment_added', { incidentId: parseInt(incidentId), comment });
        // Also broadcast for backward compatibility if needed
        io.emit('comment_added', { incidentId: parseInt(incidentId), comment });
      } catch (socketError) {
        console.error('⚠️ Socket emission failed (non-fatal):', socketError);
      }
    }

    return res.status(201).json(comment);
  } catch (error) {
    console.error('❌ Error creating comment:', error);
    if (!res.headersSent) {
      res.status(500).json({ message: 'Failed to create comment', error: error.message });
    }
  }
};

export const getComments = async (req, res) => {
  try {
    const { incidentId } = req.params;

    const comments = await prisma.comment.findMany({
      where: {
        incidentId: parseInt(incidentId)
      },
      include: {
        user: {
          select: {
            name: true,
            role: {
              select: {
                roleName: true
              }
            }
          }
        }
      },
      orderBy: {
        createdAt: 'asc'
      }
    });

    res.json(comments);
  } catch (error) {
    console.error('Error fetching comments:', error);
    res.status(500).json({ message: 'Failed to fetch comments' });
  }
};
