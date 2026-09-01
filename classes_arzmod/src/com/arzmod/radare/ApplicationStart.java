package com.arzmod.radare;

import com.arzmod.radare.AppContext;
import com.arzmod.radare.FirebaseAdd;
import com.arzmod.radare.AppAds;
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
import org.json.JSONArray;
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
    private static final String BANNER_API_URL_FALLBACK = "https://raw.githubusercontent.com/" + BuildConfig.GIT_OWNER + "/" + BuildConfig.GIT_REPO + "/refs/heads/main/configs/banner";
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

    public boolean handleLaunchIntent(Intent intent) {
        if (intent == null) return false;

        String ip = intent.getStringExtra("ip");
        String port = intent.getStringExtra("port");
        String nickname = intent.getStringExtra("nickname");
        String password = intent.getStringExtra("password");
        int serverId = intent.getIntExtra("server_id", -1);
        int serverNumber = intent.getIntExtra("server_number", -1);
        boolean runGame = intent.getBooleanExtra("run_game", false);

        if (ip == null && intent.getData() != null) {
            Uri data = intent.getData();
            String scheme = data.getScheme();
            if ("samp".equals(scheme) || "crmp".equals(scheme)) {
                ip = data.getHost();
                port = data.getPort() > 0 ? String.valueOf(data.getPort()) : null;
                if (nickname == null) nickname = data.getQueryParameter("nickname");
                if (password == null) password = data.getQueryParameter("password");
                runGame = true;
            }
        }

        if (ip == null && serverId < 0 && !runGame) return false;

        if (port == null) port = "7777";

        Log.d("arzmod-app-module", "Launch intent: ip=" + ip + " port=" + port
            + " nickname=" + nickname + " serverId=" + serverId
            + " serverNumber=" + serverNumber + " runGame=" + runGame);

        if (serverId >= 0 && serverNumber >= 0) {
            connectToOfficialServer(serverId, serverNumber, nickname, password);
        } else if (ip != null) {
            connectToServer(ip, port, nickname, password);
        } else if (runGame) {
            connectToServer("lastplayed", port, nickname, password);
        }

        return true;
    }

    public void connectToOfficialServer(int serverId, int serverNumber, String nickname, String password) {
        long currentTime = SystemClock.elapsedRealtime();
        if (currentTime - lastStartGameTime < MIN_START_INTERVAL) return;
        lastStartGameTime = currentTime;

        try {
            Activity activity = AppContext.getGTASAActivity();
            if (activity != null && !activity.isFinishing() && !activity.isDestroyed()) {
                activity.finish();
            }
        } catch (Exception e) {
            Log.e("arzmod-app-module", "Error finishing activity: " + e.getMessage());
        }

        try {
            File externalDir = context.getExternalFilesDir(null);
            File sampDir = new File(externalDir, "SAMP");
            sampDir.mkdirs();

            File settingsFile = new File(sampDir, "settings.json");
            if (settingsFile.exists()) settingsFile.delete();
            settingsFile.createNewFile();

            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
            boolean headMoving = prefs.getBoolean("head_moving", false);

            JSONObject settings = new JSONObject();
            JSONObject server = new JSONObject()
                .put("id", serverId)
                .put("serverid", serverNumber);
            JSONObject client = new JSONObject()
                .put("server", server);

            JSONObject launcher = new JSONObject();
            launcher.put("nickname", nickname != null ? nickname : "Player");
            launcher.put("head_moving", headMoving);
            try {
                launcher.put("chat_pagesize", ConnectionHolder.INSTANCE.getSettingsData().getPageSize());
                launcher.put("chat_fontsize", ConnectionHolder.INSTANCE.getSettingsData().getChatFontSize());
                launcher.put("chat_print_timestamp", ConnectionHolder.INSTANCE.getSettingsData().getShowChatTime());
                launcher.put("streamer_mode", ConnectionHolder.INSTANCE.getSettingsData().getStreamerMode());
            } catch (Exception e) {
                Log.w("arzmod-app-module", "ConnectionHolder not available, using defaults");
            }

            if (password != null && !password.isEmpty()) {
                JSONObject test = new JSONObject()
                    .put("pass", password);
                client.put("test", test);
            }

            settings.put("client", client).put("launcher", launcher);

            try (BufferedWriter writer = new BufferedWriter(new FileWriter(settingsFile))) {
                writer.write(settings.toString());
            }
            context.startActivity(new Intent(context, GTASA.class));
        } catch (Exception e) {
            Log.e("arzmod-app-module", "Error connecting to official server", e);
        }
    }

    public void connectToServer(String ip, String port, String nickname, String password) {
        long currentTime = SystemClock.elapsedRealtime();
        if (currentTime - lastStartGameTime >= MIN_START_INTERVAL) {
            lastStartGameTime = currentTime;

            try {
                Activity activity = AppContext.getGTASAActivity();
                if (activity != null && !activity.isFinishing() && !activity.isDestroyed()) {
                    activity.finish();
                }
            } catch (Exception e) {
                Log.e("AppContext", "Error finishing activity: " + e.getMessage());
            }

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

    public static void launcherStart() {
        Context context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-app-module", "Context is null");
            return;
        }

        Toast.makeText(context, Build.CPU_ABI + " " + BuildConfig.VERSION_NAME + " " + (BuildConfig.GIT_BUILD  ? "arzmod_community" : "arzmod"), Toast.LENGTH_SHORT).show();
        AppAds.checkInitialization(!SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_DEV_HUNGRY));
    }

    public static void showBanner() {
        Context context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-app-module", "context is null");
            return;
        }
        final Activity activity = AppContext.getActivity();
        if (activity == null) {
            Log.e("arzmod-app-module", "activity is null");
            return;
        }
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    JSONObject json = null;
                    try {
                        URL url = new URL(BANNER_API_URL);
                        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                        connection.setDoInput(true);
                        connection.connect();
                        InputStream input = connection.getInputStream();
                        String jsonResponse = new java.util.Scanner(input).useDelimiter("\\A").next();
                        input.close();
                        json = new JSONObject(jsonResponse);
                    } catch (Exception e) {
                        Log.e("arzmod-app-module", "Primary banner URL failed, trying fallback", e);
                    }
                    if (json == null || json.length() == 0) {
                        try {
                            URL url = new URL(BANNER_API_URL_FALLBACK);
                            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                            connection.setDoInput(true);
                            connection.connect();
                            InputStream input = connection.getInputStream();
                            String jsonResponse = new java.util.Scanner(input).useDelimiter("\\A").next();
                            input.close();
                            json = new JSONObject(jsonResponse);
                        } catch (Exception e2) {
                            Log.e("arzmod-app-module", "Fallback banner URL also failed", e2);
                        }
                    }
                    if (json == null || json.length() == 0) {
                        return;
                    }

                    final String bannerId = json.getString("id");
                    final int width = json.getInt("width");
                    final int height = json.getInt("height");
                    final String imageUrl = json.getString("imageUrl");
                    final String bannerUrl = json.getString("url");
                    final boolean isActive = json.getBoolean("isActive");
                    final String title = json.optString("title", "");

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
                            bannerContainer.setId(View.generateViewId());
                            RelativeLayout.LayoutParams containerParams = new RelativeLayout.LayoutParams(
                                width, height
                            );
                            containerParams.addRule(RelativeLayout.CENTER_IN_PARENT);
                            bannerContainer.setLayoutParams(containerParams);
                            
                            final TextView titleTextView;
                            if (title != null && !title.isEmpty()) {
                                OutlinedTextView titleView = new OutlinedTextView(context);
                                titleView.setText(title);
                                titleView.setTextColor(Color.WHITE);
                                titleView.setTextSize(18);
                                titleView.setTypeface(null, android.graphics.Typeface.BOLD);
                                titleView.setGravity(Gravity.CENTER);
                                titleView.setPadding(20, 20, 20, 20);
                                titleView.setStroke(Color.BLACK, 6f);
                                
                                RelativeLayout.LayoutParams titleParams = new RelativeLayout.LayoutParams(
                                    ViewGroup.LayoutParams.WRAP_CONTENT,
                                    ViewGroup.LayoutParams.WRAP_CONTENT
                                );
                                titleParams.addRule(RelativeLayout.CENTER_HORIZONTAL);
                                titleParams.addRule(RelativeLayout.ABOVE, bannerContainer.getId());
                                titleParams.bottomMargin = 20;
                                titleView.setLayoutParams(titleParams);
                                titleView.setAlpha(0f);
                                titleTextView = titleView;
                            } else {
                                titleTextView = null;
                            }

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
                            
                            if (titleTextView != null) {
                                titleTextView.setId(View.generateViewId());
                                bannerLayout.addView(titleTextView);
                            }
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
                                                
                                                showBannerWithAnimation(bannerImage, closeButton, titleTextView);
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
                                                
                                                showBannerWithAnimation(bannerImage, closeButton, titleTextView);

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

    private static void showBannerWithAnimation(final View bannerImage, final View closeButton, final View titleTextView) {
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
        
        if (titleTextView != null) {
            AlphaAnimation titleAlphaAnimation = new AlphaAnimation(0f, 1f);
            titleAlphaAnimation.setDuration(ANIMATION_DURATION);
            titleTextView.startAnimation(titleAlphaAnimation);
            titleTextView.setAlpha(1f);
        }
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
        if (container.getChildCount() == 0) {
            if (bannerPopup != null) {
                bannerPopup.dismiss();
            }
            return;
        }
        
        ViewGroup bannerContainer = null;
        View titleTextView = null;
        
        for (int i = 0; i < container.getChildCount(); i++) {
            View child = container.getChildAt(i);
            if (child instanceof ViewGroup) {
                bannerContainer = (ViewGroup) child;
            } else if (child instanceof TextView) {
                titleTextView = child;
            }
        }
        
        if (bannerContainer == null) {
            if (bannerPopup != null) {
                bannerPopup.dismiss();
            }
            return;
        }
        
        if (bannerContainer.getChildCount() > 0) {
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
        
        if (titleTextView != null) {
            AlphaAnimation titleAnimation = new AlphaAnimation(1f, 0f);
            titleAnimation.setDuration(ANIMATION_DURATION);
            titleTextView.startAnimation(titleAnimation);
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
                    String gitUpdateUrl = "https://api.github.com/repos/" + BuildConfig.GIT_OWNER + "/" + BuildConfig.GIT_REPO + "/releases";

                    if (gitUpdateUrl != null && !gitUpdateUrl.isEmpty()) {
                        URL url = new URL(gitUpdateUrl);
                    
                        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                        connection.setRequestProperty("Accept", "application/vnd.github.v3+json");
                        connection.setDoInput(true);
                        connection.connect();

                        InputStream input = connection.getInputStream();
                        String jsonResponse = new java.util.Scanner(input).useDelimiter("\\A").next();
                        input.close();

                        JSONArray releasesArray = new JSONArray(jsonResponse);
                        
                        String clientType = BuildConfig.IS_ARIZONA ? "arizona" : "rodina";
                        String arch = Build.CPU_ABI.equals("arm64-v8a") ? "x64" : "x32";
                        String targetApkName = "app-" + clientType + "-" + arch + "-patched.apk";
                        
                        Log.d("arzmod-app-module", "Looking for APK: " + targetApkName);
                        
                        JSONObject foundRelease = null;
                        String latestVersion = "";
                        String releaseUrl = "";
                        
                        for (int i = 0; i < releasesArray.length(); i++) {
                            JSONObject release = releasesArray.getJSONObject(i);
                            JSONArray assets = release.getJSONArray("assets");
                            
                            boolean hasTargetApk = false;
                            for (int j = 0; j < assets.length(); j++) {
                                JSONObject asset = assets.getJSONObject(j);
                                String assetName = asset.getString("name");
                                if (assetName.equals(targetApkName)) {
                                    hasTargetApk = true;
                                    break;
                                }
                            }
                            
                            if (hasTargetApk) {
                                foundRelease = release;
                                latestVersion = release.getString("tag_name").replace("v", "");
                                releaseUrl = release.getString("html_url");
                                Log.d("arzmod-app-module", "Found suitable release: " + latestVersion);
                                break;
                            }
                        }
                        
                        if (foundRelease == null) {
                            Log.w("arzmod-app-module", "No suitable release found for APK: " + targetApkName);
                            return;
                        }
                        
                        boolean isPrerelease = foundRelease.optBoolean("prerelease", false);
                        
                        int currentVersion = BuildConfig.VERSION_CODE;
                        int newVersion = Integer.parseInt(latestVersion);

                        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
                        String lastShownVersion = prefs.getString("last_shown_prerelease", "");
                        boolean hasShownPrerelease = !lastShownVersion.isEmpty() && lastShownVersion.equals(latestVersion);

                        if (!isPrerelease && hasShownPrerelease) {
                            prefs.edit().remove("last_shown_prerelease").apply();
                            hasShownPrerelease = false;
                        }

                        boolean shouldShowUpdate = !isPrerelease || (isPrerelease && !hasShownPrerelease);

                        if (newVersion != currentVersion && shouldShowUpdate) {
                            final boolean finalIsPrerelease = isPrerelease;
                            final String finalLatestVersion = latestVersion;
                            final SharedPreferences finalPrefs = prefs;
                            final String finalReleaseUrl = releaseUrl;
                            
                            new Handler(Looper.getMainLooper()).post(new Runnable() {
                                @Override
                                public void run() {
                                    Activity activity = AppContext.getActivity();
                                    if (activity == null) {
                                        Log.e("arzmod-app-module", "Activity is null (gitCheckUpdate)");
                                        return;
                                    }
                                    if (activity.isFinishing() || activity.isDestroyed()) 
                                    {
                                        Log.e("arzmod-app-module", "Activity is finishing or destroyed (gitCheckUpdate)");
                                        return;
                                    }

                                    AlertDialog.Builder builder = new AlertDialog.Builder(activity);
                                    builder.setTitle("Доступно обновление");

                                    StringBuilder message = new StringBuilder();
                                    if (finalIsPrerelease) message.append("Доступно автоматическое обновление лаунчера: ").append(newVersion);
                                    else message.append("Доступна новая версия лаунчера: ").append(newVersion);
                                    if (newVersion < currentVersion) {
                                        message.append("\n\nТекущая версия была удалена. Рекомендуется вернуться на старую версию. (ничего удалять/переустанавливать не надо, просто установить новый APK)");
                                    } else {
                                        if (finalIsPrerelease) message.append("\n\nВерсия не отмечена как стабильная (не протестирована, автоматическое обновление), а значит может содержать баги или вовсе не работать. Если вы очень хотите обновиться - попробуйте, на старую версию можно будет откатиться в любое время, установив с прошлого релиза. (обновлением без переустановки!)");
                                        else message.append("\n\nРекомендуется обновить приложение для корректной работы.");
                                    }
                                    builder.setMessage(message.toString());

                                    builder.setPositiveButton("Установить", new DialogInterface.OnClickListener() {
                                        @Override
                                        public void onClick(DialogInterface dialog, int which) {
                                            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(finalReleaseUrl));
                                            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                                            activity.startActivity(intent);
                                        }
                                    });

                                    builder.setNegativeButton("Пропустить", new DialogInterface.OnClickListener() {
                                        @Override
                                        public void onClick(DialogInterface dialog, int which) {
                                            dialog.dismiss();
                                        }
                                    });

                                    builder.setCancelable(false);
                                    
                                    if (finalIsPrerelease) {
                                        finalPrefs.edit().putString("last_shown_prerelease", finalLatestVersion).apply();
                                    }
                                    
                                    builder.show();
                                }
                            });
                        } else {
                            Log.i("arzmod-app-module", "No update available. Your app version is latest.");
                        }
                    }
                } catch (Exception e) {
                    Log.e("arzmod-app-module", "Error checking for updates", e);
                }
            }
        }).start();
    }

    public static void checkLocalFilesUpdate() {
        FilesUpdateManager.start();
    }

    public static class OutlinedTextView extends android.widget.TextView {
        private int strokeColor = Color.BLACK;
        private float strokeWidth = 4f;

        public OutlinedTextView(Context context) {
            super(context);
            setWillNotDraw(false);
        }

        public void setStroke(int color, float width) {
            this.strokeColor = color;
            this.strokeWidth = width;
            invalidate();
        }

        @Override
        protected void onDraw(android.graphics.Canvas canvas) {
            android.graphics.Paint paint = getPaint();
            int originalColor = getCurrentTextColor();

            paint.setStyle(android.graphics.Paint.Style.STROKE);
            paint.setStrokeWidth(strokeWidth);
            setTextColor(strokeColor);
            super.onDraw(canvas);

            paint.setStyle(android.graphics.Paint.Style.FILL);
            setTextColor(originalColor);
            super.onDraw(canvas);
        }
    }
}