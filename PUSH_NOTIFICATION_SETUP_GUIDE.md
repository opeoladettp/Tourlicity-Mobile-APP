# Push Notification Setup Guide

## 🔔 **Two Options for Push Notifications**

You can choose between Firebase (recommended) or a custom solution using your existing database.

## Option 1: Firebase Setup (Recommended) 🔥

### **Why Firebase?**
- ✅ Industry standard for mobile push notifications
- ✅ Reliable delivery even when app is closed
- ✅ Works on both Android and iOS
- ✅ Handles device tokens automatically
- ✅ Free tier available

### **Firebase Setup Steps:**

#### **1. Create Firebase Project**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Project name: "Tourlicity"
4. Enable Google Analytics (optional)
5. Create project

#### **2. Add Android App**
1. In Firebase Console → Project Overview → Add app → Android
2. Package name: `com.example.tourlicity`
3. Download `google-services.json`
4. Place in: `android/app/google-services.json`

#### **3. Add iOS App** (if needed)
1. In Firebase Console → Add app → iOS
2. Bundle ID: `com.example.tourlicity`
3. Download `GoogleService-Info.plist`
4. Place in: `ios/Runner/GoogleService-Info.plist`

#### **4. Get Server Key**
1. Go to Project Settings → Cloud Messaging
2. Copy "Server key" (for your backend)

#### **5. Update Flutter Dependencies**
```yaml
# Uncomment these in pubspec.yaml
firebase_core: ^2.24.2
firebase_messaging: ^14.7.10
```

#### **6. Update Backend (Node.js)**
```bash
npm install firebase-admin
```

```javascript
// backend/services/pushNotificationService.js
const admin = require('firebase-admin');

// Initialize Firebase Admin (add this to your backend)
const serviceAccount = require('./firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Send push notification function
async function sendPushNotification(fcmToken, title, body, data = {}) {
  const message = {
    notification: { title, body },
    data: data,
    token: fcmToken
  };
  
  try {
    const response = await admin.messaging().send(message);
    console.log('Push notification sent:', response);
    return response;
  } catch (error) {
    console.error('Error sending push notification:', error);
    throw error;
  }
}

// Send to multiple devices
async function sendBulkNotifications(tokens, title, body, data = {}) {
  const message = {
    notification: { title, body },
    data: data,
    tokens: tokens
  };
  
  try {
    const response = await admin.messaging().sendMulticast(message);
    console.log('Bulk notifications sent:', response);
    return response;
  } catch (error) {
    console.error('Error sending bulk notifications:', error);
    throw error;
  }
}

module.exports = { sendPushNotification, sendBulkNotifications };
```

#### **7. Update Your Notification Endpoints**
```javascript
// Add to your existing notification routes
app.post('/api/notifications/subscribe', async (req, res) => {
  try {
    const { fcmToken, userId } = req.body;
    
    // Save FCM token to user's record in database
    await User.findByIdAndUpdate(userId, { fcmToken });
    
    res.json({ message: 'Subscribed successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/notifications/send', async (req, res) => {
  try {
    const { userId, title, body, type, data } = req.body;
    
    // Get user's FCM token
    const user = await User.findById(userId);
    if (!user.fcmToken) {
      return res.status(400).json({ error: 'User not subscribed to notifications' });
    }
    
    // Send notification
    await sendPushNotification(user.fcmToken, title, body, { type, ...data });
    
    res.json({ message: 'Notification sent successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

---

## Option 2: Custom Push Notifications (Using Your Database) 🛠️

### **Why Custom?**
- ✅ Full control over notification system
- ✅ Uses your existing database
- ✅ No external dependencies
- ✅ Can integrate with your current API structure

### **Custom Implementation (Already Created)**

I've created `lib/services/custom_push_notification_service.dart` that uses:
- **WebSockets** for real-time notifications
- **Polling** as fallback method
- **Local notifications** for display
- **Your existing API** for notification management

### **Backend WebSocket Setup (Node.js)**

#### **1. Install WebSocket Dependencies**
```bash
npm install ws socket.io
```

#### **2. Add WebSocket Server**
```javascript
// backend/websocket/notificationSocket.js
const WebSocket = require('ws');

