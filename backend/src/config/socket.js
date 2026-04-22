import { Server as SocketIOServer } from 'socket.io';

export function createSocketServer(httpServer) {
  const io = new SocketIOServer(httpServer, {
    cors: {
      origin: process.env.FRONTEND_URL || "*",
      methods: ["GET", "POST"],
      credentials: true
    },
    // Socket.IO configuration
    pingTimeout: 60000,
    pingInterval: 25000,
    maxHttpBufferSize: 1e8, // 100MB for file uploads
    allowEIO3: true, // Allow Engine.IO v3 clients
  });

  console.log('🔌 Socket.IO server configured');

  return io;
}

export function setupSocketHandlers(io) {
  io.on('connection', (socket) => {
    console.log(`🔌 Client connected: ${socket.id}`);

    // Room management
    handleRoomJoining(socket, io);

    // Real-time event handlers
    handleLocationUpdates(socket, io);
    handleMissionUpdates(socket, io);
    handleVolunteerRequests(socket, io);
    handleDonationUpdates(socket, io);
    handleIncidentUpdates(socket, io);

    // Connection cleanup
    socket.on('disconnect', (reason) => {
      console.log(`🔌 Client disconnected: ${socket.id} (${reason})`);
    });

    // Error handling
    socket.on('error', (error) => {
      console.error(`Socket error from ${socket.id}:`, error);
    });
  });

  console.log('🎯 Socket.IO event handlers configured');
}

function handleRoomJoining(socket, io) {
  // Join user-specific room
  socket.on('join_user_room', (userId) => {
    if (!userId) {
      socket.emit('error', { message: 'User ID required for room joining' });
      return;
    }

    socket.join(`user_${userId}`);
    console.log(`👤 User ${userId} joined their personal room`);
    socket.emit('room_joined', { room: `user_${userId}`, type: 'user' });
  });

  // Join role-specific room
  socket.on('join_role_room', (roleId) => {
    if (!roleId) {
      socket.emit('error', { message: 'Role ID required for room joining' });
      return;
    }

    socket.join(`role_${roleId}`);
    console.log(`👥 User joined role room: ${roleId}`);
    socket.emit('room_joined', { room: `role_${roleId}`, type: 'role' });
  });

  // Join mission-specific room
  socket.on('join_mission_room', (missionId) => {
    if (!missionId) {
      socket.emit('error', { message: 'Mission ID required for room joining' });
      return;
    }

    socket.join(`mission_${missionId}`);
    console.log(`🚁 User joined mission room: ${missionId}`);
    socket.emit('room_joined', { room: `mission_${missionId}`, type: 'mission' });
  });
}

function handleLocationUpdates(socket, io) {
  socket.on('location_update', (data) => {
    try {
      const { missionId, latitude, longitude, userId, accuracy, speed } = data;

      if (!missionId || !latitude || !longitude || !userId) {
        socket.emit('error', { message: 'Missing required location data' });
        return;
      }

      const locationData = {
        missionId,
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        userId,
        accuracy: accuracy ? parseFloat(accuracy) : null,
        speed: speed ? parseFloat(speed) : null,
        timestamp: new Date()
      };

      // Broadcast to admins for monitoring
      io.to('role_3').emit('rescue_team_location', locationData);

      // Send to specific mission room for real-time tracking
      io.to(`mission_${missionId}`).emit('team_location_update', locationData);

      console.log(`📍 Location update from user ${userId} for mission ${missionId}`);

      // Confirm receipt to sender
      socket.emit('location_update_ack', { success: true, timestamp: locationData.timestamp });

    } catch (error) {
      console.error('Location update error:', error);
      socket.emit('error', { message: 'Failed to process location update' });
    }
  });
}

function handleMissionUpdates(socket, io) {
  socket.on('mission_status_update', (data) => {
    try {
      const { missionId, status, userId, notes, location } = data;

      if (!missionId || !status || !userId) {
        socket.emit('error', { message: 'Missing required mission data' });
        return;
      }

      const missionData = {
        missionId,
        status,
        userId,
        notes,
        location,
        timestamp: new Date()
      };

      // Notify mission participants
      io.to(`mission_${missionId}`).emit('mission_status_changed', missionData);

      // Notify admins of all status changes
      io.to('role_3').emit('mission_status_changed', missionData);

      // Notify specific user rooms for assignments
      if (status === 'assigned') {
        io.to(`user_${userId}`).emit('mission_assigned', missionData);
      }

      console.log(`📋 Mission ${missionId} status updated to ${status} by user ${userId}`);

    } catch (error) {
      console.error('Mission update error:', error);
      socket.emit('error', { message: 'Failed to process mission update' });
    }
  });
}

function handleVolunteerRequests(socket, io) {
  socket.on('volunteer_request', (data) => {
    try {
      const volunteerData = {
        ...data,
        timestamp: new Date(),
        type: 'volunteer_request'
      };

      // Notify all admins
      io.to('role_3').emit('new_volunteer_request', volunteerData);

      console.log(`🙋 New volunteer request from user ${data.userId || 'unknown'}`);

      // Confirm receipt
      socket.emit('volunteer_request_ack', { success: true, timestamp: volunteerData.timestamp });

    } catch (error) {
      console.error('Volunteer request error:', error);
      socket.emit('error', { message: 'Failed to process volunteer request' });
    }
  });
}

function handleDonationUpdates(socket, io) {
  socket.on('donation_received', (data) => {
    try {
      const donationData = {
        ...data,
        timestamp: new Date(),
        type: 'donation'
      };

      // Notify admins
      io.to('role_3').emit('new_donation', donationData);

      // Confirm to donor if donorId provided
      if (data.donorId) {
        io.to(`user_${data.donorId}`).emit('donation_confirmed', donationData);
      }

      console.log(`💰 Donation received: ${data.amount || 'unknown amount'}`);

      // Confirm receipt
      socket.emit('donation_ack', { success: true, timestamp: donationData.timestamp });

    } catch (error) {
      console.error('Donation update error:', error);
      socket.emit('error', { message: 'Failed to process donation update' });
    }
  });
}

function handleIncidentUpdates(socket, io) {
  socket.on('incident_update', (data) => {
    try {
      const incidentData = {
        ...data,
        timestamp: new Date(),
        type: 'incident_update'
      };

      // Notify relevant stakeholders based on incident
      if (data.incidentId) {
        // Notify users following this incident
        io.to(`incident_${data.incidentId}`).emit('incident_status_changed', incidentData);
      }

      // Always notify admins
      io.to('role_3').emit('incident_updated', incidentData);

      console.log(`🚨 Incident ${data.incidentId || 'unknown'} updated`);

    } catch (error) {
      console.error('Incident update error:', error);
      socket.emit('error', { message: 'Failed to process incident update' });
    }
  });
}
