package com.example.reminder_app;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import io.flutter.plugin.common.BinaryMessenger;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;



public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.notifications/email_intent";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        NotificationAccessService.registerWith(flutterEngine, getApplicationContext());

        Log.d("MainActivity", "✅ Inside configureFlutterEngine() - Start");

        // Get the binary messenger
        BinaryMessenger messenger = flutterEngine.getDartExecutor().getBinaryMessenger();
        Log.d("MainActivity", "📡 BinaryMessenger obtained");

        // Create MethodChannel instance
        MethodChannel methodChannel = new MethodChannel(messenger, CHANNEL);
        Log.d("MainActivity", "📡 MethodChannel created with name: " + CHANNEL);

        // Set the method call handler
        methodChannel.setMethodCallHandler((call, result) -> {
            Log.d("MainActivity", "📞 Method call received - Method: " + call.method);

            if (call.method.equals("sendEmail")) {
                Log.d("MainActivity", "📩 Processing 'sendEmail' request...");

                // Extract arguments
                String title = call.argument("title");
                String description = call.argument("description");

                Log.d("MainActivity", "📨 Email request details - Title: " + title + ", Description: " + description);

                if (title == null || description == null) {
                    Log.e("MainActivity", "⚠️ Error: Null values received for title or description");
                    result.error("NULL_ARGUMENTS", "Title or description is null", null);
                    return;
                }

                // Call email broadcast function
                try {
                    Log.d("MainActivity", "🚀 Calling sendEmailBroadcast()");
                    sendEmailBroadcast(title, description);
                    Log.d("MainActivity", "✅ Email broadcast request sent successfully");
                    result.success(null);
                } catch (Exception e) {
                    Log.e("MainActivity", "❌ Error sending email request: " + e.getMessage());
                    result.error("EMAIL_SEND_FAILED", "Failed to send email request", e);
                }
            } else {
                Log.w("MainActivity", "⚠️ Method not implemented: " + call.method);
                result.notImplemented();
            }
        });

        Log.d("MainActivity", "✅ configureFlutterEngine() - Completed");
    }


    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    private void sendEmailBroadcast(String title, String description) {
        Intent intent = new Intent("com.example.notifications.EMAIL_INTENT");
        intent.putExtra("title", title);
        intent.putExtra("description", description);

        Log.d("sendEmailBroadcast", "🔥 Attempting to send broadcast: Title = " + title + ", Description = " + description);
        // intent.setClass(context, EmailBroadcastReceiver.class);
        sendBroadcast(intent);
        Log.d("sendEmailBroadcast", "✅ Broadcast Sent!");
    }


}
