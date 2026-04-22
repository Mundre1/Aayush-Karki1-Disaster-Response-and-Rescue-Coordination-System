import { prisma } from '../../config/prisma.js';
import { ApiResponse, ErrorHandler, ValidationHelper } from '../../core/utils/response.handler.js';

// Improved Donation Controller with generic patterns
class DonationController {
  // Create donation
  async createDonation(req, res) {
    try {
      const { donorName, donorEmail, amount, paymentMethod, transactionId } = req.body;

      // Validation
      const validationRules = {
        amount: [ValidationHelper.required, ValidationHelper.numeric],
        paymentMethod: [ValidationHelper.required]
      };

      if (donorEmail) {
        validationRules.donorEmail = [ValidationHelper.email];
      }

      const errors = ValidationHelper.validate(req.body, validationRules);
      if (errors) {
        return ApiResponse.validationError(res, errors);
      }

      // Validate amount is positive
      const amountValue = parseFloat(amount);
      if (amountValue <= 0) {
        return ApiResponse.badRequest(res, 'Amount must be greater than zero');
      }

      const donation = await prisma.donation.create({
        data: {
          donorName: donorName || null,
          donorEmail: donorEmail || null,
          amount: amountValue,
          paymentMethod,
          transactionId: transactionId || null,
          status: transactionId ? 'completed' : 'pending'
        }
      });

      // In a real scenario, you would integrate with payment gateway here
      // For now, we'll simulate payment processing
      if (transactionId) {
        await prisma.donation.update({
          where: { donationId: donation.donationId },
          data: { status: 'completed' }
        });
      }

      ApiResponse.created(res, donation, 'Donation recorded successfully');

    } catch (error) {
      console.error('Create donation error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Get donations with filters
  async getDonations(req, res) {
    try {
      const { status, donorName, startDate, endDate, page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const where = {};

      if (status) where.status = status;
      if (donorName) where.donorName = { contains: donorName, mode: 'insensitive' };
      
      if (startDate || endDate) {
        where.createdAt = {};
        if (startDate) where.createdAt.gte = new Date(startDate);
        if (endDate) where.createdAt.lte = new Date(endDate);
      }

      const [donations, total] = await Promise.all([
        prisma.donation.findMany({
          where,
          skip,
          take: parseInt(limit),
          orderBy: { createdAt: 'desc' }
        }),
        prisma.donation.count({ where })
      ]);

      // Calculate statistics
      const totalAmount = await prisma.donation.aggregate({
        where: { status: 'completed' },
        _sum: { amount: true }
      });

      const stats = {
        totalAmount: totalAmount._sum.amount || 0,
        totalDonations: total,
        completedDonations: await prisma.donation.count({ where: { status: 'completed' } }),
        pendingDonations: await prisma.donation.count({ where: { status: 'pending' } })
      };

      ApiResponse.withMeta(res, donations, { 
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        },
        stats
      }, 'Donations retrieved successfully');

    } catch (error) {
      console.error('Get donations error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Get donation by ID
  async getDonationById(req, res) {
    try {
      const { id } = req.params;

      const donation = await prisma.donation.findUnique({
        where: { donationId: parseInt(id) }
      });

      if (!donation) {
        return ApiResponse.notFound(res, 'Donation not found');
      }

      ApiResponse.success(res, donation, 'Donation retrieved successfully');

    } catch (error) {
      console.error('Get donation by id error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Update donation status
  async updateDonationStatus(req, res) {
    try {
      const { id } = req.params;
      const { status, transactionId } = req.body;

      // Validation
      const validStatuses = ['pending', 'completed', 'failed', 'refunded'];
      const errors = ValidationHelper.validate({ status }, {
        status: [value => ValidationHelper.enum(value, validStatuses, 'Status')]
      });

      if (errors) {
        return ApiResponse.validationError(res, errors);
      }

      const updateData = { status };
      if (transactionId) {
        updateData.transactionId = transactionId;
      }

      const donation = await prisma.donation.update({
        where: { donationId: parseInt(id) },
        data: updateData
      });

      ApiResponse.success(res, donation, 'Donation status updated successfully');

    } catch (error) {
      console.error('Update donation status error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Get donation statistics
  async getDonationStats(req, res) {
    try {
      const [
        totalDonations,
        totalAmount,
        completedDonations,
        pendingDonations,
        failedDonations,
        recentDonations
      ] = await Promise.all([
        prisma.donation.count(),
        prisma.donation.aggregate({
          where: { status: 'completed' },
          _sum: { amount: true }
        }),
        prisma.donation.count({ where: { status: 'completed' } }),
        prisma.donation.count({ where: { status: 'pending' } }),
        prisma.donation.count({ where: { status: 'failed' } }),
        prisma.donation.findMany({
          where: { status: 'completed' },
          take: 10,
          orderBy: { createdAt: 'desc' },
          select: {
            amount: true,
            createdAt: true,
            donorName: true
          }
        })
      ]);

      const stats = {
        totalDonations,
        totalAmount: totalAmount._sum.amount || 0,
        completedDonations,
        pendingDonations,
        failedDonations,
        successRate: totalDonations > 0 ? Math.round((completedDonations / totalDonations) * 100) : 0,
        averageDonation: completedDonations > 0 ? 
          Math.round((totalAmount._sum.amount || 0) / completedDonations * 100) / 100 : 0
      };

      ApiResponse.success(res, { stats, recentDonations }, 'Donation statistics retrieved successfully');

    } catch (error) {
      console.error('Get donation stats error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }

  // Get donations by user (if user tracking is implemented)
  async getUserDonations(req, res) {
    try {
      // This would require user association with donations
      // For now, returning all donations as example
      const { page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const [donations, total] = await Promise.all([
        prisma.donation.findMany({
          where: { status: 'completed' },
          skip,
          take: parseInt(limit),
          orderBy: { createdAt: 'desc' }
        }),
        prisma.donation.count({ where: { status: 'completed' } })
      ]);

      ApiResponse.paginated(res, donations, {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }, 'User donations retrieved successfully');

    } catch (error) {
      console.error('Get user donations error:', error);
      const errorResponse = ErrorHandler.handlePrismaError(error) || ErrorHandler.handleGenericError(error);
      ApiResponse.error(res, errorResponse.message, errorResponse.statusCode, errorResponse.details);
    }
  }
}

export default new DonationController();