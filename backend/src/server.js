import dotenv from 'dotenv';
import { createServer } from 'http';
import express from 'express';

// Import configuration modules
import { setupMiddleware } from './config/middleware.js';
import { setupRoutes } from './config/routes.js';
import { createSocketServer, setupSocketHandlers } from './config/socket.js';
import { setupErrorHandlers } from './config/errorHandlers.js';

// Load environment variables
dotenv.config();

// Graceful shutdown handling
let serverStarted = false;
let globalIo = null;

const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

// Initialize application and start server
async function initializeApp() {
  try {
    console.log('🚀 Initializing Disaster Response API...');

    // Initialize Express app
    const app = express();

    // Setup middleware
    setupMiddleware(app);

    // Create HTTP server
    const httpServer = createServer(app);

    // Create and configure Socket.IO server
    const io = createSocketServer(httpServer);
    setupSocketHandlers(io);
    globalIo = io; // Store for export

    // Setup routes (async operation)
    const loadedRoutes = await setupRoutes(app, io);

    // Setup error handlers (must be last)
    setupErrorHandlers(app);

    // Start server
    return new Promise((resolve, reject) => {
      // Handle server errors
      httpServer.on('error', (error) => {
        if (error.code === 'EADDRINUSE') {
          console.error(`\n❌ Port ${PORT} is already in use!`);
          console.error('💡 Solutions:');
          console.error('   1. Kill the process using port 3000:');
          console.error('      Windows: netstat -ano | findstr :3000');
          console.error('      Then: taskkill /PID <PID> /F');
          console.error('   2. Or change PORT in .env file');
          console.error(`\n🔍 Current process on port ${PORT}:`);
          console.error('   Run: netstat -ano | findstr :3000\n');
        } else {
          console.error('❌ Server start error:', error.message);
        }
        reject(error);
      });

      httpServer.listen(PORT, () => {
        serverStarted = true;
        console.log('✅ Application initialized successfully');
        console.log(`🚀 Server running on port ${PORT}`);
        console.log(`🌍 Environment: ${NODE_ENV}`);
        console.log(`🔌 Socket.IO enabled for real-time communication`);
        console.log(`📡 Health check: http://localhost:${PORT}/api/health`);
        console.log(`📦 Routes loaded: ${loadedRoutes.length}`);

        // Log available routes in development
        if (NODE_ENV === 'development') {
          console.log('📋 Available routes:');
          loadedRoutes.forEach(route => {
            console.log(`  • /api/${route}`);
          });
        }

        resolve({ app, httpServer, io });
      });
    });

  } catch (error) {
    console.error('❌ Application initialization failed:', error);
    process.exit(1);
  }
}

// Start the application
initializeApp().then(({ httpServer }) => {
  // Graceful shutdown
  process.on('SIGTERM', () => {
    console.log('🛑 SIGTERM received, shutting down gracefully');

    httpServer.close(() => {
      console.log('✅ Server closed successfully');
      serverStarted = false;
      process.exit(0);
    });

    // Force close after 10 seconds
    setTimeout(() => {
      console.log('⚠️ Forcing shutdown after timeout');
      process.exit(1);
    }, 10000);
  });

  process.on('SIGINT', () => {
    console.log('🛑 SIGINT received, shutting down gracefully');
    process.exit(0);
  });
}).catch((error) => {
  console.error('❌ Failed to start application:', error);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('🚨 Unhandled Rejection at:', promise, 'reason:', reason);
  if (NODE_ENV === 'development') {
    process.exit(1);
  }
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('💥 Uncaught Exception:', error);
  if (NODE_ENV === 'development') {
    process.exit(1);
  }
});

// Export io for use in other modules (will be available after initialization)
export { globalIo as io };

