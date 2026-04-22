import cors from 'cors';
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const uploadsDir = path.join(__dirname, '../../uploads');

export function setupMiddleware(app) {
  // CORS configuration
  app.use(cors({
    origin: process.env.FRONTEND_URL || "*",
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
  }));

  // Body parsing middleware with increased limits for file uploads
  app.use(express.json({
    limit: '10mb',
    verify: (req, res, buf) => {
      // Store raw body for webhook verification if needed
      req.rawBody = buf;
    }
  }));

  app.use(express.urlencoded({
    extended: true,
    limit: '10mb'
  }));

  // Serve uploaded incident images
  app.use('/uploads', express.static(uploadsDir));

  // Security headers
  app.use((req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    next();
  });

  // Request logging middleware (development only)
  if (process.env.NODE_ENV === 'development') {
    app.use((req, res, next) => {
      const timestamp = new Date().toISOString();
      console.log(`📨 ${timestamp} - ${req.method} ${req.path}`);
      next();
    });
  }

  console.log('🛡️ Middleware configured successfully');
}
