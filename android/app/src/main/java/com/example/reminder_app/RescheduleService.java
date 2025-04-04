package com.example.reminder_app;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.content.SharedPreferences;
import android.os.IBinder;
import android.util.Log;
import android.content.Context;

import androidx.core.app.NotificationCompat;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.dart.DartExecutor;

public class RescheduleService extends Service {
    private static final String TAG = "RescheduleService";
    private static final String CHANNEL_ID = "reminder_channel_darahaas";
    private static final String PREF_NAME = "RescheduleServicePrefs";
    private static final String PREF_SERVICE_RUNNING = "serviceRunning";

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "onCreate called.");

        SharedPreferences prefs = getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        boolean serviceRunning = prefs.getBoolean(PREF_SERVICE_RUNNING, false);


        if (serviceRunning) {
            Log.d(TAG, "Service already running, stopping duplicate start.");
            stopSelf();
            return;
        }

        SharedPreferences.Editor editor = prefs.edit();
        editor.putBoolean(PREF_SERVICE_RUNNING, true);
        editor.apply();

        createNotificationChannel();
        startForeground(1, getNotification());
        Log.d(TAG, "onCreate finished.");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "onStartCommand called.");

        // Try to get the FlutterEngine from the cache
        FlutterEngine flutterEngine = FlutterEngineCache.getInstance().get("default_engine");
        Log.d(TAG, "Got flutterEngine from cache: " + (flutterEngine != null));

        // If the FlutterEngine is not found in the cache, create and initialize a new one
        if (flutterEngine == null) {
            Log.d(TAG, "Creating new flutterEngine.");
            flutterEngine = new FlutterEngine(this);

            // Start the Flutter engine and add it to the cache
            flutterEngine.getDartExecutor().executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
            );
            FlutterEngineCache.getInstance().put("default_engine", flutterEngine);
            Log.d(TAG, "New flutterEngine initialized and cached.");

        }

        // Create the method channel and invoke the method
        MethodChannel channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "reminder_channel_darahaas");
        Log.d(TAG, "MethodChannel created.");
        channel.invokeMethod("rescheduleNotifications", null, new MethodChannel.Result() {
            @Override
            public void success(Object result) {
                Log.d(TAG, "Method call success.. ");
                stopSelf(); // Stop the service after successful execution
            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {
                Log.e(TAG, "Method call failed: " + errorCode + " " + errorMessage);
                stopSelf(); // Stop the service even if there's an error
            }

            @Override
            public void notImplemented() {
                Log.e(TAG, "Method call not implemented");
                stopSelf(); // Stop the service if not implemented.
            }
        });
        Log.d(TAG, "Method invoked.");

        Log.d(TAG, "onStartCommand finished.");
        return START_NOT_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        Log.d(TAG, "onBind called.");
        return null;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d(TAG, "Creating notification channel.");
            NotificationChannel serviceChannel = new NotificationChannel(
                    CHANNEL_ID,
                    "Reschedule Notifications",
                    NotificationManager.IMPORTANCE_LOW
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(serviceChannel);
                Log.d(TAG, "Notification channel created.");
            }
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "onDestroy called.");
    }

    private Notification getNotification() {
        Log.d(TAG, "Creating notification.");
        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Rescheduling Reminders")
                .setContentText("Restoring scheduled notifications after reboot.")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .build();
    }
}