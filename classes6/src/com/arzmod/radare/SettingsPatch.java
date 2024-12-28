package com.arzmod.radare;

import com.arizona.game.R;
import java.util.List;
import android.util.Log;
import kotlin.collections.MapsKt;
import kotlin.TuplesKt;
import kotlin.jvm.internal.Intrinsics;
import java.util.Iterator;
import kotlin.collections.CollectionsKt;
import com.arzmod.radare.AppContext;
import android.content.Context;
import android.content.SharedPreferences;
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
    public static final String IS_NEW_KEYBOARD = "is_new_keyboard";
    public static final String IS_NEW_INTERFACE = "is_new_interface";
    public static final String IS_NEW_VERSION = "is_new_version";
    public static final String IS_VERSION_21 = "is_version_21";
    public static final String IS_MODS_MODE = "is_mods_mode";
    public static final String IS_CLEAR_MODE = "is_clear_mode";
    public static List<AbstractSetting> getSettingsList(SharedPreferences sharedPreferences) {
        settingsList = CollectionsKt.mutableListOf(
            new StringSetting("Имя пользователя", "Указывается в игре", "Указывается в игре", sharedPreferences, R.drawable.user_icon_vec, StringSettingValidator.Companion.createByRegexp("")), 
            new BooleanSetting("Полный экран", SettingsConstants.USE_FULLSCREEN, false, sharedPreferences), 
            new BooleanSetting("Отображать FPS", SettingsConstants.SHOW_FPS, false, sharedPreferences), 
            new BooleanSetting("Дата и время в чате", SettingsConstants.CHAT_PRINT_TIMESTAMP, false, sharedPreferences), 
            new BooleanSetting("Режим стримера", SettingsConstants.STREAMER_MODE, false, sharedPreferences), 
            new BooleanSetting("Работа MonetLoader", MONETLOADER_WORK, true, sharedPreferences), 
            new BooleanSetting("Новая клавиатура", IS_NEW_KEYBOARD, true, sharedPreferences), 
            new BooleanSetting("Новый интерфейс", IS_NEW_INTERFACE, true, sharedPreferences), 
            new BooleanSetting("Очистка неиспольуемых файлов", IS_CLEAR_MODE, false, sharedPreferences), 
            new BooleanSetting("Режим копирования сборки", IS_MODS_MODE, false, sharedPreferences), 
            new BooleanSetting("Эмуляция актуальной версии", IS_NEW_VERSION, false, sharedPreferences), 
            new BooleanSetting("Эмуляция лаунчера 2.1", IS_VERSION_21, false, sharedPreferences), 
            new SelectableValueSetting("Загрузчик модов", MODLOADER_STATE, 0, MapsKt.mapOf(TuplesKt.to(0, "Выкл"), TuplesKt.to(1, "Текстуры"), TuplesKt.to(2, "Вкл")), R.drawable.user_icon_vec, sharedPreferences),
            new SelectableValueSetting("Строк чата", SettingsConstants.CHAT_PAGE_SIZE, 1, MapsKt.mapOf(TuplesKt.to(0, "5"), TuplesKt.to(1, "8"), TuplesKt.to(2, "10")), R.drawable.user_icon_vec, sharedPreferences), 
            new SelectableValueSetting("Размер шрифта чата", SettingsConstants.CHAT_FONT_SIZE, 2, MapsKt.mapOf(TuplesKt.to(0, "0.1"), TuplesKt.to(1, "0.5"), TuplesKt.to(2, "1.0"), TuplesKt.to(3, "1.5"), TuplesKt.to(4, "2.0")), R.drawable.user_icon_vec, sharedPreferences));
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
                Intrinsics.checkNotNull(obj, "null cannot be cast to non-null type com.arizona.launcher.model.settings.BooleanSetting");
                return ((BooleanSetting) obj).getCurrentValue();
            }
        }
        return false;
    }
}