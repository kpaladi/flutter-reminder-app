package com.example.reminder_app;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class DeviceBootReceiver extends BroadcastReceiver {
    private static final String TAG = "DeviceBootReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d(TAG, "BootReceiver onReceive called.");
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            Log.d(TAG, "ACTION_BOOT_COMPLETED received.");
            // Call Flutter service to reschedule notifications
            Intent serviceIntent = new Intent(context, RescheduleService.class);
            Log.d(TAG, "Created RescheduleService intent.");
            try{
                context.startForegroundService(serviceIntent);
                Log.d(TAG, "Started RescheduleService.");
            } catch (Exception e) {
                Log.e(TAG, "Error starting RescheduleService: " + e.getMessage());
                e.printStackTrace();
            }
        } else {
            Log.d(TAG, "Received intent with action: " + intent.getAction());
        }
        Log.d(TAG, "BootReceiver onReceive finished.");
    }
}