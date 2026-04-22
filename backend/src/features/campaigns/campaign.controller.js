import { prisma } from '../../config/prisma.js';
import { ApiResponse, ErrorHandler, ValidationHelper } from '../../core/utils/response.handler.js';

class CampaignController {
  // Request a new campaign
  async requestCampaign(req, res) {
    try {
      const { title, description, targetAmount } = req.body;
      const creatorId = req.user.userId;

      // Validation
      const validationRules = {
        title: [ValidationHelper.required],
        description: [ValidationHelper.required],
        targetAmount: [ValidationHelper.required, ValidationHelper.numeric]
      };

      const errors = ValidationHelper.validate(req.body, validationRules);
      if (errors) {
        return ApiResponse.validationError(res, errors);
      }

      if (parseFloat(targetAmount) <= 0) {
        return ApiResponse.badRequest(res, 'Target amount must be greater than zero');
      }

      const campaign = await prisma.campaign.create({
        data: {
          title,
          description,
          targetAmount: parseFloat(targetAmount),
          creatorId,
          status: 'pending'
        }
      });

      ApiResponse.created(res, campaign, 'Campaign request submitted successfully. Waiting for admin approval.');
    } catch (error) {
      console.error('Request campaign error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Get campaigns (Dynamic filtering)
  async getCampaigns(req, res) {
    try {
      const { status, creatorId, page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      // JWT does not embed role; load from DB so admins can list pending / all campaigns.
      const dbUser = await prisma.user.findUnique({
        where: { userId: req.user.userId },
        include: { role: true }
      });
      const userRole = dbUser?.role?.roleName;
      const where = {};

      // Admins can see everything. Users see approved by default.
      if (userRole === 'admin') {
        if (status) where.status = status;
        if (creatorId) where.creatorId = parseInt(creatorId);
      } else {
        // Normal users see approved campaigns or their own pending ones
        if (creatorId && parseInt(creatorId) === req.user.userId) {
          where.creatorId = req.user.userId;
          if (status) where.status = status;
        } else {
          where.status = 'approved';
        }
      }

      const [campaigns, total] = await Promise.all([
        prisma.campaign.findMany({
          where,
          skip,
          take: parseInt(limit),
          orderBy: { createdAt: 'desc' },
          include: {
            creator: {
              select: {
                name: true,
                email: true
              }
            }
          }
        }),
        prisma.campaign.count({ where })
      ]);

      ApiResponse.paginated(res, campaigns, {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }, 'Campaigns retrieved successfully');
    } catch (error) {
      console.error('Get campaigns error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Update campaign status (Admin only)
  async updateCampaignStatus(req, res) {
    try {
      const { id } = req.params;
      const { status } = req.body;

      const validStatuses = ['pending', 'approved', 'rejected', 'completed'];
      if (!validStatuses.includes(status)) {
        return ApiResponse.badRequest(res, 'Invalid campaign status');
      }

      const campaign = await prisma.campaign.update({
        where: { campaignId: parseInt(id) },
        data: { status }
      });

      ApiResponse.success(res, campaign, `Campaign status updated to ${status}`);
    } catch (error) {
      console.error('Update campaign status error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  async getCampaignById(req, res) {
    try {
      const { id } = req.params;
      const campaign = await prisma.campaign.findUnique({
        where: { campaignId: parseInt(id) },
        include: {
          creator: {
            select: { name: true, email: true }
          },
          donations: {
            where: { status: 'completed' },
            take: 10,
            orderBy: { createdAt: 'desc' }
          }
        }
      });

      if (!campaign) {
        return ApiResponse.notFound(res, 'Campaign not found');
      }

      ApiResponse.success(res, campaign, 'Campaign retrieved successfully');
    } catch (error) {
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }
}

export default new CampaignController();
