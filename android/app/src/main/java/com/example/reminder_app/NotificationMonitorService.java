package com.example.reminder_app;

import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.content.Intent;
import android.util.Log;

public class NotificationMonitorService extends NotificationListenerService {

    private static final String TAG = "NotificationMonitor";

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        Log.d(TAG, "🔔 Notification Posted getPackageName: " + sbn.getPackageName());

        // Check if the notification belongs to your app
        if (!sbn.getPackageName().equals("com.darahaas.reminderapp")) {
            return; // Ignore notifications from other apps
        }

        String title = sbn.getNotification().extras.getString("android.title");
        String description = sbn.getNotification().extras.getString("android.text");

        Log.d(TAG, "📨 Detected Notification - Title: " + title + ", Description: " + description);


        // Send broadcast to trigger email
        Intent intent = new Intent("com.example.notifications.EMAIL_INTENT");
        intent.putExtra("title", title);
        intent.putExtra("description", description);
        intent.setClass(getApplicationContext(), EmailBroadcastReceiver.class);
        Log.d("NotificationMonitorService", "🚀 Sending Explicit Email Broadcast...");
        // sendBroadcast(intent);
        getApplicationContext().sendBroadcast(intent);

        Log.d(TAG, "📩 Broadcast Sent for Email!");
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        Log.d(TAG, "❌ Notification Removed: " + sbn.getPackageName());
    }
}
