package com.arzmod.radare;

import com.arzmod.radare.AppContext;
import com.arzmod.radare.FirebaseAdd;
import android.widget.Toast;
import android.util.Log;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.content.SharedPreferences;
import android.os.SystemClock;
import android.preference.PreferenceManager;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.PopupWindow;
import android.widget.RelativeLayout;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.GradientDrawable;
import android.os.Handler;
import android.os.Looper;
import android.app.Activity;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.view.animation.AnimationSet;
import android.view.animation.ScaleAnimation;
import android.view.animation.TranslateAnimation;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.os.Build;
import com.bumptech.glide.Glide;
import com.bumptech.glide.load.resource.gif.GifDrawable;
import com.bumptech.glide.request.target.SimpleTarget;
import com.bumptech.glide.request.transition.Transition;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import org.json.JSONObject;
import org.json.JSONException;
import java.io.IOException;
import com.miami.game.feature.download.dialog.ui.connection.ConnectionHolder;
import com.arizona.game.GTASA;
import com.arizona.game.BuildConfig;
import com.arzmod.radare.InitGamePatch;
import org.json.JSONObject;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.Writer;
import android.app.AlertDialog;
import android.widget.Button;
import android.widget.TextView;
import android.content.DialogInterface;
import java.util.Arrays;

public class ApplicationStart {
    private static final long MIN_START_INTERVAL = 1000;
    private static final String BANNER_API_URL = "https://api.arzmod.com/banner?version="+ BuildConfig.VERSION_CODE;
    private static final String LAST_BANNER_ID_KEY = "last_banner_id";
    private static final int ANIMATION_DURATION = 300;
    private static final int CLOSE_BUTTON_SIZE = 40;
    private static final int CLOSE_BUTTON_MARGIN = 10;
    private static final int BANNER_CORNER_RADIUS = 20;
    private long lastStartGameTime = 0;
    private Context context;
    private static PopupWindow bannerPopup;
    private static View backgroundView;
    private static boolean isImageLoaded = false;
    private static boolean isClosing = false;
    private static Handler timeoutHandler = new Handler(Looper.getMainLooper());
    private static Runnable timeoutRunnable;

    public ApplicationStart(Context context) {
        this.context = context;
    }

    public void start() {
        Log.d("arzmod-app-module", "-> Application started.");
        AppContext.setContext(context);
        FirebaseAdd.initializeAndSubscribe(context);
    }

    public void handleSampLink(Intent intent) {
        if (intent != null && intent.getData() != null) {
            String host = intent.getData().getHost();
            String port = intent.getData().getPort() > 0 ? 
            String.valueOf(intent.getData().getPort()) : "7777";
            String nickname = intent.getData().getQueryParameter("nickname");
            String password = intent.getData().getQueryParameter("password");
            
            Log.d("arzmod-app-module", "Connect to server: " + host + ":" + port + " | Name: " + nickname + " | Password: " + password);
            connectToServer(host, port, nickname, password);
        }
    }

    public void connectToServer(String ip, String port, String nickname, String password) {
        long currentTime = SystemClock.elapsedRealtime();
        if (currentTime - lastStartGameTime >= MIN_START_INTERVAL) {
            lastStartGameTime = currentTime;

            if(ip.equals("lastplayed")) {    
                context.startActivity(new Intent(context, GTASA.class));
                return;
            }
            try {
                File externalDir = context.getExternalFilesDir(null);
                File sampDir = new File(externalDir, "SAMP");
                sampDir.mkdirs();

                
                File settingsFile = new File(sampDir, "settings.json");
                if (settingsFile.exists()) {
                    settingsFile.delete();
                }
                settingsFile.createNewFile();

                SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
                boolean headMoving = prefs.getBoolean("head_moving", false);

                JSONObject settings = new JSONObject();
            
                JSONObject server = new JSONObject()
                    .put("id", 0)
                    .put("serverid", 0);
                
                JSONObject test = new JSONObject()
                    .put("ip", ip != null ? ip : ConnectionHolder.INSTANCE.getSettingsData().getIp())
                    .put("port", port != null ? Integer.parseInt(port) : 
                        ConnectionHolder.INSTANCE.getSettingsData().getPort())
                    .put("pass", password != null ? password : "");

                JSONObject client = new JSONObject()
                    .put("server", server)
                    .put("test", test);

                JSONObject launcher = new JSONObject()
                    .put("nickname", nickname != null ? nickname : 
                        ConnectionHolder.INSTANCE.getSettingsData().getPassword())
                    .put("chat_pagesize", ConnectionHolder.INSTANCE.getSettingsData().getPageSize())
                    .put("chat_fontsize", ConnectionHolder.INSTANCE.getSettingsData().getChatFontSize())
                    .put("chat_print_timestamp", ConnectionHolder.INSTANCE.getSettingsData().getShowChatTime())
                    .put("streamer_mode", ConnectionHolder.INSTANCE.getSettingsData().getStreamerMode())
                    .put("head_moving", headMoving);

                settings.put("client", client)
                       .put("launcher", launcher);

                try (BufferedWriter writer = new BufferedWriter(new FileWriter(settingsFile))) {
                    writer.write(settings.toString());
                }
                context.startActivity(new Intent(context, GTASA.class));
            } catch (Exception e) {
                Log.e("arzmod-app-module", "Error connecting to server", e);
            }
        }
    }

