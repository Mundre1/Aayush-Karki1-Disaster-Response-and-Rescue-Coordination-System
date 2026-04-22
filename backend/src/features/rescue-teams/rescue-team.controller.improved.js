import { prisma } from '../../config/prisma.js';
import { ApiResponse, ErrorHandler } from '../../core/utils/response.handler.js';

// Improved Rescue Team Controller with generic patterns
class RescueTeamController {
  // Get missions assigned to the rescue team
  async getMyMissions(req, res) {
    try {
      const missions = await prisma.mission.findMany({
        where: {
          OR: [
            { rescueTeamId: req.user.rescueTeamId },
            { userId: req.user.userId }
          ]
        },
        include: {
          incident: {
            include: {
              location: true,
              user: {
                select: {
                  name: true,
                  phone: true
                }
              }
            }
          },
          rescueTeam: true
        },
        orderBy: { assignedAt: 'desc' }
      });

      ApiResponse.success(res, missions, 'Missions retrieved successfully');

    } catch (error) {
      console.error('Get my missions error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Update mission status
  async updateMissionStatus(req, res) {
    try {
      const { id } = req.params;
      const { missionStatus, note } = req.body;

      const mission = await prisma.mission.update({
        where: { missionId: parseInt(id) },
        data: { missionStatus },
        include: {
          incident: true,
          rescueTeam: true
        }
      });

      // Update incident status if mission is completed
      if (missionStatus === 'completed') {
        await prisma.incident.update({
          where: { incidentId: mission.incidentId },
          data: { status: 'resolved' }
        });

        await prisma.mission.update({
          where: { missionId: parseInt(id) },
          data: { completedAt: new Date() }
        });
      }

      // Create incident update
      if (note) {
        await prisma.incidentUpdate.create({
          data: {
            incidentId: mission.incidentId,
            userId: req.user.userId,
            status: missionStatus,
            note
          }
        });
      }

      // Store mission data for socket emission
      res.locals.missionUpdate = { missionId: parseInt(id), missionStatus };

      ApiResponse.success(res, mission, 'Mission status updated successfully');

    } catch (error) {
      console.error('Update mission status error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Update rescue team location
  async updateLocation(req, res) {
    try {
      const { latitude, longitude } = req.body;

      // Validate coordinates
      if (!latitude || !longitude) {
        return ApiResponse.badRequest(res, 'Latitude and longitude are required');
      }

      // Store location data for socket emission
      res.locals.locationUpdate = {
        userId: req.user.userId,
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        timestamp: new Date()
      };

      ApiResponse.success(res, null, 'Location updated successfully');

    } catch (error) {
      console.error('Update location error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Get rescue team profile
  async getProfile(req, res) {
    try {
      // Assuming rescue team ID is stored in user object or needs to be fetched
      const rescueTeam = await prisma.rescueTeam.findFirst({
        where: { 
          // This would depend on how rescue team association is stored
          // For now, returning all teams as example
        }
      });

      if (!rescueTeam) {
        return ApiResponse.notFound(res, 'Rescue team profile not found');
      }

      ApiResponse.success(res, rescueTeam, 'Rescue team profile retrieved successfully');

    } catch (error) {
      console.error('Get rescue team profile error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Update rescue team availability
  async updateAvailability(req, res) {
    try {
      const { isActive, specialization } = req.body;

      // This would update rescue team availability
      // Implementation depends on your data model
      const updatedTeam = {
        isActive: isActive !== undefined ? isActive : true,
        specialization: specialization || null,
        updatedAt: new Date()
      };

      ApiResponse.success(res, updatedTeam, 'Rescue team availability updated successfully');

    } catch (error) {
      console.error('Update availability error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }
}

export default new RescueTeamController();