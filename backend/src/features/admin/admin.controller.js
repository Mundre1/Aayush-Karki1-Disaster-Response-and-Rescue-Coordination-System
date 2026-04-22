import { prisma } from '../../config/prisma.js';
import { notifyUser, notifyOrganization } from '../../utils/notify.js';

const withMissionAliases = (incident) => ({
  ...incident,
  missions: (incident.missions || []).map((mission) => ({
    ...mission,
    rescueTeamId: mission.organizationId,
    rescueTeam: mission.organization
  }))
});

export const getAllIncidents = async (req, res) => {
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
              organization: true
            }
          },
          incidentUpdates: {
            orderBy: { updatedAt: 'desc' },
            take: 5,
            include: {
              user: {
                select: { name: true }
              }
            }
          }
        }
      }),
      prisma.incident.count({ where })
    ]);

    res.json({
      incidents: incidents.map(withMissionAliases),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get all incidents error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const assignUserToTeam = async (req, res) => {
  try {
    const { id } = req.params; // User ID
    const { organizationId, rescueTeamId } = req.body; // New Organization ID (or null to remove)
    const targetOrganizationId = organizationId ?? rescueTeamId;

    // Validate if organization exists if provided
    if (targetOrganizationId) {
      const organization = await prisma.organization.findUnique({
        where: { organizationId: parseInt(targetOrganizationId) }
      });
      if (!organization) {
        return res.status(404).json({ message: 'Organization not found' });
      }
    }

    const user = await prisma.user.update({
      where: { userId: parseInt(id) },
      data: {
        organizationId: targetOrganizationId ? parseInt(targetOrganizationId) : null
      },
      include: {
        organization: true
      }
    });

    res.json({
      message: 'User assigned to organization successfully',
      user: {
        userId: user.userId,
        name: user.name,
        email: user.email,
        organizationId: user.organizationId,
        organization: user.organization,
        rescueTeamId: user.organizationId,
        rescueTeam: user.organization
      }
    });
  } catch (error) {
    console.error('Assign user to team error:', error);
    if (error.code === 'P2025') { // Prisma error for record not found
        return res.status(404).json({ message: 'User not found' });
    }
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const assignRescueTeam = async (req, res) => {
  try {
    const { id } = req.params;
    const { organizationId, rescueTeamId } = req.body;
    const incidentId = parseInt(id);
    const targetOrganizationId = parseInt(organizationId ?? rescueTeamId);

    // Check if incident exists
    const incident = await prisma.incident.findUnique({
      where: { incidentId }
    });

    if (!incident) {
      return res.status(404).json({ message: 'Incident not found' });
    }

    const organization = await prisma.organization.findUnique({
      where: { organizationId: targetOrganizationId }
    });
    if (!organization) {
      return res.status(404).json({ message: 'Organization not found' });
    }

    const assigningAdmin = await prisma.user.findUnique({
      where: { userId: req.user.userId },
      select: { name: true, email: true }
    });

    // Create mission
    const mission = await prisma.mission.create({
      data: {
        incidentId,
        organizationId: targetOrganizationId,
        missionStatus: 'assigned'
      },
      include: {
        organization: true,
        incident: {
          include: {
            location: true
          }
        }
      }
    });

    // Update incident status
    await prisma.incident.update({
      where: { incidentId },
      data: { status: 'assigned' }
    });

    // Save assignment in incident history (shown in History tab)
    await prisma.incidentUpdate.create({
      data: {
        incidentId,
        userId: req.user.userId,
        status: 'assigned',
        note: [
          `Mission #${mission.missionId} assigned`,
          `Organization: ${organization.organizationName}`,
          `Assigned by: ${assigningAdmin?.name || assigningAdmin?.email || `Admin #${req.user.userId}`}`
        ].join(' | ')
      }
    });

    // Notify all organization members in DB notifications
    await notifyOrganization(targetOrganizationId, {
      incidentId,
      type: 'mission_assigned',
      message: `Your organization has been assigned to incident: ${incident.title}`
    });

    // Collect member ids for targeted real-time alerts
    const orgMembers = await prisma.user.findMany({
      where: { organizationId: targetOrganizationId },
      select: { userId: true }
    });

    // Store mission data for socket emission
    res.locals.mission = mission;
    res.locals.organizationMemberUserIds = orgMembers.map((m) => m.userId);

    res.json({
      message: 'Responder organization assigned successfully',
      mission: {
        ...mission,
        rescueTeamId: mission.organizationId,
        rescueTeam: mission.organization
      }
    });
  } catch (error) {
    console.error('Assign rescue team error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const deleteIncident = async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.incident.delete({
      where: { incidentId: parseInt(id) }
    });

    res.json({ message: 'Incident deleted successfully' });
  } catch (error) {
    console.error('Delete incident error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getDashboardStats = async (req, res) => {
  try {
    const [
      totalIncidents,
      pendingIncidents,
      activeMissions,
      totalVolunteers,
      recentIncidents,
      donationCount,
      pendingDonationCount,
      donationSum
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
      }),
      prisma.donation.count(),
      prisma.donation.count({ where: { status: 'pending' } }),
      prisma.donation.aggregate({
        _sum: { amount: true },
        where: { status: 'completed' }
      })
    ]);

    res.json({
      stats: {
        totalIncidents,
        pendingIncidents,
        activeMissions,
        totalVolunteers,
        donations: {
          totalAmount: Number(donationSum._sum.amount || 0),
          totalCount: donationCount,
          pendingCount: pendingDonationCount
        }
      },
      recentIncidents
    });
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const approveVolunteer = async (req, res) => {
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

    await notifyUser(volunteer.userId, {
      type: 'volunteer_approved',
      message: 'Your volunteer registration was approved. You can now request to join missions.',
      incidentId: null
    });

    res.json({
      message: 'Volunteer approved successfully',
      volunteer
    });
  } catch (error) {
    console.error('Approve volunteer error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const verifyIncident = async (req, res) => {
  try {
    const { id } = req.params;
    const { note } = req.body;
    const incidentId = parseInt(id);

    const incident = await prisma.incident.findUnique({
      where: { incidentId }
    });
    if (!incident) {
      return res.status(404).json({ message: 'Incident not found' });
    }

    const updated = await prisma.incident.update({
      where: { incidentId },
      data: { status: 'verified' }
    });

    await prisma.incidentUpdate.create({
      data: {
        incidentId,
        userId: req.user.userId,
        status: 'verified',
        note: note?.trim() || 'Incident verified by administrator'
      }
    });

    res.json({
      message: 'Incident verified',
      incident: updated
    });
  } catch (error) {
    console.error('Verify incident error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getPendingBankDonations = async (req, res) => {
  try {
    const donations = await prisma.donation.findMany({
      where: {
        paymentMethod: 'bank_transfer',
        status: 'pending'
      },
      orderBy: { createdAt: 'desc' },
      include: {
        user: {
          select: { name: true, email: true }
        }
      }
    });
    res.json({ donations });
  } catch (error) {
    console.error('Get pending bank donations error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const confirmBankDonation = async (req, res) => {
  try {
    const { donationId } = req.params;
    const id = parseInt(donationId);
    const donation = await prisma.donation.findUnique({ where: { donationId: id } });
    if (!donation || donation.paymentMethod !== 'bank_transfer' || donation.status !== 'pending') {
      return res.status(400).json({ message: 'Invalid or non-pending bank donation' });
    }
    const updated = await prisma.donation.update({
      where: { donationId: id },
      data: { status: 'completed' }
    });
    if (donation.userId) {
      await notifyUser(donation.userId, {
        type: 'donation_confirmed',
        message: `Your bank transfer donation of ${donation.amount} has been confirmed. Thank you.`,
        incidentId: null
      });
    }
    res.json({ message: 'Donation confirmed', donation: updated });
  } catch (error) {
    console.error('Confirm bank donation error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const rejectBankDonation = async (req, res) => {
  try {
    const { donationId } = req.params;
    const id = parseInt(donationId);
    const donation = await prisma.donation.findUnique({ where: { donationId: id } });
    if (!donation || donation.paymentMethod !== 'bank_transfer' || donation.status !== 'pending') {
      return res.status(400).json({ message: 'Invalid or non-pending bank donation' });
    }
    const updated = await prisma.donation.update({
      where: { donationId: id },
      data: { status: 'failed' }
    });
    if (donation.userId) {
      await notifyUser(donation.userId, {
        type: 'donation_rejected',
        message: 'Your bank transfer donation could not be verified. Contact support if you believe this is an error.',
        incidentId: null
      });
    }
    res.json({ message: 'Donation marked as failed', donation: updated });
  } catch (error) {
    console.error('Reject bank donation error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getVolunteerMissionRequests = async (req, res) => {
  try {
    const { status = 'pending' } = req.query;
    const where = {};
    if (status) where.status = status;

    const rows = await prisma.volunteerMissionRequest.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        volunteer: {
          select: { name: true, email: true, phone: true }
        },
        mission: {
          include: {
            incident: {
              include: { location: true }
            },
            organization: true
          }
        }
      }
    });
    res.json({ missionRequests: rows });
  } catch (error) {
    console.error('Get volunteer mission requests error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const approveVolunteerMissionRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const id = parseInt(requestId);

    const row = await prisma.volunteerMissionRequest.findUnique({
      where: { requestId: id },
      include: { mission: true }
    });
    if (!row || row.status !== 'pending') {
      return res.status(400).json({ message: 'Request not found or already resolved' });
    }

    const updated = await prisma.volunteerMissionRequest.update({
      where: { requestId: id },
      data: {
        status: 'approved',
        resolvedAt: new Date(),
        resolvedByUserId: req.user.userId
      }
    });

    await notifyUser(row.volunteerUserId, {
      type: 'mission_request_approved',
      message: `Your request to join mission #${row.missionId} was approved.`,
      incidentId: row.mission?.incidentId ?? null
    });

    res.json({ message: 'Request approved', missionRequest: updated });
  } catch (error) {
    console.error('Approve mission request error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const rejectVolunteerMissionRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const id = parseInt(requestId);

    const row = await prisma.volunteerMissionRequest.findUnique({
      where: { requestId: id },
      include: { mission: true }
    });
    if (!row || row.status !== 'pending') {
      return res.status(400).json({ message: 'Request not found or already resolved' });
    }

    const updated = await prisma.volunteerMissionRequest.update({
      where: { requestId: id },
      data: {
        status: 'rejected',
        resolvedAt: new Date(),
        resolvedByUserId: req.user.userId
      }
    });

    await notifyUser(row.volunteerUserId, {
      type: 'mission_request_rejected',
      message: `Your request to join mission #${row.missionId} was not approved.`,
      incidentId: row.mission?.incidentId ?? null
    });

    res.json({ message: 'Request rejected', missionRequest: updated });
  } catch (error) {
    console.error('Reject mission request error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getVolunteers = async (req, res) => {
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

    res.json({
      volunteers,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get volunteers error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getRescueTeams = async (req, res) => {
  try {
    const { page = 1, limit = 20, isActive } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (isActive !== undefined) where.isActive = isActive === 'true';

    const [organizations, total] = await Promise.all([
      prisma.organization.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { createdAt: 'desc' }
      }),
      prisma.organization.count({ where })
    ]);

    res.json({
      organizations,
      rescueTeams: organizations.map((o) => ({
        ...o,
        teamId: o.organizationId,
        teamName: o.organizationName
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get rescue teams error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getOrganizationDetails = async (req, res) => {
  try {
    const organizationId = parseInt(req.params.id, 10);
    if (Number.isNaN(organizationId)) {
      return res.status(400).json({ message: 'Invalid organization id' });
    }

    const organization = await prisma.organization.findUnique({
      where: { organizationId },
      include: {
        members: {
          orderBy: { createdAt: 'asc' },
          select: {
            userId: true,
            name: true,
            email: true,
            phone: true,
            responderStatus: true,
            role: { select: { roleName: true } }
          }
        },
        missions: {
          orderBy: { assignedAt: 'desc' },
          include: {
            incident: {
              include: {
                location: true,
                incidentUpdates: {
                  orderBy: { updatedAt: 'desc' },
                  include: {
                    user: { select: { name: true } }
                  }
                }
              }
            },
            user: { select: { name: true, email: true } }
          }
        }
      }
    });

    if (!organization) {
      return res.status(404).json({ message: 'Organization not found' });
    }

    return res.json({ organization });
  } catch (error) {
    console.error('Get organization details error:', error);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

export const getPendingResponderApprovals = async (req, res) => {
  try {
    const pendingResponders = await prisma.user.findMany({
      where: {
        responderStatus: 'pending',
        role: { roleName: { in: ['responder', 'rescue_team'] } }
      },
      orderBy: { createdAt: 'desc' },
      include: {
        role: { select: { roleName: true } },
        organization: true
      }
    });
    const pendingOrganizations = await prisma.organization.findMany({
      where: { approvalStatus: 'pending' },
      orderBy: { createdAt: 'desc' }
    });
    res.json({ pendingResponders, pendingOrganizations });
  } catch (error) {
    console.error('Get pending responder approvals error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const reviewResponderRegistration = async (req, res) => {
  try {
    const { id } = req.params;
    const { action } = req.body; // approve | reject
    if (!['approve', 'reject'].includes(action)) {
      return res.status(400).json({ message: 'Invalid action' });
    }
    const responder = await prisma.user.findUnique({
      where: { userId: parseInt(id, 10) },
      include: { role: true }
    });
    if (!responder) return res.status(404).json({ message: 'Responder not found' });
    if (!['responder', 'rescue_team'].includes(responder.role?.roleName)) {
      return res.status(400).json({ message: 'User is not a responder account' });
    }
    const updated = await prisma.user.update({
      where: { userId: responder.userId },
      data: { responderStatus: action === 'approve' ? 'approved' : 'rejected' }
    });
    await notifyUser(updated.userId, {
      incidentId: null,
      type: action === 'approve'
        ? 'responder_registration_approved'
        : 'responder_registration_rejected',
      message: action === 'approve'
        ? 'Your responder registration has been approved.'
        : 'Your responder registration was rejected. Contact support for details.'
    });
    res.json({
      message: action === 'approve'
        ? 'Responder approved successfully'
        : 'Responder rejected successfully',
      responder: updated
    });
  } catch (error) {
    console.error('Review responder registration error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const reviewOrganizationRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const { action } = req.body; // approve | reject
    if (!['approve', 'reject'].includes(action)) {
      return res.status(400).json({ message: 'Invalid action' });
    }
    const organization = await prisma.organization.findUnique({
      where: { organizationId: parseInt(id, 10) }
    });
    if (!organization) return res.status(404).json({ message: 'Organization not found' });

    const updated = await prisma.organization.update({
      where: { organizationId: organization.organizationId },
      data: {
        approvalStatus: action === 'approve' ? 'approved' : 'rejected',
        reviewedByUserId: req.user.userId,
        reviewedAt: new Date(),
        isActive: action === 'approve'
      }
    });

    const members = await prisma.user.findMany({
      where: { organizationId: updated.organizationId },
      select: { userId: true }
    });
    if (members.length > 0) {
      await prisma.notification.createMany({
        data: members.map((m) => ({
          userId: m.userId,
          incidentId: null,
          type: action === 'approve'
            ? 'organization_request_approved'
            : 'organization_request_rejected',
          message: action === 'approve'
            ? `Your organization "${updated.organizationName}" has been approved.`
            : `Your organization "${updated.organizationName}" was rejected by admin.`,
          isRead: false
        }))
      });
    }

    res.json({
      message: action === 'approve'
        ? 'Organization approved successfully'
        : 'Organization rejected successfully',
      organization: updated
    });
  } catch (error) {
    console.error('Review organization request error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

