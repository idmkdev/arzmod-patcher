    package com.arzmod.radare;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.util.Log;
import java.lang.reflect.Method;
import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import com.arizona.launcher.ArizonaApplication;
import com.arizona.launcher.model.settings.SettingsConstants;

public class FirebaseAdd extends FirebaseMessagingService {
    private static final String TAG = "arzmod-firebase-module";
    private static final String CHANNEL_ID = "DefaultChannel";
    private static final String TOPIC = "subscriber-updates";
    private static FirebaseMessaging messageApp = null;
    
    public static void initializeAndSubscribe(Context context) {
        FirebaseOptions options = new FirebaseOptions.Builder()
                .setProjectId("arizona-21")
                .setApiKey("AIzaSyAlNT6Qr1qEGgZu1_Aq3yet7cssDeLv95o")
                .setApplicationId("1:551532909837:android:639dc64fff7a76e437cc44")
                .setGcmSenderId("551532909837")
                .setStorageBucket("arizona-21.appspot.com")
                .build();

        try {
            FirebaseApp app = FirebaseApp.initializeApp(context, options, "ARZFirebaseApp");
            messageApp = app.get(FirebaseMessaging.class);

            messageApp.setAutoInitEnabled(true);

            messageApp.subscribeToTopic(TOPIC)
                .addOnCompleteListener(new OnCompleteListener<Void>() {
                    @Override
                    public void onComplete(@NonNull Task<Void> task) {
                        if (task.isSuccessful()) {
                            Log.d(TAG, "Subscribed to topic: " + TOPIC);
                            updateCurrentFcmToken();
                        } else {
                            Log.e(TAG, "Failed to subscribe to topic", task.getException());
                        }
                    }
                });

            updateCurrentFcmToken();
        } catch (IllegalStateException e) {
            Log.w(TAG, "FirebaseApp already initialized");
        }

    }

    public void onNewToken(String token) {
        super.onNewToken(token);
        Log.d(TAG, "New token FCM: " + token);
        if(messageApp != null) {
            messageApp.subscribeToTopic(TOPIC)
                .addOnCompleteListener(new OnCompleteListener<Void>() {
                    @Override
                    public void onComplete(@NonNull Task<Void> task) {
                        if (task.isSuccessful()) {
                            Log.d(TAG, "Subscribed to topic: " + TOPIC);
                            updateCurrentFcmToken();
                        } else {
                            Log.e(TAG, "Failed to subscribe to topic", task.getException());
                        }
                    }
                });
        }
    }

    public static void updateCurrentFcmToken() {
        if(messageApp != null)
        {
            messageApp.getToken()
                .addOnCompleteListener(new OnCompleteListener<String>() {
                    @Override
                    public void onComplete(@NonNull Task<String> task) {
                        if (!task.isSuccessful()) {
                            Log.e(TAG, "Fetching FCM registration token failed", task.getException());
                            return;
                        }
                        String token = task.getResult();
                        Log.d(TAG, "Current FCM Token: " + token);
                        SettingsPatch.getSettingsPreferences().edit().putString(SettingsConstants.TOKEN, token).apply();
                    }
                });
        }
        else Log.e(TAG, "messageApp is null");
    }

}
