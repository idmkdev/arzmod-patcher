package com.arzmod.radare;

import com.arizona.game.R;
import android.os.Build;
import java.util.List;
import java.util.ArrayList;
import android.util.Log;
import kotlin.collections.MapsKt;
import kotlin.TuplesKt;
import kotlin.jvm.internal.Intrinsics;
import java.util.Iterator;
import kotlin.collections.CollectionsKt;
import com.arzmod.radare.Main;
import com.arzmod.radare.AppContext;
import android.content.Context;
import android.content.SharedPreferences;
import com.arizona.game.BuildConfig;
import com.arizona.launcher.model.settings.StringSetting;
import com.arizona.launcher.model.settings.validation.StringSettingValidator;
import com.arizona.launcher.model.settings.AbstractSetting;
import com.arizona.launcher.model.settings.BooleanSetting;
import com.arizona.launcher.model.settings.SelectableValueSetting;
import com.arizona.launcher.model.settings.SettingsConstants;
import androidx.preference.PreferenceManager;

public class SettingsPatch  {
    private static Context context;
    private static List<AbstractSetting> settingsList;

    public static final String MONETLOADER_WORK = "monetloader_work";
    public static final String MODLOADER_STATE = "modloader_state";
    public static final String GAME_VERSION = "game_version";
    public static final String IS_NEW_KEYBOARD = "is_new_keyboard";
    public static final String IS_NEW_INTERFACE = "is_new_interface";
    public static final String IS_VERSION_21 = "is_version_21";
    public static final String IS_MODS_MODE = "is_mods_mode";
    public static final String IS_CLEAR_MODE = "is_clear_mode";
    public static List<AbstractSetting> getSettingsList(SharedPreferences sharedPreferences) {
        List<AbstractSetting> settingsList = new ArrayList<>();
        String cpu = Build.CPU_ABI;

        settingsList.add(new StringSetting("Имя пользователя", "Указывается в игре", "Указывается в игре", sharedPreferences, R.drawable.user_icon_vec, StringSettingValidator.Companion.createByRegexp("")));
        settingsList.add(new BooleanSetting("Полный экран", SettingsConstants.USE_FULLSCREEN, false, sharedPreferences));
        settingsList.add(new BooleanSetting("Отображать FPS", SettingsConstants.SHOW_FPS, false, sharedPreferences));
        settingsList.add(new BooleanSetting("Дата и время в чате", SettingsConstants.CHAT_PRINT_TIMESTAMP, false, sharedPreferences));
        settingsList.add(new BooleanSetting("Режим стримера", SettingsConstants.STREAMER_MODE, false, sharedPreferences));
        settingsList.add(new SelectableValueSetting("Строк чата", SettingsConstants.CHAT_PAGE_SIZE, 1, MapsKt.mapOf(TuplesKt.to(0, "5"), TuplesKt.to(1, "8"), TuplesKt.to(2, "10")), R.drawable.user_icon_vec, sharedPreferences));
        settingsList.add(new SelectableValueSetting("Размер шрифта чата", SettingsConstants.CHAT_FONT_SIZE, 2, MapsKt.mapOf(TuplesKt.to(0, "0.1"), TuplesKt.to(1, "0.5"), TuplesKt.to(2, "1.0"), TuplesKt.to(3, "1.5"), TuplesKt.to(4, "2.0")), R.drawable.user_icon_vec, sharedPreferences));
        settingsList.add(new BooleanSetting("[MOD] MonetLoader & AML (LUA & CLEO Загрузчик)", MONETLOADER_WORK, true, sharedPreferences));

        if (!cpu.equals("arm64-v8a")) {
            settingsList.add(new BooleanSetting("[MOD] Новая клавиатура", IS_NEW_KEYBOARD, true, sharedPreferences));
            settingsList.add(new BooleanSetting("[MOD] Новый интерфейс", IS_NEW_INTERFACE, true, sharedPreferences));
        }
    
        settingsList.add(new BooleanSetting("[MOD] Очистка неиспольуемых файлов", IS_CLEAR_MODE, false, sharedPreferences));
        settingsList.add(new BooleanSetting("[MOD] Режим копирования сборки", IS_MODS_MODE, false, sharedPreferences));
        settingsList.add(new BooleanSetting("[MOD] Эмуляция лаунчера 2.1", IS_VERSION_21, false, sharedPreferences));

        if (!cpu.equals("arm64-v8a")) {
            settingsList.add(new SelectableValueSetting("[MOD] Загрузчик модов", MODLOADER_STATE, 0, MapsKt.mapOf(TuplesKt.to(0, "Выкл"), TuplesKt.to(1, "Текстуры"), TuplesKt.to(2, "Вкл")), R.drawable.user_icon_vec, sharedPreferences));
            settingsList.add(new SelectableValueSetting("[MOD] Версия игры", GAME_VERSION, 0, MapsKt.mapOf(TuplesKt.to(0, BuildConfig.VERSION_NAME + " actual"), TuplesKt.to(1508, "1508 (1.9.24 archive)")), R.drawable.user_icon_vec, sharedPreferences));
        }
        return settingsList;
    }

    public static SharedPreferences getSettingsPreferences() {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-settings-module", "Context is null (getSettingsPreferences)");
            return null;
        }
        return context.getSharedPreferences("myAppPreference", 0);
    }

    public static final boolean getSettingsKeyValue(String key) {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-settings-module", "Context is null (getSettingsKeyValue)");
        } else {
            Object obj;
            Iterator it;
            if (settingsList == null) {
                SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(context);
                settingsList = getSettingsList(sharedPreferences);
            }

            if (settingsList != null) {
                it = settingsList.iterator();
                while (true) {
                    if (!it.hasNext()) {
                        obj = null;
                        break;
                    }
                    obj = it.next();
                    if (Intrinsics.areEqual((Object) ((AbstractSetting) obj).getSettingKey(), (Object) key)) {
                        break;
                    }
                }
                if(obj == null) return false;
                return ((BooleanSetting) obj).getCurrentValue();
            }
        }
        return false;
    }
}