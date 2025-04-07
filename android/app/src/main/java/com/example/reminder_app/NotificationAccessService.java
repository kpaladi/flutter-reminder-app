package com.example.reminder_app;

import android.content.Intent;
import android.os.Build;
import android.os.Environment;
import android.provider.Settings;
import android.content.Context;
import android.net.Uri;

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
        switch (call.method) {
            case "isNotificationAccessEnabled":
                result.success(isNotificationServiceEnabled(context));
                break;
            case "openNotificationAccessSettings":
                openNotificationAccessSettings(context);
                result.success(true);
                break;
            case "isAllFilesAccessGranted":
                result.success(isAllFilesAccessGranted());
                break;
            case "openAllFilesAccessSettings":
                openAllFilesAccessSettings();
                result.success(true);
                break;
            default:
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

    private boolean isAllFilesAccessGranted() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return Environment.isExternalStorageManager();
        }
        return true; // assume true for Android 10 and below
    }

    private void openAllFilesAccessSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Intent intent = new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION);
            intent.setData(Uri.parse("package:" + context.getPackageName()));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        }
    }
}
