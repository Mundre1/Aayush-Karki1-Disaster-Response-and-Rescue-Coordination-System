import { prisma } from '../../config/prisma.js';
import { notifyAllAdmins } from '../../utils/notify.js';

const toAbsoluteImageUrl = (req, imageUrl) => {
  if (!imageUrl) return imageUrl;
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl;
  }
  const normalizedPath = imageUrl.startsWith('/') ? imageUrl : `/${imageUrl}`;
  return `${req.protocol}://${req.get('host')}${normalizedPath}`;
};

const withResolvedImageUrl = (req, incident) => ({
  ...incident,
  imageUrl: toAbsoluteImageUrl(req, incident.imageUrl),
  incidentUpdates: (incident.incidentUpdates || []).map((update) => ({
    ...update,
    imageUrl: toAbsoluteImageUrl(req, update.imageUrl)
  }))
});

const withMissionAliases = (incident) => ({
  ...incident,
  missions: (incident.missions || []).map((mission) => ({
    ...mission,
    rescueTeamId: mission.organizationId,
    rescueTeam: mission.organization
  }))
});

const toClientIncident = (req, incident) =>
  withMissionAliases(withResolvedImageUrl(req, incident));

export const createIncident = async (req, res) => {
  try {
    const { title, description, severity, latitude, longitude, address, district, imageUrl: imageUrlInput } = req.body;
    const normalizedImageUrl = typeof imageUrlInput === 'string' ? imageUrlInput.trim() : '';
    const imageUrl = req.file
      ? `/uploads/${req.file.filename}`
      : (normalizedImageUrl || null);

    // Create location
    const location = await prisma.location.create({
      data: {
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        address,
        district
      }
    });

    // Create incident
    const incident = await prisma.incident.create({
      data: {
        userId: req.user.userId,
        locationId: location.locationId,
        title,
        description,
        severity: severity || 'medium',
        imageUrl,
        status: 'pending'
      },
      include: {
        user: {
          select: {
            name: true,
            email: true,
            phone: true
          }
        },
        location: true
      }
    });

    // Socket event will be emitted from the route handler

    await notifyAllAdmins({
      incidentId: incident.incidentId,
      type: 'incident_reported',
      message: `New incident reported: ${incident.title}`
    });

    // Store incident data for socket emission
    res.locals.incident = incident;

    const incidentWithImageUrl = toClientIncident(req, incident);

    res.status(201).json({
      message: 'Incident reported successfully',
      incident: incidentWithImageUrl
    });
  } catch (error) {
    console.error('Create incident error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getIncidents = async (req, res) => {
  try {
    const { status, severity, page = 1, limit = 20 } = req.query;
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
          }
        }
      }),
      prisma.incident.count({ where })
    ]);

    res.json({
      incidents: incidents.map((incident) => toClientIncident(req, incident)),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get incidents error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getIncidentById = async (req, res) => {
  try {
    const { id } = req.params;

    const incident = await prisma.incident.findUnique({
      where: { incidentId: parseInt(id) },
      include: {
        user: {
          select: {
            name: true,
            email: true,
            phone: true
          }
        },
        location: true,
        incidentUpdates: {
          orderBy: { updatedAt: 'desc' },
          include: {
            user: {
              select: {
                name: true
              }
            }
          }
        },
        missions: {
          include: {
            organization: true,
            user: {
              select: {
                name: true
              }
            }
          }
        }
      }
    });

    if (!incident) {
      return res.status(404).json({ message: 'Incident not found' });
    }

    res.json({ incident: toClientIncident(req, incident) });
  } catch (error) {
    console.error('Get incident by id error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getMyIncidents = async (req, res) => {
  try {
    const incidents = await prisma.incident.findMany({
      where: { userId: req.user.userId },
      orderBy: { reportedAt: 'desc' },
      include: {
        location: true,
        incidentUpdates: {
          orderBy: { updatedAt: 'desc' },
          take: 20,
          include: {
            user: {
              select: { name: true }
            }
          }
        },
        missions: {
          include: {
            organization: true
          }
        }
      }
    });

    res.json({
      incidents: incidents.map((incident) => toClientIncident(req, incident))
    });
  } catch (error) {
    console.error('Get my incidents error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateIncidentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, note } = req.body;

    const actor = await prisma.user.findUnique({
      where: { userId: req.user.userId },
      include: { role: true }
    });

    if (!actor?.role) {
      return res.status(403).json({ message: 'Insufficient permissions' });
    }

    const roleName = actor.role.roleName;
    if (!['admin', 'responder', 'rescue_team'].includes(roleName)) {
      return res.status(403).json({
        message: 'Only administrators and responders can change incident status'
      });
    }

    const incident = await prisma.incident.update({
      where: { incidentId: parseInt(id) },
      data: { status }
    });

    await prisma.incidentUpdate.create({
      data: {
        incidentId: parseInt(id),
        userId: req.user.userId,
        status,
        note: note?.trim() || `Status set to ${status}`
      }
    });

    if (req.io) {
      req.io.emit('incident_updated', { incidentId: parseInt(id), status });
    }

    res.json({
      message: 'Incident status updated',
      incident
    });
  } catch (error) {
    console.error('Update incident status error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateIncident = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, severity, latitude, longitude, address, district, imageUrl: imageUrlInput } = req.body;
    const normalizedImageUrl = typeof imageUrlInput === 'string' ? imageUrlInput.trim() : '';
    const imageUrl = req.file
      ? `/uploads/${req.file.filename}`
      : (normalizedImageUrl || undefined);

    // Check if incident exists and belongs to user
    const existingIncident = await prisma.incident.findUnique({
      where: { incidentId: parseInt(id) }
    });

    if (!existingIncident) {
      return res.status(404).json({ message: 'Incident not found' });
    }

    if (existingIncident.userId !== req.user.userId) {
      return res.status(403).json({ message: 'You can only update your own incidents' });
    }

    // Update location if provided
    let locationData = {};
    if (latitude !== undefined && longitude !== undefined) {
      locationData = {
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        address,
        district
      };
    } else if (address !== undefined || district !== undefined) {
      locationData = {
        ...(address !== undefined && { address }),
        ...(district !== undefined && { district })
      };
    }

    if (Object.keys(locationData).length > 0) {
      await prisma.location.update({
        where: { locationId: existingIncident.locationId },
        data: locationData
      });
    }

    // Update incident
    const updateData = {
      title,
      description,
      severity: severity || existingIncident.severity,
      ...(imageUrl && { imageUrl })
    };

    const incident = await prisma.incident.update({
      where: { incidentId: parseInt(id) },
      data: updateData,
      include: {
        user: {
          select: {
            name: true,
            email: true,
            phone: true
          }
        },
        location: true
      }
    });

    const incidentWithImageUrl = toClientIncident(req, incident);

    res.json({
      message: 'Incident updated successfully',
      incident: incidentWithImageUrl
    });
  } catch (error) {
    console.error('Update incident error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const deleteIncident = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if incident exists and belongs to user
    const incident = await prisma.incident.findUnique({
      where: { incidentId: parseInt(id) }
    });

    if (!incident) {
      return res.status(404).json({ message: 'Incident not found' });
    }

    if (incident.userId !== req.user.userId) {
      return res.status(403).json({ message: 'You can only delete your own incidents' });
    }

    // Delete incident (cascade will handle related records)
    await prisma.incident.delete({
      where: { incidentId: parseInt(id) }
    });

    res.json({ message: 'Incident deleted successfully' });
  } catch (error) {
    console.error('Delete incident error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

