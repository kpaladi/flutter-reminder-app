package com.example.reminder_app;

import android.content.Intent;
import android.provider.Settings;
import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class NotificationAccessService implements MethodCallHandler {

    private static final String CHANNEL = "notification_access_channel";
    private final Context context;

    public NotificationAccessService(Context context) {
        this.context = context;
    }

    public static void registerWith(FlutterEngine flutterEngine, Context context) {
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(new NotificationAccessService(context));
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if ("isNotificationAccessEnabled".equals(call.method)) {
            result.success(isNotificationServiceEnabled(context));
        } else if ("openNotificationAccessSettings".equals(call.method)) {
            openNotificationAccessSettings(context);
            result.success(true);
        } else {
            result.notImplemented();
        }
    }

    private boolean isNotificationServiceEnabled(Context context) {
        final String pkgName = context.getPackageName();
        final String flat = Settings.Secure.getString(
                context.getContentResolver(),
                "enabled_notification_listeners"
        );

        return flat != null && flat.contains(pkgName);
    }

    private void openNotificationAccessSettings(Context context) {
        Intent intent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(intent);
    }
}





