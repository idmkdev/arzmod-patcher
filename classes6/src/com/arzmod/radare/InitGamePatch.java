package com.arzmod.radare;

import android.content.res.AssetManager;
import android.os.Build;
import android.os.Environment;
import android.util.Log;
import java.util.UUID;
import java.util.Objects;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.InputStream;
import android.content.Context;
import android.content.SharedPreferences;
import com.arzmod.radare.Main;
import com.arzmod.radare.SettingsPatch;
import com.arzmod.radare.AppContext;
import com.arizona.launcher.model.settings.SettingsConstants;
import com.arizona.game.GTASAInternal;
import com.google.firebase.crashlytics.FirebaseCrashlytics;
import com.arizona.game.GTASA;
import com.arizona.game.BuildConfig;
import com.arizona.launcher.util.UtilsKt;
import ru.mrlargha.commonui.core.UIElementID;
import androidx.preference.PreferenceManager;

public class InitGamePatch {
    private static Context context;
    private static String CONNECT_TAG = "release";
    private static String ACTUAL_VERSION = BuildConfig.VERSION_NAME;

    public static void copyFileFromAssets(Context context, String fileName, String outputFile) throws IOException {
        InputStream inputStream = context.getAssets().open("arzmod/" + fileName);

        File outFile = new File(outputFile);

        File parentDir = outFile.getParentFile();
        if (parentDir != null && !parentDir.exists()) {
            Path path = parentDir.toPath();
            try {
                Files.createDirectories(path);
            } catch (IOException e) {
                throw new IOException("Ошибка при создании директории: " + path.toAbsolutePath(), e);
            } catch (SecurityException e) {
                throw new SecurityException("Отсутствуют права для создания директории: " + path.toAbsolutePath(), e);
            }
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


    public static void loadLib(String libName) {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-initgame-module", "Context is null (loadLib)");
            return;
        }

        String nativeLibDir = context.getApplicationInfo().nativeLibraryDir;

        GTASAInternal.loadLibraryFromPath(nativeLibDir + "/lib" + libName + ".so");   
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
            
            try {
                String outputFile = Environment.getExternalStorageDirectory().getAbsolutePath() + "/Android/media/" + packageName + "/monetloader/compat/profile.json";
                copyFileFromAssets(context, "profile" + (defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0) != 0 ? getGameVersion(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0)) : "") + ".json", outputFile);
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
                if(isMonetloaderWork) loadLib("monetloader");
            } else {
                if(isMonetloaderWork)
                {
                    loadLib("samp" + (defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0) != 0 ? getGameVersion(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0)) : ""));
                    loadLib("monetloader");
                    loadLib("AML");
                }
                else loadLib("sampv");
            }
            if (Objects.equals(cpu, "arm64-v8a")) {
                loadLib("bass");
                loadLib("bass_fx");
                loadLib("bass_ssl");
            }

            try {
                GTASA.InitModloaderConfig(defaultSharedPreferences.getInt(SettingsPatch.MODLOADER_STATE, 0));
            } catch (LinkageError e) {
                Log.w("arzmod-initgame-module", "Unable to call native method InitModloaderConfig", e);
            } 

            UtilsKt.initZip(context);

            Log.d("arzmod-initgame-module", "game started. by ARZMOD (arzmod.com) & Community (t.me/cleodis)");
        } catch (LinkageError e) {
            e.printStackTrace();
            Log.e("arzmod-initgame-module", "Public firstTimePatches has errors");
        } 
    }

    public static int getGameVersion(int type) {
        switch(type) {
            case 1: return 1508;
            default: return 0;
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
            boolean isShowFps = SettingsPatch.getSettingsKeyValue(SettingsConstants.SHOW_FPS);
            boolean isNewKeyboard = SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_NEW_KEYBOARD);
            boolean isNewInterface = SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_NEW_INTERFACE);
            boolean isVersion21 = SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_VERSION_21);
            boolean isStreamerMode = SettingsPatch.getSettingsKeyValue(SettingsConstants.STREAMER_MODE);
            String deviceInfo = Build.MANUFACTURER + ":" + Build.MODEL + ":" + getUniqueID();
            int lastUIElementID = UIElementID.getLastUIElementID();

            SharedPreferences sharedPreferences = SettingsPatch.getSettingsPreferences();
            String notifyHash = sharedPreferences.getString(SettingsConstants.TOKEN, getUniqueID());

            if(getGameVersion(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0)) == 1508) GTASA.InitSetting(isNewInterface, isShowFps ? 1 : 0, isNewKeyboard, "(" + CONNECT_TAG + ") " + (isVersion21 ? "2.1" : "2.0") + " - " + (defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0) != 0 ? formatVersion(getGameVersion(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0))) : ACTUAL_VERSION), lastUIElementID, deviceInfo, notifyHash);
            else GTASA.InitSetting(isNewInterface, isShowFps ? 1 : 0, isNewKeyboard, isStreamerMode, "(" + CONNECT_TAG + ") " + (isVersion21 ? "2.1" : "2.0") + " - " + (defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0) != 0 ? formatVersion(getGameVersion(defaultSharedPreferences.getInt(SettingsPatch.GAME_VERSION, 0))) : ACTUAL_VERSION), lastUIElementID, deviceInfo, notifyHash);
            
            
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
