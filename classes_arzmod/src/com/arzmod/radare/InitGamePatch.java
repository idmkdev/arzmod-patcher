package com.arzmod.radare;

import android.content.res.AssetManager;
import android.os.Build;
import android.os.Environment;
import android.util.Log;
import java.util.UUID;
import java.util.Objects;
import java.util.HashMap;
import java.util.Map;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.BufferedReader;
import java.io.FileReader;
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
import androidx.preference.PreferenceManager;
import org.json.JSONObject;

public class InitGamePatch {
    private static Context context;
    private static String CONNECT_TAG = "release";
    private static String ACTUAL_VERSION = BuildConfig.VERSION_NAME;

    public native static void installPacketsFix();
    public native static void setVersionString(String string);
    public native static void setVersion(String version);
    public native static void versionFix(Context context);
    public native static void setChatPosition(float pos_x, float pos_y);

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
    }

    public static void firstTimePatches() {
        try {
            context = AppContext.getContext();
            if (context == null) {
                Log.e("arzmod-initgame-module", "Context is null (firstTimePatches)");
                return;
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
                loadLib("samp");
                if(isMonetloaderWork)
                {
                    loadLib("arzmod");
                    try {
                        InitGamePatch.setVersion(String.valueOf(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0)));
                        InitGamePatch.versionFix(context);
                    } catch (LinkageError e) {
                        Log.w("arzmod-initgame-module", "Unable to call native method versionFix. Using profile system...", e);
                    } 
                    loadLib("monetloader");
                }
            } else {
                loadLib("samp" + (defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, BuildConfig.VERSION_CODE) != BuildConfig.VERSION_CODE ? defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0) : ""));
                if(SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_VERSION_HIDED))
                {
                    loadLib("arzmod");
                    InitGamePatch.setVersionString("");
                }
                if(SettingsPatch.getSettingsKeyValue(SettingsPatch.CHAT_POSITION_ENABLED))
                {
                    loadLib("arzmod");
                    ChatPosition chatPosition = SettingsPatch.getChatPosition();
                    if(chatPosition.enabled) InitGamePatch.setChatPosition(chatPosition.x, chatPosition.y);
                }
                try {
                    String settingsPath = "/Android/data/" + packageName + "/files/SAMP/settings.json";
                    File settingsFile = new File(Environment.getExternalStorageDirectory(), settingsPath);
                    if (settingsFile.exists()) {
                        JSONObject settings = new JSONObject(new String(Files.readAllBytes(settingsFile.toPath())));
                        JSONObject server = settings.getJSONObject("client").getJSONObject("server");
                        int id = server.getInt("id");
                        int serverid = server.getInt("serverid");
                        
                        if (id == 0 && serverid == 0) {
                            Log.d("arzmod-initgame-module", "Enabling custom server fix...");
                            loadLib("arzmod");
                            InitGamePatch.installPacketsFix();
                        }
                    }
                } catch (Exception e) {
                    Log.e("arzmod-initgame-module", "Ошибка при проверке settings.json: " + e.getMessage());
                }
                if(isMonetloaderWork)
                {
                    if(loadedProfile.equals("profile.json") || loadedProfile.isEmpty())
                    {
                        loadLib("arzmod");
                        try {
                            InitGamePatch.setVersion(String.valueOf(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0)));
                            InitGamePatch.versionFix(context);
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

            Log.d("arzmod-initgame-module", "game started. by ARZMOD (arzmod.com) & Community (t.me/cleodis)");
        } catch (Exception e) {
            e.printStackTrace();
            Log.e("arzmod-initgame-module", "Public firstTimePatches has errors");
        } 
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

            SharedPreferences defaultSharedPreferences = PreferenceManager.getDefaultSharedPreferences(context);
        
            boolean isMonetloaderWork = SettingsPatch.getSettingsKeyValue(SettingsPatch.MONETLOADER_WORK);
            boolean isShowFps = SettingsPatch.getSettingsKeyValue(SettingsPatch.SHOW_FPS);
            boolean isNewKeyboard = SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_NEW_KEYBOARD);
            boolean isNewInterface = SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_NEW_INTERFACE);
            boolean isVersion21 = SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_VERSION_21);
            boolean isStreamerMode = SettingsPatch.getSettingsKeyValue(SettingsPatch.STREAMER_MODE);
            String deviceInfo = Build.MANUFACTURER + ":" + Build.MODEL + ":" + getUniqueID();
            int lastUIElementID = UIElementID.getLastUIElementID();

            SharedPreferences sharedPreferences = SettingsPatch.getSettingsPreferences();
            String notifyHash = sharedPreferences.getString(SettingsPatch.TOKEN, getUniqueID());

            if(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0) == 1508) GTASA.InitSetting(isNewInterface, isShowFps ? 1 : 0, isNewKeyboard, "(" + CONNECT_TAG + ") " + (isVersion21 ? "2.1" : "2.0") + " - " + formatVersion(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0)), lastUIElementID, deviceInfo, notifyHash);
            else GTASA.InitSetting(isNewInterface, isShowFps ? 1 : 0, isNewKeyboard, isStreamerMode, "(" + CONNECT_TAG + ") " + (isVersion21 ? "2.1" : "2.0") + " - " + (defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, BuildConfig.VERSION_CODE) != BuildConfig.VERSION_CODE ? formatVersion(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0)) : ACTUAL_VERSION), lastUIElementID, deviceInfo, notifyHash);
            
            
            FirebaseCrashlytics.getInstance().setUserId(getUniqueID());
        } catch (LinkageError e) {
            Log.w("arzmod-initgame-module", "Unable to call native method InitSetting", e);
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
}
