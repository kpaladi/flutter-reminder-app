package com.example.reminder_app;

import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.content.Intent;
import android.util.Log;

public class NotificationMonitorEmailService extends NotificationListenerService {

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        if (!sbn.getPackageName().equals(getApplicationContext().getPackageName())) return;

        String title = sbn.getNotification().extras.getString("android.title");
        String description = sbn.getNotification().extras.getString("android.text");

        if (title == null) title = "No Title";
        if (description == null) description = "No Description";


        Intent intent = new Intent("com.example.notifications.EMAIL_INTENT");
        intent.setClassName(getPackageName(), "com.example.reminder_app.EmailBroadcastReceiver");
        intent.putExtra("title", title);
        intent.putExtra("description", description);
        sendBroadcast(intent);

        Log.d("NotificationMonitor", "Broadcast sent with title: " + title + ", description: " + description);
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        Log.d("NotificationMonitor", "Notification Removed: " + sbn.getPackageName());
    }
}
