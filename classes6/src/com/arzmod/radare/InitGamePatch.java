package com.arzmod.radare;

import android.os.Build;
import android.util.Log;
import java.util.UUID;
import android.content.Context;
import android.content.SharedPreferences;
import com.arzmod.radare.SettingsPatch;
import com.arzmod.radare.AppContext;
import com.arizona.launcher.model.settings.SettingsConstants;
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

    public static void firstTimePatches() {
        try {
            context = AppContext.getContext();
            if (context == null) {
                Log.e("arzmod-initgame-module", "Context is null (firstTimePatches)");
                return;
            }

            SharedPreferences defaultSharedPreferences = PreferenceManager.getDefaultSharedPreferences(context);
            GTASA.InitModloaderConfig(defaultSharedPreferences.getInt(SettingsPatch.MODLOADER_STATE, 0));

            UtilsKt.initZip(context);

            Log.d("arzmod-initgame-module", "game started. by ARZMOD (arzmod.com) & Community (t.me/cleodis)");
        } catch (LinkageError e) {
            Log.w("arzmod-initgame-module", "Unable to call native method InitModloaderConfig", e);
        } 
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
            boolean isNewVersion = SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_NEW_VERSION);
            boolean isVersion21 = SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_VERSION_21);
            boolean isStreamerMode = SettingsPatch.getSettingsKeyValue(SettingsConstants.STREAMER_MODE);
            String deviceInfo = Build.MANUFACTURER + ":" + Build.MODEL + ":" + getUniqueID();
            int lastUIElementID = UIElementID.getLastUIElementID();

            SharedPreferences sharedPreferences = SettingsPatch.getSettingsPreferences();
            String notifyHash = sharedPreferences.getString(SettingsConstants.TOKEN, getUniqueID());

            if (isMonetloaderWork) {
                GTASA.InitSetting(isNewInterface, isShowFps ? 1 : 0, isNewKeyboard, "(" + CONNECT_TAG + ") " + (isVersion21 ? "2.1" : "2.0") + " - " + (isNewVersion ? ACTUAL_VERSION : "v15.1.2"), lastUIElementID, deviceInfo, notifyHash);
            } else {
                GTASA.InitSetting(isNewInterface, isShowFps ? 1 : 0, isNewKeyboard, isStreamerMode, "(" + CONNECT_TAG + ") " + (isVersion21 ? "2.1" : "2.0") + " - " + ACTUAL_VERSION, lastUIElementID, deviceInfo, notifyHash);
            }
            
            
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
