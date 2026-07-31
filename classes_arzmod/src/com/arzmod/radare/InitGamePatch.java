package com.arzmod.radare;

import android.content.res.AssetManager;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import java.util.UUID;
import java.util.Objects;
import java.util.HashMap;
import java.util.Map;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.StandardCopyOption;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.InputStream;
import android.content.Context;
import android.content.SharedPreferences;
import com.arzmod.radare.Main;
import com.arzmod.radare.SettingsPatch;
import com.arzmod.radare.SettingsPatch.ChatPosition;
import com.arzmod.radare.AppContext;
import com.arizona.game.GTASAInternal;
import com.google.firebase.crashlytics.FirebaseCrashlytics;
import com.arizona.game.GTASA;
import com.arizona.game.BuildConfig;
import com.arizona.launcher.util.UtilsKt;
import ru.mrlargha.commonui.core.UIElementID;
import ru.mrlargha.commonui.elements.authorization.presentation.screen.RegistrationVideoBackground;
import com.miami.game.feature.download.dialog.ui.connection.ConnectionHolder;
import com.miami.game.core.connection.resolver.FirebaseConfigHelper;
import androidx.constraintlayout.widget.ConstraintLayout;
import android.widget.LinearLayout;
import androidx.preference.PreferenceManager;
import org.json.JSONObject;
import android.widget.TextView;
import java.lang.reflect.Field;
import android.app.Activity;
import java.lang.reflect.Method;
import java.lang.NoSuchFieldException;
import com.arzmod.radare.DebugOverlay;
import com.arzmod.radare.GamePatches;
import com.arizona.launcher.model.settings.SettingsConstants;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class InitGamePatch {
    private static Context context;
    private static final String ACTUAL_VERSION_PREF_KEY = "actual_launcher_version";
    private static String CONNECT_TAG = "release";
    private static String ACTUAL_VERSION = BuildConfig.VERSION_NAME;

    public native static void installPacketsFix();
    public native static void setVersionString(String string);
    public native static void setVersion(String version);
    public native static void versionFix();
    public native static void setChatPosition(float pos_x, float pos_y);
    public native static void setActivity(Object activity);
    public native static void setHudType(int hud, int radar);

    private static boolean isAssetExists(Context context, String fileName) {
        try {
            context.getAssets().open("arzmod/" + fileName).close();
            return true;
        } catch (IOException e) {
            return false;
        }
    }

    public static void copyFileFromAssets(Context context, String fileName, String outputPath) throws IOException {
        AssetManager assetManager = context.getAssets();

        String[] assets;
        try {
            assets = assetManager.list("arzmod/" + fileName);
            if (assets != null && assets.length > 0) {
                copyFolderFromAssets(context, "arzmod/" + fileName, new File(outputPath));
            } else {
                copySingleFileFromAssets(context, "arzmod/" + fileName, new File(outputPath));
            }
        } catch (IOException e) {
            copySingleFileFromAssets(context, "arzmod/" + fileName, new File(outputPath));
        }
    }

    private static void copySingleFileFromAssets(Context context, String assetPath, File outFile) throws IOException {
        InputStream inputStream = context.getAssets().open(assetPath);

        if (outFile.exists()) {
            deleteRecursively(outFile);
        }

        File parentDir = outFile.getParentFile();
        if (parentDir != null && !parentDir.exists()) {
            Files.createDirectories(parentDir.toPath());
        }

        try (FileOutputStream outputStream = new FileOutputStream(outFile)) {
            byte[] buffer = new byte[1024];
            int length;
            while ((length = inputStream.read(buffer)) > 0) {
                outputStream.write(buffer, 0, length);
            }
        } finally {
            inputStream.close();
        }
    }

    private static void copyFolderFromAssets(Context context, String assetFolderPath, File outputFolder) throws IOException {
        AssetManager assetManager = context.getAssets();
        String[] assets = assetManager.list(assetFolderPath);

        if (outputFolder.exists()) {
            deleteRecursively(outputFolder);
        }

        if (!outputFolder.exists() && !outputFolder.mkdirs()) {
            throw new IOException("Не удалось создать папку: " + outputFolder.getAbsolutePath());
        }

        if (assets != null) {
            for (String asset : assets) {
                String assetPath = assetFolderPath + "/" + asset;
                File outFile = new File(outputFolder, asset);

                if (assetManager.list(assetPath).length > 0) {
                    copyFolderFromAssets(context, assetPath, outFile);
                } else {
                    copySingleFileFromAssets(context, assetPath, outFile);
                }
            }
        }
    }

    private static void deleteRecursively(File file) throws IOException {
        if (file.isDirectory()) {
            File[] files = file.listFiles();
            if (files != null) {
                for (File child : files) {
                    deleteRecursively(child);
                }
            }
        }
        if (!file.delete()) {
            throw new IOException("Не удалось удалить файл или папку: " + file.getAbsolutePath());
        }
    }

    public static boolean isLibraryLoaded(String libName) {
        try {
            BufferedReader reader = new BufferedReader(new FileReader("/proc/self/maps"));
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.contains("lib" + libName + ".so")) {
                    reader.close();
                    return true;
                }
            }
            reader.close();
        } catch (Exception e) {
            Log.e("arzmod-initgame-module", "Error checking library: " + e.getMessage());
        }
        return false;
    }

    public static long getLibraryBase(String libName) {
        try {
            BufferedReader reader = new BufferedReader(new FileReader("/proc/self/maps"));
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.contains("lib" + libName + ".so")) {
                    String[] parts = line.split("\\s+");
                    if (parts.length > 0) {
                        String addressRange = parts[0];
                        String[] addresses = addressRange.split("-");
                        if (addresses.length == 2) {
                            long baseAddress = Long.parseLong(addresses[0], 16);
                            reader.close();
                            return baseAddress;
                        }
                    }
                }
            }
            reader.close();
        } catch (Exception e) {
            Log.e("arzmod-initgame-module", "Error getting library base: " + e.getMessage());
        }
        return 0;
    }

    public static void loadLib(String libName) {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-initgame-module", "Context is null (loadLib)");
            return;
        }

        String nativeLibDir = context.getApplicationInfo().nativeLibraryDir;
        String fullLibPath = nativeLibDir + "/lib" + libName + ".so";

        // if (isLibraryLoaded(libName)) {
        //     Log.d("arzmod-initgame-module", "Library " + libName + " is already loaded");
        //     return;
        // }

        Log.d("arzmod-initgame-module", "Loading library " + libName + " from path: " + fullLibPath);
        GTASAInternal.loadLibraryFromPath(fullLibPath);
        
        long baseAddress = getLibraryBase(libName);
        if (baseAddress != 0) {
            Log.d("arzmod-initgame-module", "Library " + libName + " loaded at base address: 0x" + Long.toHexString(baseAddress));
        } else {
            Log.w("arzmod-initgame-module", "Could not get base address for library " + libName);
        }
    }

    public static void firstTimePatches(Activity activity) {
        try {
            context = AppContext.getContext();
            if (context == null) {
                Log.e("arzmod-initgame-module", "Context is null (firstTimePatches)");
                return;
            }
            
            Activity targetActivity = activity;
            if (targetActivity == null) {
                if (context instanceof Activity) {
                    targetActivity = (Activity) context;
                } else {
                    try {
                        Class<?> activityThreadClass = Class.forName("android.app.ActivityThread");
                        Object activityThread = activityThreadClass.getMethod("currentActivityThread").invoke(null);
                        Object activityRecord = activityThreadClass.getMethod("getActivities").invoke(activityThread);
                        if (activityRecord instanceof java.util.List && !((java.util.List<?>) activityRecord).isEmpty()) {
                            Object record = ((java.util.List<?>) activityRecord).get(0);
                            Field activityField = record.getClass().getDeclaredField("activity");
                            activityField.setAccessible(true);
                            targetActivity = (Activity) activityField.get(record);
                        }
                    } catch (Exception e) {
                        Log.w("arzmod-initgame-module", "Could not get Activity: " + e.getMessage());
                    }
                }
            }
            
            SharedPreferences defaultSharedPreferences = PreferenceManager.getDefaultSharedPreferences(context);
            String packageName = context.getPackageName();
            String loadedProfile = "";
            
            if (defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0) == 0) {
                SharedPreferences.Editor editor = defaultSharedPreferences.edit();
                editor.putInt(SettingsPatch.GAME_VERSION, BuildConfig.VERSION_CODE);
                editor.apply();
            } else {
                int currentVersion = defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0);
                if (!GameVersions.isVersionSupported(currentVersion)) {
                    SharedPreferences.Editor editor = defaultSharedPreferences.edit();
                    editor.putInt(SettingsPatch.GAME_VERSION, GameVersions.getLatestVersion());
                    editor.apply();
                }
            }
            try {
                File debugProfile = new File(Environment.getExternalStorageDirectory().getAbsolutePath() + "/Android/media/" + packageName + "/monetloader/compat/debug.json");
                String outputFile = Environment.getExternalStorageDirectory().getAbsolutePath() + "/Android/media/" + packageName + "/monetloader/compat/profile.json";
                String assetFile = "profile"+ (defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, BuildConfig.VERSION_CODE) != BuildConfig.VERSION_CODE ? defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0) : "")+".json";
                Log.d("arzmod-initgame-module", "Loading profile ver: " + (defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, BuildConfig.VERSION_CODE) != BuildConfig.VERSION_CODE ? defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0) : "") + ", from file: " + assetFile + ", gameArchiveCode: " + defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, BuildConfig.VERSION_CODE));

                if(debugProfile.exists())
                {
                    Files.copy(debugProfile.toPath(), new File(outputFile).toPath(), StandardCopyOption.REPLACE_EXISTING);
                    Log.d("arzmod-initgame-module", "loaded debug profile");
                    loadedProfile = "debug.json";
                } else if (isAssetExists(context, assetFile)) {
                    copyFileFromAssets(context, assetFile, outputFile);
                    loadedProfile = assetFile;
                } else {
                    copyFileFromAssets(context, "profile.json", outputFile);
                    loadedProfile = "profile.json";
                    SharedPreferences.Editor editor = defaultSharedPreferences.edit();
                    editor.putInt(SettingsPatch.GAME_VERSION, BuildConfig.VERSION_CODE);
                    editor.apply();
                    Log.d("arzmod-initgame-module", "Loading default profile");
                }
                Log.d("arzmod-initgame-module", "Loaded profile: " + loadedProfile);
            } catch(IOException | SecurityException e) {
                e.printStackTrace();
                Main.moduleDialog("Ошибка при копировании файла: " + e.getMessage() + "\n\nПопробуйте вручную создать папки если их не существует. Если папка compat существует, пересоздайте её через любой проводник");
                Log.e("arzmod-initgame-module", "Ошибка при копировании файла: " + e.getMessage());
            }

            boolean isMonetloaderWork = SettingsPatch.getSettingsKeyValue(SettingsPatch.MONETLOADER_WORK);
            String cpu = Build.CPU_ABI;

            if (Objects.equals(cpu, "arm64-v8a")) {
                loadLib("SCAnd");
            } else {
                loadLib("ImmEmulatorJ");
            }
            loadLib("GTASA");
            if (Objects.equals(cpu, "arm64-v8a")) {
                if(isCustomServer()) setServer(0, 1);
                loadLib("samp");
                loadNativeMod(targetActivity);
                
                if(isMonetloaderWork)
                {
                    try {
                        InitGamePatch.setVersion(String.valueOf(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0)));
                        InitGamePatch.versionFix();
                    } catch (LinkageError e) {
                        Log.w("arzmod-initgame-module", "Unable to call native method versionFix. Using profile system...", e);
                    } 
                    loadLib("monetloader");
                }
            } else {
                if(isCustomServer()) setServer(0, 0);
                loadLib("samp" + (defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, BuildConfig.VERSION_CODE) != BuildConfig.VERSION_CODE ? defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0) : ""));
                loadNativeMod(targetActivity);
                
                if(isMonetloaderWork)
                {
                    if(loadedProfile.equals("profile.json") || loadedProfile.isEmpty())
                    {
                        try {
                            InitGamePatch.setVersion(String.valueOf(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0)));
                            InitGamePatch.versionFix();
                        } catch (LinkageError e) {
                            Log.w("arzmod-initgame-module", "Unable to call native method versionFix. Using profile system...", e);
                        } 
                    }
                    loadLib("monetloader");
                    loadLib("AML");
                }
            }
            
            
            if (Objects.equals(cpu, "arm64-v8a")) {
                loadLib("bass");
                loadLib("bass_fx");
                loadLib("bass_ssl");
            }
            
            if (!Objects.equals(cpu, "arm64-v8a"))
            {
                try {
                    GTASA.InitModloaderConfig(defaultSharedPreferences.getInt(SettingsPatch.MODLOADER_STATE, 0));
                } catch (LinkageError e) {
                    Log.w("arzmod-initgame-module", "Unable to call native method InitModloaderConfig", e);
                } 
            }

            UtilsKt.initZip(context);

            if(BuildConfig.ARZMOD_DEBUG)
            {
                AppContext.getGTASAActivity(new AppContext.GTASAActivityCallback() {
                    @Override
                    public void onResult(Activity activity) {
                        Main.moduleDialog("last repatch at: " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(new Date(BuildConfig.BUILD_TIME)));
                        //int gameMonitorTimer = Timers.startTimer(1000, new Timers.TimerCallback() {
                        //    @Override
                        //    public void onTimerTick(int timerId, int tickCount, long currentTime) {
                        //        DebugOverlay.show(activity, "ARZMOD-DEBUG"
                        //        + " | version: " + BuildConfig.VERSION_NAME 
                        //        + " | code: " + BuildConfig.VERSION_CODE 
                        //        + " | commit: " + BuildConfig.GIT_HASH.substring(0, 7) 
                        //        + " | core rebuild: " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(new Date(BuildConfig.BUILD_TIME)) 
                        //       + " | arch: " + Build.CPU_ABI 
                        //        + " | time: " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(new Date(currentTime)));
                        //    }
                        //});
                    }
                });
            }
            AppAds.checkInitialization(false);

            GamePatches.onSetConnectState("Подключение к игре...");
            Log.d("arzmod-initgame-module", "game started. by ARZMOD (arzmod.com) & Community (t.me/cleodis)");
        } catch (Exception e) {
            e.printStackTrace();
            Log.e("arzmod-initgame-module", "Public firstTimePatches has errors");
        } 
    }

    public static void loadNativeMod(Activity targetActivity)
    {
        loadLib("arzmod");

        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-initgame-module", "Context is null (InitSettingWrapper)");
            return;
        }
        InitGamePatch.setActivity(context);

        SharedPreferences defaultSharedPreferences = PreferenceManager.getDefaultSharedPreferences(context);

        if(SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_VERSION_HIDED)) InitGamePatch.setVersionString(""); 
        if(SettingsPatch.getSettingsKeyValue(SettingsPatch.CHAT_POSITION_ENABLED))
        {
            ChatPosition chatPosition = SettingsPatch.getChatPosition();
            if(chatPosition.enabled) InitGamePatch.setChatPosition(chatPosition.x, chatPosition.y);
        }
        if(isCustomServer())
        {
            Log.d("arzmod-initgame-module", "Enabling custom server fix...");
            InitGamePatch.installPacketsFix();
        }

        int hud_type = defaultSharedPreferences.getInt(SettingsPatch.HUD_TYPE, 3);
        int radar_type = defaultSharedPreferences.getInt(SettingsPatch.RADAR_TYPE, 0);

        if((!Objects.equals(Build.CPU_ABI, "arm64-v8a") && (hud_type != 3 || radar_type != 0)) || (Objects.equals(Build.CPU_ABI, "arm64-v8a") && hud_type != 3)) InitGamePatch.setHudType(hud_type, radar_type);
    }

    public static String formatVersion(int number) {
        if (number < 1000 || number > 9999) {
            return "v" + number;
        }

        String numStr = String.valueOf(number);

        return "v" + numStr.substring(0, 2) + "." + numStr.substring(2, 3) + "." + numStr.substring(3, 4);
    }

    public static void InitSettingWrapper() {
        try {
            context = AppContext.getContext();
            if (context == null) {
                Log.e("arzmod-initgame-module", "Context is null (InitSettingWrapper)");
                return;
            }

        
            boolean isMonetloaderWork = SettingsPatch.getSettingsKeyValue(SettingsPatch.MONETLOADER_WORK);
            boolean isShowFps = SettingsPatch.getSettingsKeyValue(SettingsConstants.SHOW_FPS);
            boolean isNewKeyboard = SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_NEW_KEYBOARD);
            boolean isNewInterface = SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_NEW_INTERFACE);
            boolean isStreamerMode = SettingsPatch.getSettingsKeyValue(SettingsConstants.STREAMER_MODE);
            boolean isAmbientSounds = SettingsPatch.getSettingsKeyValue(SettingsConstants.AMBIENT_SOUNDS);
            String deviceInfo = Build.MANUFACTURER + ":" + Build.MODEL + ":" + getUniqueID() + ":notify_on";
            int lastUIElementID = UIElementID.getLastUIElementID();

            SharedPreferences sharedPreferences = SettingsPatch.getSettingsPreferences();
            String notifyHash = sharedPreferences.getString(SettingsConstants.TOKEN, getUniqueID());

            GTASA.InitSetting(isNewInterface, isShowFps ? 1 : 0, isNewKeyboard, isStreamerMode, "(" + CONNECT_TAG + ") 2.1 - " + getLauncherVersion(), lastUIElementID, deviceInfo, notifyHash, FirebaseConfigHelper.INSTANCE.getChannelsState(), isAmbientSounds);
            
            FirebaseCrashlytics.getInstance().setUserId(getUniqueID());
            SettingsPatch.dumpAllSettingsKeys();
        } catch (LinkageError e) {
            Log.w("arzmod-initgame-module", "Unable to call native method InitSetting", e);
        }
    }

    public static String getLauncherVersion()
    {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-initgame-module", "Context is null (getLauncherVersion)");
            return ACTUAL_VERSION;
        }
        SharedPreferences defaultSharedPreferences = PreferenceManager.getDefaultSharedPreferences(context);

        if(SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_ACTUAL_VERSION))
        {
            String cachedVersion = defaultSharedPreferences.getString(ACTUAL_VERSION_PREF_KEY, ACTUAL_VERSION);

            new Thread(new Runnable() {
                @Override
                public void run() {
                    try {
                        HttpURLConnection connection = (HttpURLConnection) new URL("https://mob.maz-ins.com/game/release/app_version.json").openConnection();
                        connection.setConnectTimeout(3000);
                        connection.setReadTimeout(3000);
                        connection.setRequestMethod("GET");

                        int responseCode = connection.getResponseCode();
                        if (responseCode == 200) {
                            BufferedReader reader = new BufferedReader(
                                    new InputStreamReader(connection.getInputStream()));
                            StringBuilder builder = new StringBuilder();
                            String line;
                            while ((line = reader.readLine()) != null) {
                                builder.append(line);
                            }
                            reader.close();

                            JSONObject json = new JSONObject(builder.toString());
                            String newVersion = json.getString("launcherVersionName");

                            if (!newVersion.equals(cachedVersion)) {
                                defaultSharedPreferences.edit().putString(ACTUAL_VERSION_PREF_KEY, newVersion).apply();
                                Log.d("arzmod-initgame-module", "newActualVersion: " + newVersion + " cachedActualVersion: " + cachedVersion);
                            }
                        }

                        connection.disconnect();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }).start();
            Log.d("arzmod-initgame-module", "cachedActualVersion: " + cachedVersion);
            return cachedVersion;
        }
        else
        {
            Log.d("arzmod-initgame-module", "gameArchiveVersion: " + defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, BuildConfig.VERSION_CODE) + " formatVersion: " + formatVersion(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0)) + " actualVersion: " + ACTUAL_VERSION + " returnValue: " + (defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, BuildConfig.VERSION_CODE) != BuildConfig.VERSION_CODE ? formatVersion(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0)) : ACTUAL_VERSION));
            return (defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, BuildConfig.VERSION_CODE) != BuildConfig.VERSION_CODE ? formatVersion(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0)) : ACTUAL_VERSION);
        } 
    }
    

    public static String getUniqueID() {
        SharedPreferences sharedPreferences = SettingsPatch.getSettingsPreferences();
        String string = sharedPreferences.getString("uniqueID", null);
        if (string != null) {
            return string;
        }
        String uuid = UUID.randomUUID().toString();
        SharedPreferences.Editor edit = sharedPreferences.edit();
        edit.putString("uniqueID", uuid);
        edit.apply();
        return uuid;
    }

    public static boolean isCustomServer() {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-initgame-module", "Context is null (isCustomServer)");
            return false;
        }
        String packageName = context.getPackageName();
        try {
            String settingsPath = "/Android/data/" + packageName + "/files/SAMP/settings.json";
            File settingsFile = new File(Environment.getExternalStorageDirectory(), settingsPath);
            if (settingsFile.exists()) {
                JSONObject settings = new JSONObject(new String(Files.readAllBytes(settingsFile.toPath())));
                JSONObject server = settings.getJSONObject("client").getJSONObject("server");
                int id = server.getInt("id");
                int serverid = server.getInt("serverid");
                
                // if (!Objects.equals(Build.CPU_ABI, "arm64-v8a"))
                // { 
                //     if (id == 0 && serverid == 0) {
                //         return true;
                //     }
                // }
                // else 
                // {
                if (settings.getJSONObject("client").has("test")) {
                    JSONObject test = settings.getJSONObject("client").getJSONObject("test");
                    if (test.has("ip") && test.has("port")) {
                        String ip = test.getString("ip");
                        int port = test.getInt("port");
                        if (!ip.isEmpty() && port > 0) {
                            return true;
                        }
                    }
                }
                // }
            }
        } catch (Exception e) {
            Log.e("arzmod-initgame-module", "Failed to check settings.json: " + e.getMessage());
        }
        return false;
    }


    public static String[] getCustomServer() {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-initgame-module", "Context is null (getCustomServerIpPort)");
            return null;
        }
        String packageName = context.getPackageName();
        try {
            String settingsPath = "/Android/data/" + packageName + "/files/SAMP/settings.json";
            File settingsFile = new File(Environment.getExternalStorageDirectory(), settingsPath);
            if (settingsFile.exists()) {
                JSONObject settings = new JSONObject(new String(Files.readAllBytes(settingsFile.toPath())));
                JSONObject test = settings.getJSONObject("client").getJSONObject("test");
                String ip = test.getString("ip");
                int port = test.getInt("port");
                return new String[] { ip, String.valueOf(port) };
            }
        } catch (Exception e) {
            Log.e("arzmod-initgame-module", "Failed to get ip/port from settings.json: " + e.getMessage());
        }
        return null;
    }

    public static int[] getServer() {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-initgame-module", "Context is null (getServer)");
            return null;
        }
        String packageName = context.getPackageName();
        try {
            String settingsPath = "/Android/data/" + packageName + "/files/SAMP/settings.json";
            File settingsFile = new File(Environment.getExternalStorageDirectory(), settingsPath);
            if (settingsFile.exists()) {
                JSONObject settings = new JSONObject(new String(Files.readAllBytes(settingsFile.toPath())));
                JSONObject server = settings.getJSONObject("client").getJSONObject("server");
                int id = server.getInt("id");
                int serverid = server.getInt("serverid");
                return new int[] { id, serverid };
            }
        } catch (Exception e) {
            Log.e("arzmod-initgame-module", "Failed to get id/serverid from settings.json: " + e.getMessage());
        }
        return null;
    }

    public static void setServer(int id, int serverid) {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-initgame-module", "Context is null (setServer)");
            return;
        }
        
        String packageName = context.getPackageName();
        try {
            String settingsPath = "/Android/data/" + packageName + "/files/SAMP/settings.json";
            File settingsFile = new File(Environment.getExternalStorageDirectory(), settingsPath);
            
            if (!settingsFile.exists()) {
                Log.w("arzmod-initgame-module", "Settings file not found for writing");
                return;
            }
            
            JSONObject settings = new JSONObject(new String(Files.readAllBytes(settingsFile.toPath())));
            JSONObject server = settings.getJSONObject("client").getJSONObject("server");
            
            server.put("id", id);
            server.put("serverid", serverid);
            
            Files.write(settingsFile.toPath(), settings.toString(2).getBytes());
            Log.i("arzmod-initgame-module", "Server settings updated: id=" + id + ", serverid=" + serverid);
            
        } catch (Exception e) {
            Log.e("arzmod-initgame-module", "Failed to set id/serverid in settings.json: " + e.getMessage());
        }
    }

    public static void setAwaitText(RegistrationVideoBackground registrationVideoBackground, String text)
    {
        GamePatches.onSetConnectState(text);
        if(text.equals("Подключились. Входим в игру..."))
        {
            if(SettingsPatch.getSettingsKeyInt(SettingsPatch.VIDEO_HIDE_STEP) == 2 || isCustomServer()) hideVideo(registrationVideoBackground, 999);
        }
        
    }

    public static void hideVideo(RegistrationVideoBackground registrationVideoBackground, int step) {
        if((SettingsPatch.getSettingsKeyInt(SettingsPatch.VIDEO_HIDE_STEP) == 0 || SettingsPatch.getSettingsKeyInt(SettingsPatch.VIDEO_HIDE_STEP) != step) && step != 999) return;
        try {
            Field bindingField = registrationVideoBackground.getClass().getDeclaredField("videoBackgroundBinding");
            bindingField.setAccessible(true);
            Object binding = bindingField.get(registrationVideoBackground);
            
            Field playerViewField = binding.getClass().getDeclaredField("playerView");
            playerViewField.setAccessible(true);
            Object playerView = playerViewField.get(binding);
            
            Method getPlayerMethod = playerView.getClass().getMethod("getPlayer");
            Object player = getPlayerMethod.invoke(playerView);
            if (player != null) {
                player.getClass().getMethod("stop").invoke(player);
                player.getClass().getMethod("release").invoke(player);
            }
            
            Field videoField = binding.getClass().getDeclaredField("video");
            videoField.setAccessible(true);
            Object video = videoField.get(binding);
            
            if (video instanceof View) {
                ((View) video).setVisibility(View.GONE);
            } else {
                video.getClass().getMethod("setVisibility", int.class).invoke(video, 8);
            }
        } catch (Exception e) {
            Log.e("arzmod-init-game", "Failed to stop video: " + e.getMessage());
        }
    }
}
