export async function setupRoutesImproved(app, io) {
  const routes = [
    { path: '../features/auth/auth.routes.js', mountPath: '/api/auth', name: 'auth' },
    // Special handling for routes that need io instance
    { type: 'function', setup: async () => {
        const { setupIncidentRoutes } = await import('../features/incidents/incident.routes.js');
        return setupIncidentRoutes(io);
      }, mountPath: '/api/incidents', name: 'incidents' },
    { type: 'function', setup: async () => {
        const { setupAdminRoutes } = await import('../features/admin/admin.routes.improved.js');
        return setupAdminRoutes(io);
      }, mountPath: '/api/admin', name: 'admin' },
    { type: 'function', setup: async () => {
        const { setupRescueTeamRoutes } = await import('../features/rescue-teams/rescue-team.routes.improved.js');
        return setupRescueTeamRoutes(io);
      }, mountPath: '/api/rescue-teams', name: 'rescue-teams' },
    { type: 'function', setup: async () => {
        const { setupVolunteerRoutes } = await import('../features/volunteers/volunteer.routes.improved.js');
        return setupVolunteerRoutes(io);
      }, mountPath: '/api/volunteers', name: 'volunteers' },
    { type: 'function', setup: async () => {
        const { setupNotificationRoutes } = await import('../features/notifications/notification.routes.improved.js');
        return setupNotificationRoutes(io);
      }, mountPath: '/api/notifications', name: 'notifications' },
    { type: 'function', setup: async () => {
        const { setupDonationRoutes } = await import('../features/donations/donation.routes.improved.js');
        return setupDonationRoutes(io);
      }, mountPath: '/api/donations', name: 'donations' },
  ];

  const loadedRoutes = [];

  for (const route of routes) {
    try {
      console.log(`🔄 Loading ${route.name} routes...`);

      if (route.type === 'function') {
        // Handle function-based routes (like incidents that need io)
        const routeHandler = await route.setup();
        app.use(route.mountPath, routeHandler);
      } else {
        // Handle regular module-based routes
        const routeModule = await import(route.path);
        app.use(route.mountPath, routeModule.default);
      }

      loadedRoutes.push(route.name);
      console.log(`📍 Route ${route.mountPath} registered`);
    } catch (error) {
      console.error(`❌ Failed to load ${route.name} routes:`, error.message);
      console.error('Stack:', error.stack);
      // Continue loading other routes even if one fails
    }
  }

  // Health check endpoint
  app.get('/api/health', (req, res) => {
    res.json({
      status: 'ok',
      message: 'Disaster Response API is running with improved features',
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development',
      loadedRoutes,
      improvements: [
        'Generic base controller implementation',
        'Consistent response handling',
        'Enhanced error handling',
        'Improved validation',
        'Better separation of concerns'
      ]
    });
  });

  console.log(`✅ ${loadedRoutes.length} route modules loaded successfully with improvements`);
  return loadedRoutes;
}