class NotificationWebSocket {
  constructor(server) {
    this.wss = new WebSocket.Server({ server, path: '/notifications/ws' });
    this.clients = new Map(); // userId -> WebSocket connection
    
    this.wss.on('connection', (ws, req) => {
      const userId = new URL(req.url, 'http://localhost').searchParams.get('userId');
      
      if (userId) {
        this.clients.set(userId, ws);
        console.log(`User ${userId} connected to notifications`);
        
        ws.on('message', (message) => {
          try {
            const data = JSON.parse(message);
            if (data.type === 'heartbeat') {
              ws.send(JSON.stringify({ type: 'heartbeat_ack' }));
            }
          } catch (error) {
            console.error('Invalid WebSocket message:', error);
          }
        });
        
        ws.on('close', () => {
          this.clients.delete(userId);
          console.log(`User ${userId} disconnected from notifications`);
        });
      }
    });
  }
  
  // Send notification to specific user
  sendToUser(userId, notification) {
    const ws = this.clients.get(userId);
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'notification',
        notification: notification
      }));
      return true;
    }
    return false;
  }
  
  // Send notification to all connected users
  broadcast(notification) {
    this.clients.forEach((ws, userId) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'notification',
          notification: notification
        }));
      }
    });
  }
}

module.exports = NotificationWebSocket;
```

#### **3. Integrate with Your Server**
```javascript
// backend/server.js (add to your existing server)
const NotificationWebSocket = require('./websocket/notificationSocket');

// After creating your HTTP server
const notificationWS = new NotificationWebSocket(server);

// Add to your notification service
async function sendNotificationToUser(userId, title, body, type, data = {}) {
  const notification = { title, body, type, data };
  
  // Try WebSocket first (real-time)
  const sent = notificationWS.sendToUser(userId, notification);
  
  if (!sent) {
    // Fallback: Store in database for polling
    await Notification.create({
      userId,
      title,
      body,
      type,
      data,
      delivered: false,
      createdAt: new Date()
    });
  }
  
  // Also send email if enabled
  if (data.includeEmail) {
    await sendEmailNotification(userId, title, body);
  }
}
```

#### **4. Add Polling Endpoint**
```javascript
// Add to your notification routes
app.get('/api/notifications/pending', async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get undelivered notifications
    const notifications = await Notification.find({
      userId,
      delivered: false
    }).sort({ createdAt: -1 });
    
    // Mark as delivered
    await Notification.updateMany(
      { userId, delivered: false },
      { delivered: true }
    );
    
    res.json({ notifications });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

---

## 🎯 **Recommendation**

### **For Production: Use Firebase** 🔥
- More reliable for mobile push notifications
- Works when app is completely closed
- Industry standard with excellent documentation
- Easier to implement and maintain

### **For Custom Control: Use Custom Solution** 🛠️
- Full control over notification system
- Integrates with your existing database
- No external dependencies
- More complex to implement and maintain

---

## 🚀 **Quick Start Instructions**

### **To Enable Firebase:**
1. Follow Firebase setup steps above
2. Uncomment Firebase dependencies in `pubspec.yaml`
3. Uncomment Firebase imports in `push_notification_service.dart`
4. Add configuration files to Android/iOS folders

### **To Use Custom Solution:**
1. Add WebSocket server to your backend (code provided above)
2. The custom service is already created and ready to use
3. Update your notification endpoints to support WebSocket

### **To Test Either Solution:**
1. Run `flutter pub get`
2. The settings dropdown will show notification status
3. Use the "Test" button to send test notifications

Choose the option that best fits your needs! Firebase is recommended for most use cases, but the custom solution gives you complete control.