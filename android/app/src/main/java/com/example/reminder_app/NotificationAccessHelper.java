package com.example.reminder_app;

import android.content.Context;
import android.content.Intent;
import android.provider.Settings;
import android.text.TextUtils;

public class NotificationAccessHelper {

    public static boolean isNotificationAccessEnabled(Context context) {
        String pkgName = context.getPackageName();
        final String flat = Settings.Secure.getString(
                context.getContentResolver(),
                "enabled_notification_listeners"
        );

        return flat != null && flat.contains(pkgName);
    }

    public static void openNotificationAccessSettings(Context context) {
        Intent intent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(intent);
    }
}