import { prisma } from '../../config/prisma.js';
import { notifyAllAdmins } from '../../utils/notify.js';

async function ensureApprovedResponder(userId) {
  const user = await prisma.user.findUnique({
    where: { userId },
    include: { role: true, organization: true }
  });
  const roleName = user?.role?.roleName;
  const isResponderRole = ['responder', 'rescue_team'].includes(roleName);
  if (!isResponderRole) {
    return { ok: false, message: 'Only responders can perform this action.' };
  }
  if (user?.responderStatus !== 'approved') {
    return {
      ok: false,
      message: `Responder account is ${user?.responderStatus ?? 'pending'}.`
    };
  }
  if (user.organization && user.organization.approvalStatus !== 'approved') {
    return {
      ok: false,
      message: `Organization is ${user.organization.approvalStatus}.`
    };
  }
  return { ok: true, user };
}

export const getMyMissions = async (req, res) => {
  try {
    const { userId } = req.user;
    const approvedCheck = await ensureApprovedResponder(userId);
    if (!approvedCheck.ok) {
      return res.status(403).json({ message: approvedCheck.message, missions: [] });
    }

    // Do not rely only on JWT payload for organizationId because it can be stale/null.
    const dbUser = await prisma.user.findUnique({
      where: { userId },
      select: { organizationId: true }
    });
    const resolvedOrganizationId =
      dbUser?.organizationId ??
      req.user.organizationId ??
      req.user.rescueTeamId ??
      null;

    // Build OR conditions dynamically
    const orConditions = [{ userId }];
    if (resolvedOrganizationId) {
      orConditions.push({ organizationId: resolvedOrganizationId });
    }

    const missions = await prisma.mission.findMany({
      where: {
        OR: orConditions
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
        organization: true
      },
      orderBy: { assignedAt: 'desc' }
    });

    // Backward-compatible aliasing while clients transition
    const missionsWithAliases = missions.map((mission) => ({
      ...mission,
      rescueTeamId: mission.organizationId,
      rescueTeam: mission.organization
    }));

    res.json({ missions: missionsWithAliases });
  } catch (error) {
    console.error('Get my missions error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateMissionStatus = async (req, res) => {
  try {
    const approvedCheck = await ensureApprovedResponder(req.user.userId);
    if (!approvedCheck.ok) {
      return res.status(403).json({ message: approvedCheck.message });
    }

    const { id } = req.params;
    const { missionStatus, note, imageUrl: imageUrlInput } = req.body;
    const normalizedImageUrl = typeof imageUrlInput === 'string'
      ? imageUrlInput.trim()
      : '';
    const updateImageUrl = req.file
      ? `/uploads/${req.file.filename}`
      : (normalizedImageUrl || null);

    const mission = await prisma.mission.update({
      where: { missionId: parseInt(id) },
      data: { missionStatus },
      include: {
        incident: true,
        organization: true
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

    // Create incident history update for mission progress.
    await prisma.incidentUpdate.create({
      data: {
        incidentId: mission.incidentId,
        userId: req.user.userId,
        status: missionStatus,
        note: (typeof note === 'string' && note.trim().length > 0)
          ? note.trim()
          : `Mission updated to ${missionStatus}`,
        imageUrl: updateImageUrl || undefined
      }
    });

    // Store mission data for socket emission
    res.locals.missionUpdate = { missionId: parseInt(id), missionStatus };

    res.json({
      message: 'Mission status updated',
      mission: {
        ...mission,
        rescueTeamId: mission.organizationId,
        rescueTeam: mission.organization
      }
    });
  } catch (error) {
    console.error('Update mission status error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateLocation = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;

    // Store location data for socket emission
    res.locals.locationUpdate = {
      userId: req.user.userId,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      timestamp: new Date()
    };

    res.json({ message: 'Location updated' });
  } catch (error) {
    console.error('Update location error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getOrganizationMembers = async (req, res) => {
  try {
    const approvedCheck = await ensureApprovedResponder(req.user.userId);
    if (!approvedCheck.ok) {
      return res.status(403).json({ message: approvedCheck.message, members: [] });
    }
    const organizationId = approvedCheck.user.organizationId;
    if (!organizationId) {
      return res.status(400).json({ message: 'Responder is not linked to an organization.', members: [] });
    }

    const members = await prisma.user.findMany({
      where: { organizationId },
      orderBy: { createdAt: 'asc' },
      select: {
        userId: true,
        name: true,
        email: true,
        phone: true,
        responderStatus: true,
        role: { select: { roleName: true } }
      }
    });

    return res.json({
      organization: {
        organizationId: approvedCheck.user.organization?.organizationId,
        organizationName: approvedCheck.user.organization?.organizationName
      },
      members
    });
  } catch (error) {
    console.error('Get organization members error:', error);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

export const requestMissionAssignment = async (req, res) => {
  try {
    const missionId = parseInt(req.params.id, 10);
    const userId = req.user.userId;
    const approvedCheck = await ensureApprovedResponder(userId);
    if (!approvedCheck.ok) {
      return res.status(403).json({ message: approvedCheck.message });
    }
    if (Number.isNaN(missionId)) {
      return res.status(400).json({ message: 'Invalid mission id' });
    }

    const [mission, user] = await Promise.all([
      prisma.mission.findUnique({
        where: { missionId },
        include: { incident: true }
      }),
      prisma.user.findUnique({
        where: { userId },
        select: { name: true, email: true, organizationId: true }
      })
    ]);

    if (!mission) {
      return res.status(404).json({ message: 'Mission not found' });
    }

    if (!user?.organizationId) {
      return res.status(400).json({
        message: 'Responder account must be linked to an organization.'
      });
    }

    if (mission.userId === userId || mission.organizationId === user.organizationId) {
      return res.status(400).json({
        message: 'This mission is already assigned to you or your organization.'
      });
    }

    const actor = user.name || user.email || `User ${userId}`;
    await notifyAllAdmins({
      incidentId: mission.incidentId,
      type: 'responder_mission_request',
      message: `${actor} requested to join mission #${missionId} (${mission.incident?.title || 'incident'})`
    });

    return res.json({
      message: 'Request sent to administrators. You will be notified once reviewed.'
    });
  } catch (error) {
    console.error('Request mission assignment error:', error);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

