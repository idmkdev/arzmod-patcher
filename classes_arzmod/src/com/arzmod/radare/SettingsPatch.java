package com.arzmod.radare;

import com.arizona.game.R;
import android.os.Build;
import java.util.List;
import java.util.ArrayList;
import java.util.HashMap;
import android.util.Log;
import kotlin.collections.MapsKt;
import kotlin.TuplesKt;
import kotlin.jvm.internal.Intrinsics;
import java.util.Iterator;
import kotlin.collections.CollectionsKt;
import com.arzmod.radare.Main;
import com.arzmod.radare.AppContext;
import com.arzmod.radare.UpdateServicePatch;
import android.content.Context;
import android.content.SharedPreferences;
import androidx.preference.PreferenceManager;
import android.app.AlertDialog;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Switch;
import android.widget.Spinner;
import android.widget.ArrayAdapter;
import android.widget.AdapterView;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.view.Gravity;
import android.widget.Toast;
import android.content.DialogInterface;
import java.util.Map;
import com.arizona.game.BuildConfig;
import android.widget.CompoundButton;
import android.widget.ImageView;
import android.graphics.drawable.Drawable;
import android.text.SpannableString;
import android.text.Spanned;
import android.text.method.LinkMovementMethod;
import android.text.style.ClickableSpan;
import android.content.Intent;
import android.net.Uri;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.util.DisplayMetrics;
import android.view.WindowManager;
import android.graphics.Point;
import android.view.Display;
import android.text.TextPaint;
import android.os.Handler;
import android.os.Looper;
import android.app.Activity;

public class SettingsPatch {
    
    public interface SettingChangeCallback {
        boolean onSettingChange(String key, Object newValue, Object oldValue);
    }

    public static abstract class AbstractSetting {
        protected String title;
        protected String settingKey;
        protected SharedPreferences preferences;
        protected SettingChangeCallback callback;

        public AbstractSetting(String title, String key, SharedPreferences prefs) {
            this.title = title;
            this.settingKey = key;
            this.preferences = prefs;
        }

        public String getTitle() { return title; }
        public String getSettingKey() { return settingKey; }
        public void setCallback(SettingChangeCallback callback) { this.callback = callback; }
        
        public abstract View createView(Context context);
        public abstract Object getCurrentValue();
    }

    public static class BooleanSetting extends AbstractSetting {
        private boolean defaultValue;

        public BooleanSetting(String title, String key, boolean defaultValue, SharedPreferences prefs) {
            super(title, key, prefs);
            this.defaultValue = defaultValue;
        }

        @Override
        public Boolean getCurrentValue() {
            return preferences.getBoolean(settingKey, defaultValue);
        }

        @Override
        public View createView(Context context) {
            LinearLayout layout = new LinearLayout(context);
            layout.setOrientation(LinearLayout.HORIZONTAL);
            layout.setPadding(20, 10, 20, 10);

            TextView titleView = new TextView(context);
            titleView.setText(title);
            titleView.setTextSize(16);
            titleView.setTextColor(Color.WHITE);

            Switch switchView = new Switch(context);
            switchView.setChecked(getCurrentValue());
            int textColor = Color.WHITE;
            switchView.setTextColor(textColor);
            
            try {
                switchView.getThumbDrawable().setColorFilter(Color.WHITE, android.graphics.PorterDuff.Mode.MULTIPLY);
                switchView.getTrackDrawable().setColorFilter(Color.GRAY, android.graphics.PorterDuff.Mode.MULTIPLY);
            } catch (Exception e) {
                Log.d("arzmod-settings-module", "Cannot set switch colors: " + e.getMessage());
            }
            
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            );
            params.weight = 1;
            titleView.setLayoutParams(params);
            
            layout.addView(titleView);
            layout.addView(switchView);

