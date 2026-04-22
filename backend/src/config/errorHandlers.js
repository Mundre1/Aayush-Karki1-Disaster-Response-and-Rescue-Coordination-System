export function setupErrorHandlers(app) {
  // Global error handler
  app.use((err, req, res, next) => {
    const timestamp = new Date().toISOString();
    console.error(`❌ [${timestamp}] Server Error:`, {
      message: err.message,
      stack: err.stack,
      url: req.url,
      method: req.method,
      ip: req.ip,
      userAgent: req.get('User-Agent')
    });

    const statusCode = err.status || err.statusCode || 500;
    const message = err.message || 'Internal Server Error';

    // Don't leak error details in production
    const isDevelopment = process.env.NODE_ENV === 'development';

    res.status(statusCode).json({
      success: false,
      message,
      ...(isDevelopment && {
        stack: err.stack,
        details: err,
        timestamp
      })
    });
  });

  // 404 handler - must be last
  app.use((req, res) => {
    const timestamp = new Date().toISOString();
    console.warn(`🚫 [${timestamp}] 404 Not Found: ${req.method} ${req.path}`);

    res.status(404).json({
      success: false,
      message: 'Route not found',
      path: req.path,
      method: req.method,
      timestamp
    });
  });

  // Handle unhandled promise rejections
  process.on('unhandledRejection', (reason, promise) => {
    console.error('🚨 Unhandled Rejection at:', promise, 'reason:', reason);
    // Don't exit the process in production, just log
    if (process.env.NODE_ENV === 'development') {
      process.exit(1);
    }
  });

  // Handle uncaught exceptions
  process.on('uncaughtException', (error) => {
    console.error('💥 Uncaught Exception:', error);
    // Don't exit the process in production, just log
    if (process.env.NODE_ENV === 'development') {
      process.exit(1);
    }
  });

  console.log('🛡️ Error handlers configured successfully');
}
