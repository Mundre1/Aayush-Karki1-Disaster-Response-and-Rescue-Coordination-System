import { prisma } from '../config/prisma.js';

export async function getAdminUsers() {
  const adminRole = await prisma.role.findUnique({
    where: { roleName: 'admin' }
  });
  if (!adminRole) return [];
  return prisma.user.findMany({
    where: { roleId: adminRole.roleId },
    select: { userId: true }
  });
}

export async function notifyAllAdmins({ incidentId, type, message }) {
  const admins = await getAdminUsers();
  if (admins.length === 0) return;
  await prisma.notification.createMany({
    data: admins.map((a) => ({
      userId: a.userId,
      incidentId: incidentId ?? null,
      type,
      message,
      isRead: false
    }))
  });
}

export async function notifyUser(userId, { incidentId, type, message }) {
  if (!userId) return;
  await prisma.notification.create({
    data: {
      userId,
      incidentId: incidentId ?? null,
      type,
      message,
      isRead: false
    }
  });
}
export async function notifyOrganization(organizationId, { incidentId, type, message }) {
  if (!organizationId) return;
  const members = await prisma.user.findMany({
    where: { organizationId },
    select: { userId: true }
  });
  if (members.length === 0) return;
  await prisma.notification.createMany({
    data: members.map((m) => ({
      userId: m.userId,
      incidentId: incidentId ?? null,
      type,
      message,
      isRead: false
    }))
  });
}

// Backward compatibility alias during migration
export const notifyRescueTeam = notifyOrganization;
