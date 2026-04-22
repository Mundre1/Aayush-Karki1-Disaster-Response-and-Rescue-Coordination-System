import { prisma } from '../../config/prisma.js';
import { ApiResponse, ErrorHandler } from '../../core/utils/response.handler.js';

// Improved Admin Controller with generic patterns
class AdminController {
  // Get all incidents with filters and pagination
  async getAllIncidents(req, res) {
    try {
      const { status, severity, page = 1, limit = 50 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const where = {};
      if (status) where.status = status;
      if (severity) where.severity = severity;

      const [incidents, total] = await Promise.all([
        prisma.incident.findMany({
          where,
          skip,
          take: parseInt(limit),
          orderBy: { reportedAt: 'desc' },
          include: {
            user: {
              select: {
                name: true,
                email: true,
                phone: true
              }
            },
            location: true,
            missions: {
              include: {
                rescueTeam: true
              }
            }
          }
        }),
        prisma.incident.count({ where })
      ]);

      ApiResponse.paginated(res, incidents, {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }, 'Incidents retrieved successfully');

    } catch (error) {
      console.error('Get all incidents error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Assign rescue team to incident
  async assignRescueTeam(req, res) {
    try {
      const { id } = req.params;
      const { rescueTeamId } = req.body;

      // Check if incident exists
      const incident = await prisma.incident.findUnique({
        where: { incidentId: parseInt(id) }
      });

      if (!incident) {
        return ApiResponse.notFound(res, 'Incident not found');
      }

      // Create mission
      const mission = await prisma.mission.create({
        data: {
          incidentId: parseInt(id),
          rescueTeamId: parseInt(rescueTeamId),
          missionStatus: 'assigned'
        },
        include: {
          rescueTeam: true,
          incident: {
            include: {
              location: true
            }
          }
        }
      });

      // Update incident status
      await prisma.incident.update({
        where: { incidentId: parseInt(id) },
        data: { status: 'assigned' }
      });

      // Store mission data for socket emission
      res.locals.mission = mission;

      ApiResponse.success(res, mission, 'Rescue team assigned successfully');

    } catch (error) {
      console.error('Assign rescue team error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Delete incident
  async deleteIncident(req, res) {
    try {
      const { id } = req.params;

      await prisma.incident.delete({
        where: { incidentId: parseInt(id) }
      });

      ApiResponse.success(res, null, 'Incident deleted successfully');

    } catch (error) {
      console.error('Delete incident error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Get dashboard statistics
  async getDashboardStats(req, res) {
    try {
      const [
        totalIncidents,
        pendingIncidents,
        activeMissions,
        totalVolunteers,
        recentIncidents
      ] = await Promise.all([
        prisma.incident.count(),
        prisma.incident.count({ where: { status: 'pending' } }),
        prisma.mission.count({ where: { missionStatus: { in: ['assigned', 'in_progress'] } } }),
        prisma.volunteer.count({ where: { isApproved: true } }),
        prisma.incident.findMany({
          take: 5,
          orderBy: { reportedAt: 'desc' },
          include: {
            location: true,
            user: {
              select: {
                name: true
              }
            }
          }
        })
      ]);

      const stats = {
        totalIncidents,
        pendingIncidents,
        activeMissions,
        totalVolunteers
      };

      ApiResponse.withMeta(res, recentIncidents, { stats }, 'Dashboard statistics retrieved successfully');

    } catch (error) {
      console.error('Get dashboard stats error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Approve volunteer
  async approveVolunteer(req, res) {
    try {
      const { id } = req.params;

      const volunteer = await prisma.volunteer.update({
        where: { volunteerId: parseInt(id) },
        data: { isApproved: true },
        include: {
          user: {
            select: {
              name: true,
              email: true
            }
          }
        }
      });

      ApiResponse.success(res, volunteer, 'Volunteer approved successfully');

    } catch (error) {
      console.error('Approve volunteer error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Generic methods for other entities
  async getRescueTeams(req, res) {
    try {
      const { page = 1, limit = 20, isActive } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const where = {};
      if (isActive !== undefined) where.isActive = isActive === 'true';

      const [teams, total] = await Promise.all([
        prisma.rescueTeam.findMany({
          where,
          skip,
          take: parseInt(limit),
          orderBy: { createdAt: 'desc' }
        }),
        prisma.rescueTeam.count({ where })
      ]);

      ApiResponse.paginated(res, teams, {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }, 'Rescue teams retrieved successfully');

    } catch (error) {
      console.error('Get rescue teams error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  async getVolunteers(req, res) {
    try {
      const { page = 1, limit = 20, isApproved } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const where = {};
      if (isApproved !== undefined) where.isApproved = isApproved === 'true';

      const [volunteers, total] = await Promise.all([
        prisma.volunteer.findMany({
          where,
          skip,
          take: parseInt(limit),
          orderBy: { createdAt: 'desc' },
          include: {
            user: {
              select: {
                name: true,
                email: true,
                phone: true
              }
            }
          }
        }),
        prisma.volunteer.count({ where })
      ]);

      ApiResponse.paginated(res, volunteers, {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }, 'Volunteers retrieved successfully');

    } catch (error) {
      console.error('Get volunteers error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }
}

export default new AdminController();