import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../../config/prisma.js';
import { notifyAllAdmins } from '../../utils/notify.js';

const ALLOWED_REGISTRATION_ROLES = ['citizen', 'volunteer', 'responder', 'rescue_team'];

export const register = async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      phone,
      roleId,
      roleName,
      organizationId,
      rescueTeamId,
      organizationChoice,
      organizationName,
      organizationContact,
      organizationSpecialization
    } = req.body;

    let resolvedRoleId = null;

    if (roleName != null && String(roleName).trim() !== '') {
      // Prefer roleName: look up role by name
      let normalizedName = String(roleName).trim().toLowerCase();
      if (normalizedName === 'rescue_team') normalizedName = 'responder';
      if (!ALLOWED_REGISTRATION_ROLES.includes(normalizedName)) {
        return res.status(400).json({
          message: normalizedName === 'admin'
            ? 'Admin registration is not allowed. Please contact system administrator.'
            : 'Invalid role selected. Please choose a valid user type (citizen, volunteer, responder).',
        });
      }
      const role = await prisma.role.findUnique({
        where: { roleName: normalizedName },
      });
      if (!role) {
        return res.status(400).json({ message: 'Invalid role selected. Please choose a valid user type.' });
      }
      resolvedRoleId = role.roleId;
    } else if (roleId != null) {
      // Fallback: resolve by roleId and validate role name
      const role = await prisma.role.findUnique({
        where: { roleId: parseInt(roleId, 10) },
      });
      if (!role) {
        return res.status(400).json({ message: 'Invalid role selected. Please choose a valid user type.' });
      }
      const normalizedRoleName = role.roleName === 'rescue_team' ? 'responder' : role.roleName;
      if (role.roleName === 'admin' || !ALLOWED_REGISTRATION_ROLES.includes(normalizedRoleName)) {
        return res.status(403).json({
          message: 'Admin registration is not allowed. Please contact system administrator.',
        });
      }
      resolvedRoleId = role.roleId;
    } else {
      // Default to citizen by name
      const citizenRole = await prisma.role.findUnique({
        where: { roleName: 'citizen' },
      });
      if (!citizenRole) {
        return res.status(500).json({ message: 'Default role not configured. Please contact support.' });
      }
      resolvedRoleId = citizenRole.roleId;
    }

    // Check if user exists
    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Validate password strength
    if (!password || password.length < 6) {
      return res.status(400).json({
        message: 'Password must be at least 6 characters long',
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    const resolvedRole = await prisma.role.findUnique({
      where: { roleId: resolvedRoleId },
      select: { roleName: true }
    });
    const effectiveRoleName = resolvedRole?.roleName === 'rescue_team'
      ? 'responder'
      : resolvedRole?.roleName;
    const requestedOrganizationId = organizationId ?? rescueTeamId;
    let resolvedOrganizationId = requestedOrganizationId
      ? parseInt(requestedOrganizationId, 10)
      : null;
    let responderStatus = 'approved';
    let createdOrganization = null;

    let pendingOrganizationPayload = null;
    if (effectiveRoleName === 'responder') {
      responderStatus = 'pending';
      if (organizationChoice === 'new') {
        if (!organizationName || String(organizationName).trim().isEmpty) {
          return res.status(400).json({
            message: 'Organization name is required when creating a new organization.'
          });
        }
        pendingOrganizationPayload = {
          organizationName: String(organizationName).trim(),
          contact: organizationContact || null,
          specialization: organizationSpecialization || null,
          approvalStatus: 'pending'
        };
      } else {
        if (!resolvedOrganizationId) {
          return res.status(400).json({
            message: 'Please select an existing organization.'
          });
        }
        const existingOrganization = await prisma.organization.findUnique({
          where: { organizationId: resolvedOrganizationId }
        });
        if (!existingOrganization) {
          return res.status(404).json({ message: 'Selected organization not found.' });
        }
      }
    }

    // Create responder and (if requested) pending organization atomically.
    const user = await prisma.$transaction(async (tx) => {
      let orgIdForUser = resolvedOrganizationId;
      if (pendingOrganizationPayload) {
        const provisionalUser = await tx.user.create({
          data: {
            name,
            email,
            password: hashedPassword,
            phone,
            roleId: resolvedRoleId,
            organizationId: null,
            responderStatus,
          },
          select: { userId: true }
        });
        createdOrganization = await tx.organization.create({
          data: {
            ...pendingOrganizationPayload,
            requestedByUserId: provisionalUser.userId
          }
        });
        orgIdForUser = createdOrganization.organizationId;
        return tx.user.update({
          where: { userId: provisionalUser.userId },
          data: { organizationId: orgIdForUser },
          select: {
            userId: true,
            name: true,
            email: true,
            phone: true,
            roleId: true,
            role: {
              select: {
                roleName: true
              }
            },
            organizationId: true,
            responderStatus: true,
            createdAt: true
          }
        });
      }

      return tx.user.create({
        data: {
          name,
          email,
          password: hashedPassword,
          phone,
          roleId: resolvedRoleId,
          organizationId: orgIdForUser,
          responderStatus,
        },
        select: {
          userId: true,
          name: true,
          email: true,
          phone: true,
          roleId: true,
          role: {
            select: {
              roleName: true
            }
          },
          organizationId: true,
          responderStatus: true,
          createdAt: true
        }
      });
    });

    if (effectiveRoleName === 'responder') {
      await notifyAllAdmins({
        incidentId: null,
        type: createdOrganization ? 'organization_request' : 'responder_registration_request',
        message: createdOrganization
          ? `${user.name} requested new organization "${createdOrganization.organizationName}" and responder registration approval.`
          : `${user.name} requested responder registration approval.`
      });
    }

    res.status(201).json({
      message: effectiveRoleName === 'responder'
        ? 'Responder registration submitted. Waiting for admin approval.'
        : 'User registered successfully',
      user
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = await prisma.user.findUnique({
      where: { email },
      include: { role: true }
    });

    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    if (
      (user.role?.roleName === 'responder' || user.role?.roleName === 'rescue_team') &&
      user.responderStatus !== 'approved'
    ) {
      return res.status(403).json({
        message: `Responder account is ${user.responderStatus}. Please wait for admin approval.`
      });
    }

    if (
      (user.role?.roleName === 'responder' || user.role?.roleName === 'rescue_team') &&
      user.organizationId
    ) {
      const organization = await prisma.organization.findUnique({
        where: { organizationId: user.organizationId },
        select: { approvalStatus: true }
      });
      if (organization && organization.approvalStatus !== 'approved') {
        return res.status(403).json({
          message: `Organization is ${organization.approvalStatus}. Please wait for admin approval.`
        });
      }
    }


    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password);

    if (!isValidPassword) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate JWT
    const token = jwt.sign(
      {
        userId: user.userId,
        email: user.email,
        roleId: user.roleId,
        organizationId: user.organizationId,
        rescueTeamId: user.organizationId
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        userId: user.userId,
        name: user.name,
        email: user.email,
        phone: user.phone,
        roleId: user.roleId,
        roleName: user.role.roleName === 'rescue_team' ? 'responder' : user.role.roleName,
        organizationId: user.organizationId,
        rescueTeamId: user.organizationId,
        responderStatus: user.responderStatus
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getAvailableOrganizations = async (req, res) => {
  try {
    const organizations = await prisma.organization.findMany({
      where: {
        isActive: true,
        approvalStatus: 'approved'
      },
      orderBy: { organizationName: 'asc' },
      select: {
        organizationId: true,
        organizationName: true,
        specialization: true,
        contact: true
      }
    });
    res.json({ organizations });
  } catch (error) {
    console.error('Get available organizations error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getProfile = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { userId: req.user.userId },
      select: {
        userId: true,
        name: true,
        email: true,
        phone: true,
        roleId: true,
        role: {
          select: {
            roleName: true
          }
        },
        createdAt: true
      }
    });

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ user });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateProfile = async (req, res) => {
  try {
    const { name, phone } = req.body;

    const data = {};
    if (name !== undefined) data.name = name;
    if (phone !== undefined) data.phone = phone === '' || phone === null ? null : phone;

    const user = await prisma.user.update({
      where: { userId: req.user.userId },
      data,
      select: {
        userId: true,
        name: true,
        email: true,
        phone: true,
        roleId: true,
        updatedAt: true
      }
    });

    res.json({
      message: 'Profile updated successfully',
      user
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

