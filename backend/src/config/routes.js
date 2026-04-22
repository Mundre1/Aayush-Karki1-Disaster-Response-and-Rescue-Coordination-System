export async function setupRoutes(app, io) {
  const routes = [
    { path: '../features/auth/auth.routes.js', mountPath: '/api/auth', name: 'auth' },
    // Special handling for routes that need io instance
    { type: 'function', setup: async () => {
        const { setupIncidentRoutes } = await import('../features/incidents/incident.routes.js');
        return setupIncidentRoutes(io);
      }, mountPath: '/api/incidents', name: 'incidents' },
    { type: 'function', setup: async () => {
        const { setupAdminRoutes } = await import('../features/admin/admin.routes.js');
        return setupAdminRoutes(io);
      }, mountPath: '/api/admin', name: 'admin' },
    { type: 'function', setup: async () => {
        const { setupRescueTeamRoutes } = await import('../features/rescue-teams/rescue-team.routes.js');
        return setupRescueTeamRoutes(io);
      }, mountPath: '/api/rescue-teams', name: 'rescue-teams' },
    { path: '../features/volunteers/volunteer.routes.js', mountPath: '/api/volunteers', name: 'volunteers' },
    { path: '../features/notifications/notification.routes.js', mountPath: '/api/notifications', name: 'notifications' },
    { path: '../features/donations/donation.routes.js', mountPath: '/api/donations', name: 'donations' },
    { path: '../features/campaigns/campaign.routes.js', mountPath: '/api/campaigns', name: 'campaigns' },
    { type: 'function', setup: async () => {
        const { setupCommentRoutes } = await import('../features/comments/comment.routes.js');
        return setupCommentRoutes(io);
      }, mountPath: '/api/comments', name: 'comments' },
  ];

  const loadedRoutes = [];

  for (const route of routes) {
    try {
      console.log(`🔄 Loading ${route.name} routes...`);

      if (route.type === 'function') {
        // Handle function-based routes (like incidents that need io)
        const routeHandler = await route.setup();
        app.use(route.mountPath, routeHandler);
        if (route.name === 'rescue-teams') {
          // Transitional alias for renamed responder endpoints
          app.use('/api/responders', routeHandler);
        }
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
      message: 'Disaster Response API is running',
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development',
      loadedRoutes
    });
  });

  console.log(`✅ ${loadedRoutes.length} route modules loaded successfully`);
  return loadedRoutes;
}
