import { prisma } from '../../config/prisma.js';
import { notifyAllAdmins, notifyUser } from '../../utils/notify.js';

export const registerAsVolunteer = async (req, res) => {
  try {
    const { skills, availability } = req.body;

    const existing = await prisma.volunteer.findUnique({
      where: { userId: req.user.userId }
    });

    if (existing) {
      return res.status(400).json({ message: 'Already registered as volunteer' });
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

    res.status(201).json({
      message: 'Volunteer registration successful. Waiting for approval.',
      volunteer
    });
  } catch (error) {
    console.error('Register volunteer error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getMyVolunteerProfile = async (req, res) => {
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
      return res.status(404).json({ message: 'Volunteer profile not found' });
    }

    res.json({ volunteer });
  } catch (error) {
    console.error('Get volunteer profile error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getMyMissionRequests = async (req, res) => {
  try {
    const rows = await prisma.volunteerMissionRequest.findMany({
      where: { volunteerUserId: req.user.userId },
      orderBy: { createdAt: 'desc' },
      include: {
        mission: {
          include: {
            incident: {
              include: {
                location: true
              }
            },
            organization: true
          }
        }
      }
    });

    res.json({
      missionRequests: rows.map((row) => ({
        ...row,
        mission: row.mission
          ? {
              ...row.mission,
              rescueTeamId: row.mission.organizationId,
              rescueTeam: row.mission.organization
            }
          : row.mission
      }))
    });
  } catch (error) {
    console.error('Get my mission requests error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const requestToJoinMission = async (req, res) => {
  try {
    const { id } = req.params;

    const volunteer = await prisma.volunteer.findUnique({
      where: { userId: req.user.userId },
      include: {
        user: {
          select: { name: true, email: true }
        }
      }
    });

    if (!volunteer || !volunteer.isApproved) {
      return res.status(403).json({ message: 'Volunteer not approved' });
    }

    const mission = await prisma.mission.findUnique({
      where: { missionId: parseInt(id) },
      include: {
        incident: true
      }
    });

    if (!mission) {
      return res.status(404).json({ message: 'Mission not found' });
    }

    const existing = await prisma.volunteerMissionRequest.findUnique({
      where: {
        missionId_volunteerUserId: {
          missionId: mission.missionId,
          volunteerUserId: req.user.userId
        }
      }
    });

    if (existing) {
      if (existing.status === 'rejected') {
        return res.status(400).json({
          message: 'You cannot request this mission again (previously rejected)'
        });
      }
      if (existing.status === 'approved') {
        return res.status(400).json({ message: 'Already approved for this mission' });
      }
      return res.status(400).json({ message: 'Request already pending' });
    }

    const requestRow = await prisma.volunteerMissionRequest.create({
      data: {
        missionId: mission.missionId,
        volunteerUserId: req.user.userId,
        status: 'pending'
      }
    });

    const volunteerName = volunteer.user?.name || volunteer.user?.email || `User ${req.user.userId}`;
    await notifyAllAdmins({
      incidentId: mission.incidentId,
      type: 'volunteer_mission_request',
      message: `${volunteerName} requested to join mission #${mission.missionId} (${mission.incident?.title || 'incident'})`
    });

    res.json({
      message: 'Request to join mission submitted',
      missionRequest: requestRow
    });
  } catch (error) {
    console.error('Request to join mission error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateAvailability = async (req, res) => {
  try {
    const { availability } = req.body;

    const volunteer = await prisma.volunteer.update({
      where: { userId: req.user.userId },
      data: { availability }
    });

    res.json({
      message: 'Availability updated',
      volunteer
    });
  } catch (error) {
    console.error('Update availability error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
