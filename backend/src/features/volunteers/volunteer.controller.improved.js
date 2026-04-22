import { prisma } from '../../config/prisma.js';
import { ApiResponse, ErrorHandler, ValidationHelper } from '../../core/utils/response.handler.js';

// Improved Volunteer Controller with generic patterns
class VolunteerController {
  // Register as volunteer
  async registerAsVolunteer(req, res) {
    try {
      const { skills, availability } = req.body;

      // Validation
      const validationRules = {
        skills: [ValidationHelper.required],
        availability: []
      };

      const errors = ValidationHelper.validate(req.body, validationRules);
      if (errors) {
        return ApiResponse.validationError(res, errors);
      }

      // Check if already registered
      const existing = await prisma.volunteer.findUnique({
        where: { userId: req.user.userId }
      });

      if (existing) {
        return ApiResponse.conflict(res, 'Already registered as volunteer');
      }

      const volunteer = await prisma.volunteer.create({
        data: {
          userId: req.user.userId,
          skills,
          availability: availability || 'available'
        },
        include: {
          user: {
            select: {
              name: true,
              email: true,
              phone: true
            }
          }
        }
      });

      ApiResponse.created(res, volunteer, 'Volunteer registration successful. Waiting for approval.');

    } catch (error) {
      console.error('Register volunteer error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Get volunteer profile
  async getMyVolunteerProfile(req, res) {
    try {
      const volunteer = await prisma.volunteer.findUnique({
        where: { userId: req.user.userId },
        include: {
          user: {
            select: {
              name: true,
              email: true,
              phone: true
            }
          }
        }
      });

      if (!volunteer) {
        return ApiResponse.notFound(res, 'Volunteer profile not found');
      }

      ApiResponse.success(res, volunteer, 'Volunteer profile retrieved successfully');

    } catch (error) {
      console.error('Get volunteer profile error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Request to join mission
  async requestToJoinMission(req, res) {
    try {
      const { id } = req.params;

      // Check if volunteer is approved
      const volunteer = await prisma.volunteer.findUnique({
        where: { userId: req.user.userId }
      });

      if (!volunteer || !volunteer.isApproved) {
        return ApiResponse.forbidden(res, 'Volunteer not approved');
      }

      // Check if mission exists
      const mission = await prisma.mission.findUnique({
        where: { missionId: parseInt(id) }
      });

      if (!mission) {
        return ApiResponse.notFound(res, 'Mission not found');
      }

      // Create notification for admin
      await prisma.notification.create({
        data: {
          userId: 1, // Assuming admin user exists, you might want to get all admin users
          incidentId: mission.incidentId,
          type: 'volunteer_request',
          message: `Volunteer ${req.user.name} requested to join mission ${id}`,
          isRead: false
        }
      });

      ApiResponse.success(res, null, 'Request to join mission submitted successfully');

    } catch (error) {
      console.error('Request to join mission error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Update volunteer availability
  async updateAvailability(req, res) {
    try {
      const { availability } = req.body;

      // Validation
      const validAvailabilities = ['available', 'busy', 'unavailable'];
      const validationRules = {
        availability: [value => ValidationHelper.enum(value, validAvailabilities, 'Availability')]
      };

      const errors = ValidationHelper.validate({ availability }, validationRules);
      if (errors) {
        return ApiResponse.validationError(res, errors);
      }

      const volunteer = await prisma.volunteer.update({
        where: { userId: req.user.userId },
        data: { availability },
        include: {
          user: {
            select: {
              name: true,
              email: true,
              phone: true
            }
          }
        }
      });

      ApiResponse.success(res, volunteer, 'Availability updated successfully');

    } catch (error) {
      console.error('Update availability error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Update volunteer skills
  async updateSkills(req, res) {
    try {
      const { skills } = req.body;

      // Validation
      const errors = ValidationHelper.validate({ skills }, {
        skills: [ValidationHelper.required]
      });

      if (errors) {
        return ApiResponse.validationError(res, errors);
      }

      const volunteer = await prisma.volunteer.update({
        where: { userId: req.user.userId },
        data: { skills },
        include: {
          user: {
            select: {
              name: true,
              email: true,
              phone: true
            }
          }
        }
      });

      ApiResponse.success(res, volunteer, 'Skills updated successfully');

    } catch (error) {
      console.error('Update skills error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Get available missions for volunteers
  async getAvailableMissions(req, res) {
    try {
      const { page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const missions = await prisma.mission.findMany({
        where: {
          missionStatus: {
            in: ['assigned', 'in_progress']
          }
        },
        skip,
        take: parseInt(limit),
        orderBy: { assignedAt: 'desc' },
        include: {
          incident: {
            include: {
              location: true,
              user: {
                select: {
                  name: true
                }
              }
            }
          },
          rescueTeam: true
        }
      });

      const total = await prisma.mission.count({
        where: {
          missionStatus: {
            in: ['assigned', 'in_progress']
          }
        }
      });

      ApiResponse.paginated(res, missions, {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }, 'Available missions retrieved successfully');

    } catch (error) {
      console.error('Get available missions error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }
}

export default new VolunteerController();