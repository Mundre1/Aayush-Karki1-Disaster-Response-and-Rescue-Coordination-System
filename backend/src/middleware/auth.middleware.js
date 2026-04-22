import jwt from 'jsonwebtoken';

export const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ message: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

export const optionalAuthenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return next();
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (!err && user) {
      req.user = user;
    }
    next();
  });
};

export const requireRole = (...allowedRoles) => {
  return async (req, res, next) => {
    try {
      const { prisma } = await import('../config/prisma.js');
      const user = await prisma.user.findUnique({
        where: { userId: req.user.userId },
        include: { role: true }
      });

      if (!user || !allowedRoles.includes(user.role.roleName)) {
        return res.status(403).json({ message: 'Insufficient permissions' });
      }

      next();
    } catch (error) {
      console.error('Role check error:', error);
      res.status(500).json({ message: 'Internal server error' });
    }
  };
};