            switchView.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
                @Override
                public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                    boolean canChange = true;
                    if (callback != null) {
                        canChange = callback.onSettingChange(settingKey, isChecked, !isChecked);
                    }
                    if (canChange) {
                        preferences.edit().putBoolean(settingKey, isChecked).apply();
                    } else {
                        buttonView.setChecked(!isChecked);
                    }
                }
            });

            return layout;
        }
    }

    public static class SelectableValueSetting extends AbstractSetting {
        private int defaultValue;
        private Map<Integer, String> values;
        private int iconResId;

        public SelectableValueSetting(String title, String key, int defaultValue, Map<Integer, String> values, int iconResId, SharedPreferences prefs) {
            super(title, key, prefs);
            this.defaultValue = defaultValue;
            this.values = values;
            this.iconResId = iconResId;
        }

        @Override
        public Integer getCurrentValue() {
            return preferences.getInt(settingKey, defaultValue);
        }

        @Override
        public View createView(Context context) {
            LinearLayout layout = new LinearLayout(context);
            layout.setOrientation(LinearLayout.HORIZONTAL);
            layout.setPadding(20, 10, 20, 10);

            TextView titleView = new TextView(context);
            titleView.setText(title);
            titleView.setTextSize(16);
            titleView.setTextColor(Color.WHITE);
            
            LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            );
            titleParams.weight = 1;
            titleParams.gravity = Gravity.CENTER_VERTICAL;
            titleView.setLayoutParams(titleParams);
            
            Spinner spinner = new Spinner(context);
            List<String> valuesList = new ArrayList<>(values.values());
            
            ArrayAdapter<String> adapter = new ArrayAdapter<String>(context, android.R.layout.simple_spinner_item, valuesList) {
                @Override
                public View getView(int position, View convertView, ViewGroup parent) {
                    View view = super.getView(position, convertView, parent);
                    TextView text = (TextView) view.findViewById(android.R.id.text1);
                    text.setTextColor(Color.WHITE);
                    return view;
                }

                @Override
                public View getDropDownView(int position, View convertView, ViewGroup parent) {
                    View view = super.getDropDownView(position, convertView, parent);
                    TextView text = (TextView) view.findViewById(android.R.id.text1);
                    text.setTextColor(Color.WHITE);
                    text.setBackgroundColor(Color.parseColor("#80000000"));
                    text.setPadding(20, 10, 20, 10);
                    return view;
                }
            };
            
            adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            spinner.setAdapter(adapter);
            spinner.setPopupBackgroundResource(com.miami.game.core.drawable.resources.R.drawable.bg_arizona);

            LinearLayout.LayoutParams spinnerParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            );
            spinnerParams.gravity = Gravity.CENTER_VERTICAL;
            spinner.setLayoutParams(spinnerParams);

            int currentValue = getCurrentValue();
            int position = valuesList.indexOf(values.get(currentValue));
            if (position >= 0) {
                spinner.setSelection(position);
            }

            spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                @Override
                public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                    String selectedValue = valuesList.get(position);
                    int newKey = -1;
                    for (Map.Entry<Integer, String> entry : values.entrySet()) {
                        if (entry.getValue().equals(selectedValue)) {
                            newKey = entry.getKey();
                            break;
                        }
                    }
                    
                    if (newKey != -1 && newKey != getCurrentValue()) {
                        boolean canChange = true;
                        if (callback != null) {
                            canChange = callback.onSettingChange(settingKey, newKey, getCurrentValue());
                        }
                        if (canChange) {
                            preferences.edit().putInt(settingKey, newKey).apply();
                        } else {
                            int oldPosition = valuesList.indexOf(values.get(getCurrentValue()));
                            spinner.setSelection(oldPosition);
                        }
                    }
                }

                @Override
                public void onNothingSelected(AdapterView<?> parent) {}
            });

            layout.addView(titleView);
            layout.addView(spinner);
            return layout;
        }
    }

    private static Context context;
    private static List<AbstractSetting> settingsList;

    public static final String CHAT_FONT_SIZE = "chat_fontsize";
    public static final String CHAT_PAGE_SIZE = "chat_pagesize";
    public static final String CHAT_PRINT_TIMESTAMP = "chat_print_timestamp";
    public static final String IS_HEAD_MOVING = "head_moving";
    public static final String NICKNAME = "nickname";
    public static final String SHOW_FPS = "show_fps";
    public static final String STREAMER_MODE = "streamer_mode";
    public static final String TOKEN = "token";
    public static final String USE_FULLSCREEN = "use_fullscreen";
    // maybe arz will delete the files of the old launcher

    public static final String MONETLOADER_WORK = "monetloader_work";
    public static final String MODLOADER_STATE = "modloader_state";
    public static final String GAME_VERSION = "game_version";
    public static final String IS_NEW_KEYBOARD = "is_new_keyboard";
    public static final String IS_NEW_INTERFACE = "is_new_interface";
    public static final String IS_VERSION_21 = "is_version_21";
    public static final String IS_MODS_MODE = "is_mods_mode";
    public static final String IS_CLEAR_MODE = "is_clear_mode";
    public static final String IS_MODE_MODS = "is_mode_mods";
    public static List<AbstractSetting> getSettingsList(SharedPreferences sharedPreferences) {
        List<AbstractSetting> settingsList = new ArrayList<>();
        String cpu = Build.CPU_ABI;

        settingsList.add(new BooleanSetting("[MOD] MonetLoader & AML (LUA & CLEO Загрузчик)", MONETLOADER_WORK, true, sharedPreferences));

        if (!cpu.equals("arm64-v8a")) {
            settingsList.add(new BooleanSetting("[MOD] Новая клавиатура", IS_NEW_KEYBOARD, true, sharedPreferences));
            settingsList.add(new BooleanSetting("[MOD] Новый интерфейс", IS_NEW_INTERFACE, true, sharedPreferences));
        }
    
        settingsList.add(new BooleanSetting("[MOD] Очистка неиспольуемых файлов", IS_CLEAR_MODE, false, sharedPreferences));
        settingsList.add(new BooleanSetting("[MOD] Режим копирования сборки", IS_MODS_MODE, false, sharedPreferences));
        settingsList.add(new BooleanSetting("[MOD] Эмуляция лаунчера 2.1", IS_VERSION_21, false, sharedPreferences));
        settingsList.add(new BooleanSetting("[MOD] Проверка обновлений кеша игры", IS_MODE_MODS, true, sharedPreferences));

        if (!cpu.equals("arm64-v8a")) {
            settingsList.add(new SelectableValueSetting("[MOD] Загрузчик модов", MODLOADER_STATE, 0, MapsKt.mapOf(TuplesKt.to(0, "Выкл"), TuplesKt.to(1, "Текстуры"), TuplesKt.to(2, "Вкл")), R.drawable.user_icon_vec, sharedPreferences));
            
            Map<Integer, String> versions = new HashMap<>();
            versions.put(BuildConfig.VERSION_CODE,BuildConfig.VERSION_CODE + " actual");            
            if (BuildConfig.IS_ARIZONA) {
                versions.put(1579, "1579 arz crash");
            }
            versions.put(1508, "1508 " + (BuildConfig.IS_ARIZONA ? "arz" : "rdn") + " crash");
            settingsList.add(new SelectableValueSetting("[MOD] Версия игры", GAME_VERSION, 0, versions, R.drawable.user_icon_vec, sharedPreferences));
        }
        return settingsList;
    }

    private static SpannableString createClickableLinks(String text, Map<String, String> links) {
        SpannableString message = new SpannableString(text);
        
        for (Map.Entry<String, String> link : links.entrySet()) {
            String url = link.getKey();
            String displayText = link.getValue();
            
            int start = message.toString().indexOf(url);
            if (start != -1) {
                int end = start + displayText.length();
                ClickableSpan clickableSpan = new ClickableSpan() {
                    @Override
                    public void onClick(View widget) {
                        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse("https://" + url));
                        context.startActivity(intent);
                    }
                    @Override
                    public void updateDrawState(TextPaint ds) {
                        ds.setColor(Color.CYAN);
                        ds.setUnderlineText(true);
                    }
                };
                message.setSpan(clickableSpan, start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
        }
        
        return message;
    }

    public static void openSettingsMenu() {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-settings-module", "Context is null (openSettingsMenu)");
            return;
        }

        SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(context);
        settingsList = getSettingsList(sharedPreferences);

        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle("Настройки ARZMOD");

        LinearLayout mainLayout = new LinearLayout(context);
        mainLayout.setOrientation(LinearLayout.VERTICAL);
        mainLayout.setPadding(0, 20, 0, 20);

        TextView descriptionView = new TextView(context);
        Map<String, String> links = new HashMap<>();
        links.put("t.me/CleoArizona", "t.me/CleoArizona");
        links.put("arzmod.com", "arzmod.com");
        SpannableString message = createClickableLinks("Наш Telegram канал: t.me/CleoArizona\nНаш сайт: arzmod.com", links);
        
        descriptionView.setText(message);
        descriptionView.setMovementMethod(LinkMovementMethod.getInstance());
        descriptionView.setTextSize(14);
        descriptionView.setTextColor(Color.WHITE);
        descriptionView.setPadding(40, 0, 40, 20);
        mainLayout.addView(descriptionView);

        View divider = new View(context);
        divider.setBackgroundColor(Color.parseColor("#4DFFFFFF"));
        divider.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 1));
        mainLayout.addView(divider);

        String packageName = context.getPackageName();

        for (AbstractSetting setting : settingsList) {
            setting.setCallback(new SettingChangeCallback() {
                @Override
                public boolean onSettingChange(String key, Object newValue, Object oldValue) {
                    if (key.equals(IS_CLEAR_MODE)) {
                        boolean isEnabled = (Boolean) newValue;
                        if (isEnabled) {
                            new AlertDialog.Builder(context)
                                .setTitle("Очистка неиспользуемых файлов")
                                .setMessage("Данная функция очищает все файлы которые не нужны игре!\nФункция затрагивает только файлы в папке Android/data/"+packageName+"/files и удаляет все файлы необычные файлы\nЭта функция поможет вам удалить остатки сборки после удаления её из Android/media/"+packageName+"/files")
                                .setPositiveButton("OK", null)
                                .show();
                        }
                    } else if (key.equals(IS_MODS_MODE)) {
                        boolean isEnabled = (Boolean) newValue;
                        if (isEnabled) {
                            new AlertDialog.Builder(context)
                                .setTitle("Режим копирования сборки")
                                .setMessage("С помощью этой функции вы сможете копировать свою сборку с Android/media/"+packageName+"/files в Android/data/"+packageName+"/files.\nЧтобы удалить сборку используйте функции проверки файлов, и включите функцию очистки неиспользуемых файлов, для очистки остатков.")
                                .setPositiveButton("OK", null)
                                .show();
                        }
                    } else if (key.equals(IS_MODE_MODS)) {
                        boolean isEnabled = (Boolean) newValue;
                        if (isEnabled) {
                            new AlertDialog.Builder(context)
                                .setTitle("Проверка обновлений кеша игры")
                                .setMessage("Перезапустите лаунчер для корректной работы.")
                                .setPositiveButton("OK", null)
                                .show();
                        } else {
                            UpdateServicePatch.setHomeUi(false);
                        }
                    } else if (key.equals(GAME_VERSION)) {
                        Integer choosenVersion = (Integer) newValue;
                        switch(choosenVersion) {
                            case 1508: {
                                Map<String, String> warningLinks = new HashMap<>();
                                warningLinks.put("t.me/CleoArizona/217", "t.me/CleoArizona/217");
                                SpannableString message = createClickableLinks(
                                    "Внимание! Данная версия не работает на аризоновских серверах (включая некоторые бонусники), чтобы играть с неё прочитайте пост t.me/CleoArizona/217\nДля остальных SA:MP серверов можно спокойно использовать",
                                    warningLinks
                                );

                                TextView messageView = new TextView(context);
                                messageView.setText(message);
                                messageView.setMovementMethod(LinkMovementMethod.getInstance());
                                messageView.setTextColor(Color.WHITE);
                                messageView.setPadding(20, 20, 20, 20);

                                new AlertDialog.Builder(context)
                                    .setTitle("Выбрана версия " + choosenVersion)
                                    .setView(messageView)
                                    .setPositiveButton("OK", null)
                                    .show();
                                return true;
                            }
                            default: new AlertDialog.Builder(context)
                                    .setTitle("Выбрана версия " + choosenVersion)
                                    .setMessage("С данной версии нельзя зайти на любой другой сервер кроме аризоновского через меню.")
                                    .setPositiveButton("OK", null)
                                    .show();
                        }

                    }
                    return true;
                }
            });
            
            View settingView = setting.createView(context);
            if (settingView.getParent() != null) {
                ((ViewGroup) settingView.getParent()).removeView(settingView);
            }
            mainLayout.addView(settingView);
            
            View itemDivider = new View(context);
            itemDivider.setBackgroundColor(Color.parseColor("#4DFFFFFF"));
            itemDivider.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 1));
            mainLayout.addView(itemDivider);
        }

        android.widget.ScrollView scrollView = new android.widget.ScrollView(context);
        scrollView.addView(mainLayout);

        builder.setView(scrollView);
        builder.setPositiveButton("Закрыть", null);

        AlertDialog dialog = builder.create();
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawable(context.getResources().getDrawable(BuildConfig.IS_ARIZONA ? com.miami.game.core.drawable.resources.R.drawable.bg_arizona : com.miami.game.core.drawable.resources.R.drawable.bg_rodina));
        }
        dialog.show();

        TextView titleView = dialog.findViewById(android.R.id.title);
        if (titleView != null) {
            titleView.setTextColor(Color.WHITE);
        }

        android.widget.Button positiveButton = dialog.getButton(DialogInterface.BUTTON_POSITIVE);
        if (positiveButton != null) {
            positiveButton.setTextColor(Color.WHITE);
        }
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
            return false;
        }

            if (settingsList == null) {
                SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(context);
                settingsList = getSettingsList(sharedPreferences);
            }

            if (settingsList != null) {
            for (AbstractSetting setting : settingsList) {
                if (setting.getSettingKey().equals(key)) {
                    if (setting instanceof BooleanSetting) {
                        return (Boolean) setting.getCurrentValue();
                    }
                        break;
                }
            }
        }
        return false;
    }
}