    public static void showBanner() {
        Context context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-app-module", "Context is null");
            return;
        }

        if (!(context instanceof Activity)) {
            Log.e("arzmod-app-module", "Context is not an Activity");
            return;
        }

        final Activity activity = (Activity) context;
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    URL url = new URL(BANNER_API_URL);
                    HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                    connection.setDoInput(true);
                    connection.connect();
                    InputStream input = connection.getInputStream();
                    String jsonResponse = new java.util.Scanner(input).useDelimiter("\\A").next();
                    input.close();

                    JSONObject json = new JSONObject(jsonResponse);
                    if (json.length() == 0) {
                        return;
                    }

                    final String bannerId = json.getString("id");
                    final int width = json.getInt("width");
                    final int height = json.getInt("height");
                    final String imageUrl = json.getString("imageUrl");
                    final String bannerUrl = json.getString("url");
                    final boolean isActive = json.getBoolean("isActive");

                    if(!isActive) {
                        return;
                    }

                    Log.d("arzmod-app-module", "Banner ID: " + bannerId + " | Width: " + width + " | Height: " + height + " | Image URL: " + imageUrl + " | Banner URL: " + bannerUrl);

                    SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
                    String lastBannerId = prefs.getString(LAST_BANNER_ID_KEY, "");
                    if (bannerId.equals(lastBannerId)) {
                        return;
                    }

