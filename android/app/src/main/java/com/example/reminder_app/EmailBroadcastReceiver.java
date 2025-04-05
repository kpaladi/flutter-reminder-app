package com.example.reminder_app;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import java.util.Properties;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;


import android.content.SharedPreferences;

public class EmailBroadcastReceiver extends BroadcastReceiver {

    private static final String TAG = "EmailBroadcastReceiver";

    // Create a single-threaded executor for background execution
    private final ExecutorService executorService = Executors.newSingleThreadExecutor();

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d(TAG, "🔥 Broadcast Received!");

        Log.d(TAG, "❤️ Fetching email configurations from settings");
        SharedPreferences prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
        if (prefs != null) {
            Log.d("SharedPreferences", "Successfully accessed SharedPreferences.");
        } else {
            Log.d("SharedPreferences", "Failed to access SharedPreferences.");
            return;
        }
        String emailFlagKey = "flutter.email_enabled";
        Log.d("SharedPreferences", "Accessing key: " + emailFlagKey);
        boolean sendEmail = prefs.getBoolean(emailFlagKey, false);
        Log.d("SharedPreferences", "Retrieved email preference: " + sendEmail);

        if (!sendEmail) {
            Log.d(TAG, "❌ Enable email configuration in settings to send email for notification");
            return;
        }

        String emailKey = "flutter.recipient_email"; // Use the correct key here
        Log.d("SharedPreferences", "Accessing key: " + emailKey);
        String emailId = prefs.getString(emailKey, "No email id provided");
        Log.d("SharedPreferences", "Retrieved email ID: " + emailId);

        if (emailId.equals("none")) {
            Log.d(TAG, "❌ Enable email configuration in settings to send email for notification");
            return;
        }

        if (intent == null) {
            Log.e(TAG, "❌ Intent is NULL");
            return;
        }

        String title = intent.getStringExtra("title"); // Get the title

        if (title != null && title.startsWith("Snooze - ")) {
            Log.d(TAG, "👎 Its snooze notification, no email will be sent");
            return;
        }

        if (title == null) title = "No Title Provided";

        // Debugging: Log all extras
        Bundle extras = intent.getExtras();
        if (extras == null) {
            Log.e(TAG, "❌ No extras received!");
            return;
        }

        String description = intent.getStringExtra("description");

        if (description == null) description = "No Description Provided";

        Log.d(TAG, "📩 Email ID: " + emailId + ", Title: " + title + ", Description: " + description);

        // Send email in background
        sendEmailInBackground(emailId, title, description);
    }

    private void sendEmailInBackground(String recipientEmail, String subject, String body) {
        executorService.execute(() -> {
            try {
                sendEmail(recipientEmail, subject, body);
                Log.d(TAG, "✅ Email successfully sent!");
            } catch (Exception e) {
                Log.e(TAG, "❌ Error sending email: " + e.getMessage(), e);
            }
        });
    }

    private void sendEmail(String recipientEmail, String subject, String body) {
        new Thread(() -> {
            final String senderEmail = BuildConfig.SENDER_EMAIL;  // Replace with your email
            final String senderPassword = BuildConfig.SENDER_PASSWORD; // Use an App Password if using Gmail

            Properties props = new Properties();
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.host", "smtp.gmail.com");
            props.put("mail.smtp.port", "587");

            Session session = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(senderEmail, senderPassword);
                }
            });

            try {
                Message message = new MimeMessage(session);
                message.setFrom(new InternetAddress(senderEmail));
                message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(recipientEmail));
                message.setSubject(subject);
                message.setText(body);

                Transport.send(message);
                Log.d("EmailBroadcastReceiver", "✅ Email sent successfully");
            } catch (MessagingException e) {
                Log.e("EmailBroadcastReceiver", "❌ Error sending email: " + e.getMessage());
            }
        }).start();
    }

}