                    new Handler(Looper.getMainLooper()).post(new Runnable() {
                        @Override
                        public void run() {
                            if (activity.isFinishing() || activity.isDestroyed()) {
                                Log.e("arzmod-app-module", "Activity is destroyed or finishing");
                                return;
                            }

                            isImageLoaded = false;
                            isClosing = false;

                            timeoutRunnable = new Runnable() {
                                @Override
                                public void run() {
                                    isImageLoaded = true;
                                }
                            };
                            timeoutHandler.postDelayed(timeoutRunnable, 3000);


                            RelativeLayout bannerLayout = new RelativeLayout(context);
                            bannerLayout.setLayoutParams(new ViewGroup.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                ViewGroup.LayoutParams.MATCH_PARENT
                            ));

                            bannerLayout.setOnClickListener(new View.OnClickListener() {
                                @Override
                                public void onClick(View v) {
                                    if (!isImageLoaded || isClosing) return;
                                    dismissBannerWithAnimation();
                                }
                            });

                            RelativeLayout bannerContainer = new RelativeLayout(context);
                            RelativeLayout.LayoutParams containerParams = new RelativeLayout.LayoutParams(
                                width, height
                            );
                            containerParams.addRule(RelativeLayout.CENTER_IN_PARENT);
                            bannerContainer.setLayoutParams(containerParams);

                            GradientDrawable containerBackground = new GradientDrawable();
                            containerBackground.setShape(GradientDrawable.RECTANGLE);
                            containerBackground.setCornerRadius(BANNER_CORNER_RADIUS);
                            containerBackground.setColor(Color.TRANSPARENT);
                            bannerContainer.setBackground(containerBackground);

                            ImageView bannerImage = new ImageView(context);
                            RelativeLayout.LayoutParams imageParams = new RelativeLayout.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                ViewGroup.LayoutParams.MATCH_PARENT
                            );
                            bannerImage.setLayoutParams(imageParams);
                            bannerImage.setScaleType(ImageView.ScaleType.FIT_XY);
                            bannerImage.setAlpha(0f);

                            GradientDrawable imageBackground = new GradientDrawable();
                            imageBackground.setShape(GradientDrawable.RECTANGLE);
                            imageBackground.setCornerRadius(BANNER_CORNER_RADIUS);
                            imageBackground.setColor(Color.TRANSPARENT);
                            bannerImage.setBackground(imageBackground);
                            bannerImage.setClipToOutline(true);

                            ImageView closeButton = new ImageView(context);
                            RelativeLayout.LayoutParams closeParams = new RelativeLayout.LayoutParams(
                                CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE
                            );
                            closeParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
                            closeParams.addRule(RelativeLayout.ALIGN_PARENT_TOP);
                            closeParams.setMargins(CLOSE_BUTTON_MARGIN, CLOSE_BUTTON_MARGIN, CLOSE_BUTTON_MARGIN, 0);
                            closeButton.setLayoutParams(closeParams);
                            closeButton.setImageResource(android.R.drawable.ic_menu_close_clear_cancel);
                            closeButton.setAlpha(0f);

                            GradientDrawable circleBackground = new GradientDrawable();
                            circleBackground.setShape(GradientDrawable.OVAL);
                            circleBackground.setColor(Color.RED);
                            closeButton.setBackground(circleBackground);
                            closeButton.setPadding(10, 10, 10, 10);

                            bannerContainer.addView(bannerImage, 0);
                            bannerContainer.addView(closeButton, 1);
                            bannerLayout.addView(bannerContainer);

                            bannerPopup = new PopupWindow(
                                bannerLayout,
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                true
                            );
                            bannerPopup.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));

                            bannerPopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                                @Override
                                public void onDismiss() {
                                    timeoutHandler.removeCallbacks(timeoutRunnable);
                                }
                            });

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                bannerPopup.setElevation(100f);
                            }

                            int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                                    | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                                    | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                                    | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                                    | View.SYSTEM_UI_FLAG_FULLSCREEN
                                    | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;

                            View decorView = activity.getWindow().getDecorView();
                            decorView.setSystemUiVisibility(flags);

                            if (imageUrl.toLowerCase().endsWith(".gif")) {
                                if (!activity.isFinishing() && !activity.isDestroyed()) {
                                    Glide.with(activity)
                                        .asGif()
                                        .load(imageUrl)
                                        .into(new SimpleTarget<GifDrawable>() {
                                            @Override
                                            public void onResourceReady(GifDrawable resource, Transition<? super GifDrawable> transition) {
                                                if (activity.isFinishing() || activity.isDestroyed()) return;
                                                bannerImage.setImageDrawable(resource);
                                                resource.start();
                                                isImageLoaded = true;
                                                timeoutHandler.removeCallbacks(timeoutRunnable);
                                                
                                                bannerPopup.showAtLocation(
                                                    decorView,
                                                    Gravity.CENTER,
                                                    0,
                                                    0
                                                );
                                                
                                                showBannerWithAnimation(bannerImage, closeButton);
                                                PreferenceManager.getDefaultSharedPreferences(context)
                                                    .edit()
                                                    .putString(LAST_BANNER_ID_KEY, bannerId)
                                                    .apply();
                                            }
                                        });
                                }
                            } else {
                                if (!activity.isFinishing() && !activity.isDestroyed()) {
                                    Glide.with(activity)
                                        .asBitmap()
                                        .load(imageUrl)
                                        .into(new SimpleTarget<Bitmap>() {
                                            @Override
                                            public void onResourceReady(Bitmap resource, Transition<? super Bitmap> transition) {
                                                if (activity.isFinishing() || activity.isDestroyed()) return;
                                                bannerImage.setImageBitmap(resource);
                                                isImageLoaded = true;
                                                timeoutHandler.removeCallbacks(timeoutRunnable);
                                                
                                                bannerPopup.showAtLocation(
                                                    decorView,
                                                    Gravity.CENTER,
                                                    0,
                                                    0
                                                );
                                                
                                                showBannerWithAnimation(bannerImage, closeButton);

                                                PreferenceManager.getDefaultSharedPreferences(context)
                                                    .edit()
                                                    .putString(LAST_BANNER_ID_KEY, bannerId)
                                                    .apply();
                                            }
                                        });
                                }
                            }

                            bannerImage.setOnClickListener(new View.OnClickListener() {
                                @Override
                                public void onClick(View v) {
                                    if (!isImageLoaded || isClosing) return;
                                    Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(bannerUrl));
                                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                                    context.startActivity(intent);
                                    dismissBannerWithAnimation();
                                }
                            });

                            closeButton.setOnClickListener(new View.OnClickListener() {
                                @Override
                                public void onClick(View v) {
                                    if (!isImageLoaded || isClosing) return;
                                    dismissBannerWithAnimation();
                                }
                            });
                        }
                    });

                } catch (Exception e) {
                    Log.e("arzmod-app-module", "Error showing banner", e);
                }
            }
        }).start();
    }

    private static void showBannerWithAnimation(final View bannerImage, final View closeButton) {
        AnimationSet bannerAnimation = new AnimationSet(true);
    
        ScaleAnimation scaleAnimation = new ScaleAnimation(
            0.8f, 1f, 0.8f, 1f,
            Animation.RELATIVE_TO_SELF, 0.5f,
            Animation.RELATIVE_TO_SELF, 0.5f
        );
        scaleAnimation.setDuration(ANIMATION_DURATION);
    
        AlphaAnimation alphaAnimation = new AlphaAnimation(0f, 1f);
        alphaAnimation.setDuration(ANIMATION_DURATION);
        
        bannerAnimation.addAnimation(scaleAnimation);
        bannerAnimation.addAnimation(alphaAnimation);
        
        bannerImage.startAnimation(bannerAnimation);
        bannerImage.setAlpha(1f);

        AlphaAnimation closeButtonAnimation = new AlphaAnimation(0f, 1f);
        closeButtonAnimation.setDuration(ANIMATION_DURATION);
        closeButton.startAnimation(closeButtonAnimation);
        closeButton.setAlpha(1f);
    }

    private static void dismissBannerWithAnimation() {
        if (bannerPopup == null || !bannerPopup.isShowing() || isClosing) return;
        isClosing = true;

        View contentView = bannerPopup.getContentView();
        if (contentView == null) {
            bannerPopup.dismiss();
            return;
        }

        timeoutHandler.removeCallbacks(timeoutRunnable);

        ViewGroup container = (ViewGroup) contentView;
        if (container.getChildCount() > 0) {
            ViewGroup bannerContainer = (ViewGroup) container.getChildAt(0);
            if (bannerContainer != null && bannerContainer.getChildCount() > 0) {
                View bannerImage = bannerContainer.getChildAt(0);
                if (bannerImage != null) {
                    AnimationSet bannerAnimation = new AnimationSet(true);
                    
                    ScaleAnimation scaleAnimation = new ScaleAnimation(
                        1f, 0.8f, 1f, 0.8f,
                        Animation.RELATIVE_TO_SELF, 0.5f,
                        Animation.RELATIVE_TO_SELF, 0.5f
                    );
                    scaleAnimation.setDuration(ANIMATION_DURATION);
                    
                    AlphaAnimation alphaAnimation = new AlphaAnimation(1f, 0f);
                    alphaAnimation.setDuration(ANIMATION_DURATION);
                    
                    bannerAnimation.addAnimation(scaleAnimation);
                    bannerAnimation.addAnimation(alphaAnimation);
                    
                    bannerAnimation.setAnimationListener(new Animation.AnimationListener() {
                        @Override
                        public void onAnimationStart(Animation animation) {}

                        @Override
                        public void onAnimationEnd(Animation animation) {
                            if (bannerPopup != null) {
                                bannerPopup.dismiss();
                            }
                        }

                        @Override
                        public void onAnimationRepeat(Animation animation) {}
                    });
                    
                    bannerImage.startAnimation(bannerAnimation);
                }

                if (bannerContainer.getChildCount() > 1) {
                    View closeButton = bannerContainer.getChildAt(1);
                    if (closeButton != null) {
                        AlphaAnimation closeButtonAnimation = new AlphaAnimation(1f, 0f);
                        closeButtonAnimation.setDuration(ANIMATION_DURATION);
                        closeButton.startAnimation(closeButtonAnimation);
                    }
                }
            }
        }
    }

    public static void gitCheckUpdate() {
        Context context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-app-module", "Context is null");
            return;
        }
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    String gitUpdateUrl = null;
                    try {
                        gitUpdateUrl = (String) BuildConfig.class.getField("GIT_UPDATE_URL").get(null);
                    } catch (NoSuchFieldException | IllegalAccessException e) {
                        Log.e("arzmod-app-module", "Why this method called but GIT_UPDATE_URL doesn't exists in BuildConfig?");
                        return;
                    }

                    if (gitUpdateUrl != null && !gitUpdateUrl.isEmpty()) {
                        URL url = new URL(gitUpdateUrl);
                    
                        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                        connection.setRequestProperty("Accept", "application/vnd.github.v3+json");
                        connection.setDoInput(true);
                        connection.connect();

                        InputStream input = connection.getInputStream();
                        String jsonResponse = new java.util.Scanner(input).useDelimiter("\\A").next();
                        input.close();

                        JSONObject json = new JSONObject(jsonResponse);
                        String latestVersion = json.getString("tag_name").replace("v", "");
                        final String releaseUrl = json.getString("html_url");
                        
                        int currentVersion = BuildConfig.VERSION_CODE;
                        int newVersion = Integer.parseInt(latestVersion);

                        if (newVersion > currentVersion) {
                            new Handler(Looper.getMainLooper()).post(new Runnable() {
                                @Override
                                public void run() {
                                    if (!(context instanceof Activity)) return;
                                    Activity activity = (Activity) context;
                                    if (activity.isFinishing() || activity.isDestroyed()) return;

                                    AlertDialog.Builder builder = new AlertDialog.Builder(activity);
                                    builder.setTitle("Доступно обновление");
                                    builder.setMessage("Доступна новая версия лаунчера: " + newVersion + "\n\nРекомендуется обновить приложение для корректной работы.");

                                    builder.setPositiveButton("Обновить", new DialogInterface.OnClickListener() {
                                        @Override
                                        public void onClick(DialogInterface dialog, int which) {
                                            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(releaseUrl));
                                            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                                            context.startActivity(intent);
                                        }
                                    });

                                    builder.setNegativeButton("Пропустить", new DialogInterface.OnClickListener() {
                                        @Override
                                        public void onClick(DialogInterface dialog, int which) {
                                            dialog.dismiss();
                                        }
                                    });

                                    builder.setCancelable(false);
                                    builder.show();
                                }
                            });
                        } else {
                            Log.e("arzmod-app-module", "Why this method called but GIT_UPDATE_URL doesn't exists in BuildConfig?");
                            return;
                        }
                    }
                } catch (Exception e) {
                    Log.e("arzmod-app-module", "Error checking for updates", e);
                }

                try {
                    Log.d("arzmod-app-module", "Starting files extraction...");
                    InputStream zipStream = context.getAssets().open("arzmod/files.zip");
                    java.util.zip.ZipInputStream zis = new java.util.zip.ZipInputStream(zipStream);
                    java.util.zip.ZipEntry entry;

                    while ((entry = zis.getNextEntry()) != null) {
                        String entryName = entry.getName();
                        if (entry.isDirectory()) continue;

                        if (entryName.startsWith("data/") || entryName.startsWith("media/")) {
                            String[] parts = entryName.split("/");
                            if (parts.length >= 3) {
                                String packageName = parts[1];
                                File targetDir = null;
                                
                                if (entryName.startsWith("data/")) {
                                    String relativePath = entryName.substring(5 + packageName.length() + 1);
                                    targetDir = new File(context.getExternalFilesDir(null).getParentFile(), relativePath);
                                } else if (entryName.startsWith("media/")) {
                                    String relativePath = entryName.substring(6 + packageName.length() + 1);
                                    targetDir = new File(context.getExternalMediaDirs()[0], relativePath);
                                }

                                if (targetDir != null) {
                                    boolean shouldExtract = true;
                                    
                                    if (targetDir.exists() && SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_SKIP_VERIFY)) {
                                        shouldExtract = false;
                                        Log.d("arzmod-app-module", "Skipping rewrite file: " + targetDir.getAbsolutePath());
                                    }

                                    if (shouldExtract) {
                                        Log.d("arzmod-app-module", "Extracting: " + entryName + " -> " + targetDir.getAbsolutePath());

                                        try {
                                            targetDir.getParentFile().mkdirs();
                                            java.io.FileOutputStream fos = new java.io.FileOutputStream(targetDir);
                                            byte[] buffer = new byte[1024];
                                            int len;
                                            while ((len = zis.read(buffer)) > 0) {
                                                fos.write(buffer, 0, len);
                                            }
                                            fos.close();
                                        } catch (Exception e) {
                                            Log.e("arzmod-app-module", "Error extracting file: " + entryName, e);
                                        }
                                    }
                                }
                            }
                        }
                        zis.closeEntry();
                    }
                    zis.close();
                    Log.d("arzmod-app-module", "Files extraction completed");
                } catch (Exception e) {
                    Log.e("arzmod-app-module", "Error extracting files", e);
                }
            }
        }).start();
    }
}