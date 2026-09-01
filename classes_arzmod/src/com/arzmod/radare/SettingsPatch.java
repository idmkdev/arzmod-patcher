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
import com.arzmod.radare.GameVersions;
import android.view.MotionEvent;
import android.os.Bundle;
import java.io.InputStream;
import android.widget.FrameLayout;
import android.net.Uri;
import androidx.core.content.FileProvider;
import java.io.File;
import android.os.Environment;

public class SettingsPatch {
    
    public interface SettingChangeCallback {
        boolean onSettingChange(String key, Object newValue, Object oldValue);
    }

    public static abstract class AbstractSetting {
        protected String title;
        protected String description;
        protected String settingKey;
        protected SharedPreferences preferences;
        protected SettingChangeCallback callback;

        public AbstractSetting(String title, String description, String key, SharedPreferences prefs) {
            this.title = title;
            this.description = description;
            this.settingKey = key;
            this.preferences = prefs;
        }

        public String getTitle() { return title; }
        public String getDescription() { return description; }
        public String getSettingKey() { return settingKey; }
        public void setCallback(SettingChangeCallback callback) { this.callback = callback; }
        
        public abstract View createView(Context context);
        public abstract Object getCurrentValue();
        public abstract Object getDefaultValue();
    }

    public static class BooleanSetting extends AbstractSetting {
        private boolean defaultValue;

        public BooleanSetting(String title, String description, String key, boolean defaultValue, SharedPreferences prefs) {
            super(title, description, key, prefs);
            this.defaultValue = defaultValue;
        }

        @Override
        public Boolean getCurrentValue() {
            return preferences.getBoolean(settingKey, defaultValue);
        }

        @Override
        public Boolean getDefaultValue() {
            return defaultValue;
        }

        @Override
        public View createView(Context context) {
            LinearLayout layout = new LinearLayout(context);
            layout.setOrientation(LinearLayout.HORIZONTAL);
            layout.setPadding(20, 10, 20, 10);
            layout.setGravity(Gravity.CENTER_VERTICAL);

            float density = context.getResources().getDisplayMetrics().density;
            int iconPadding = (int)(8 * density);

            if (description != null && !description.trim().isEmpty()) {
                ImageView infoIcon = new ImageView(context);
                infoIcon.setImageResource(android.R.drawable.ic_dialog_info);
                infoIcon.setPadding(0, 0, iconPadding, 0);
                infoIcon.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        AlertDialog.Builder builder = new AlertDialog.Builder(context);
                        builder.setTitle(title);
                        builder.setMessage(createClickableLinksFromDescription(description));
                        builder.setPositiveButton("OK", null);
                        AlertDialog dialog = builder.create();
                        dialog.show();
                        TextView messageView = dialog.findViewById(android.R.id.message);
                        if (messageView != null) {
                            messageView.setMovementMethod(LinkMovementMethod.getInstance());
                        }
                    }
                });
                layout.addView(infoIcon);
            }

            TextView titleView = new TextView(context);
            titleView.setText(title);
            titleView.setTextSize(16);
            titleView.setTextColor(Color.WHITE);
            layout.addView(titleView);

            View spacer = new View(context);
            LinearLayout.LayoutParams spacerParams = new LinearLayout.LayoutParams(0, 0, 1f);
            spacer.setLayoutParams(spacerParams);
            layout.addView(spacer);

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

        public SelectableValueSetting(String title, String description, String key, int defaultValue, Map<Integer, String> values, SharedPreferences prefs) {
            super(title, description, key, prefs);
            this.defaultValue = defaultValue;
            this.values = values;
        }

        @Override
        public Integer getCurrentValue() {
            return preferences.getInt(settingKey, defaultValue);
        }

        @Override
        public Integer getDefaultValue() {
            return defaultValue;
        }

        public String getCurrentValueText() {
            Integer currentValue = getCurrentValue();
            return values.getOrDefault(currentValue, String.valueOf(currentValue));
        }

        @Override
        public View createView(Context context) {
            LinearLayout layout = new LinearLayout(context);
            layout.setOrientation(LinearLayout.HORIZONTAL);
            layout.setPadding(20, 10, 20, 10);
            layout.setGravity(Gravity.CENTER_VERTICAL);

            float density = context.getResources().getDisplayMetrics().density;
            int iconPadding = (int)(8 * density);

            if (description != null && !description.trim().isEmpty()) {
                ImageView infoIcon = new ImageView(context);
                infoIcon.setImageResource(android.R.drawable.ic_dialog_info);
                infoIcon.setPadding(0, 0, iconPadding, 0);
                infoIcon.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        AlertDialog.Builder builder = new AlertDialog.Builder(context);
                        builder.setTitle(title);
                        builder.setMessage(createClickableLinksFromDescription(description));
                        builder.setPositiveButton("OK", null);
                        AlertDialog dialog = builder.create();
                        dialog.show();
                        TextView messageView = dialog.findViewById(android.R.id.message);
                        if (messageView != null) {
                            messageView.setMovementMethod(LinkMovementMethod.getInstance());
                        }
                    }
                });
                layout.addView(infoIcon);
            }

            TextView titleView = new TextView(context);
            titleView.setText(title);
            titleView.setTextSize(16);
            titleView.setTextColor(Color.WHITE);
            layout.addView(titleView);

            View spacer = new View(context);
            LinearLayout.LayoutParams spacerParams = new LinearLayout.LayoutParams(0, 0, 1f);
            spacer.setLayoutParams(spacerParams);
            layout.addView(spacer);

            List<Integer> sortedKeys = new ArrayList<>(values.keySet());
            java.util.Collections.sort(sortedKeys, java.util.Collections.reverseOrder());
            List<String> valuesList = new ArrayList<>();
            for (Integer key : sortedKeys) {
                valuesList.add(values.get(key));
            }

            Spinner spinner = new Spinner(context);
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
            try {
                java.io.InputStream is = context.getAssets().open("background_home.webp");
                Drawable backgroundDrawable = Drawable.createFromStream(is, null);
                spinner.setPopupBackgroundDrawable(backgroundDrawable);
            } catch (Throwable t) {
                spinner.setPopupBackgroundResource(android.R.color.transparent);
            }

            LinearLayout.LayoutParams spinnerParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            );
            spinnerParams.gravity = Gravity.CENTER_VERTICAL;
            spinner.setLayoutParams(spinnerParams);


            int currentValue = getCurrentValue();
            int position = sortedKeys.indexOf(currentValue);
            if (position >= 0) {
                spinner.setSelection(position);
            }

            spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                @Override
                public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                    int newKey = sortedKeys.get(position);
                    if (newKey != getCurrentValue()) {
                        boolean canChange = true;
                        if (callback != null) {
                            canChange = callback.onSettingChange(settingKey, newKey, getCurrentValue());
                        }
                        if (canChange) {
                            preferences.edit().putInt(settingKey, newKey).apply();
                        } else {
                            int oldPosition = sortedKeys.indexOf(getCurrentValue());
                            spinner.setSelection(oldPosition);
                        }
                    }
                }

                @Override
                public void onNothingSelected(AdapterView<?> parent) {}
            });

            layout.addView(spinner);
            return layout;
        }
    }

    public static final String CHAT_POSITION_ENABLED = "chat_position_enabled";
    public static final String CHAT_POSITION_X = "chat_position_x";
    public static final String CHAT_POSITION_Y = "chat_position_y";

    public static class ChatPositionSetting extends AbstractSetting {
        private static final float DEFAULT_X = 384.375f;
        private static final float DEFAULT_Y = 22.5f;
        private float currentX = DEFAULT_X;
        private float currentY = DEFAULT_Y;
        private AlertDialog editDialog;

        public ChatPositionSetting(String title, String key, SharedPreferences prefs) {
            super(title, null, key, prefs);
            currentX = prefs.getFloat(CHAT_POSITION_X, DEFAULT_X);
            currentY = prefs.getFloat(CHAT_POSITION_Y, DEFAULT_Y);
        }

        @Override
        public Boolean getCurrentValue() {
            return preferences.getBoolean(settingKey, false);
        }

        @Override
        public Boolean getDefaultValue() {
            return false;
        }

        private void showEditDialog(Context context) {
            AlertDialog.Builder builder = new AlertDialog.Builder(context);
            
            WindowManager wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
            Display display = wm.getDefaultDisplay();
            Point size = new Point();
            display.getSize(size);
            int screenWidth = size.x;
            int screenHeight = size.y;

            FrameLayout mainLayout = new FrameLayout(context);
            mainLayout.setLayoutParams(new ViewGroup.LayoutParams(
                screenWidth,
                screenHeight
            ));

            TextView warningText = new TextView(context);
            SpannableString warningMessage = new SpannableString("Позиции тут и в игре могут различаться. Для точной редакции установите скрипт setchatposition.lua");
            ClickableSpan clickableSpan = new ClickableSpan() {
                @Override
                public void onClick(View widget) {
                    Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/" + BuildConfig.GIT_OWNER + "/" + BuildConfig.GIT_REPO + "/tree/main/configs/scripts/setchatposition.lua"));
                    context.startActivity(intent);
                }
                @Override
                public void updateDrawState(TextPaint ds) {
                    ds.setColor(Color.CYAN);
                    ds.setUnderlineText(true);
                }
            };
            warningMessage.setSpan(clickableSpan, warningMessage.toString().indexOf("setchatposition.lua"), 
                warningMessage.toString().indexOf("setchatposition.lua") + "setchatposition.lua".length(), 
                Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            
            warningText.setText(warningMessage);
            warningText.setTextColor(Color.WHITE);
            warningText.setTextSize(14);
            warningText.setPadding(20, 20, 20, 20);
            warningText.setBackgroundColor(Color.parseColor("#80000000"));
            warningText.setMovementMethod(LinkMovementMethod.getInstance());
            
            FrameLayout.LayoutParams warningParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            );
            warningParams.gravity = Gravity.TOP | Gravity.START;
            warningText.setLayoutParams(warningParams);

            ImageView backgroundView = new ImageView(context);
            FrameLayout.LayoutParams bgParams = new FrameLayout.LayoutParams(
                screenWidth,
                screenHeight
            );
            backgroundView.setLayoutParams(bgParams);
            backgroundView.setScaleType(ImageView.ScaleType.FIT_XY);
            
            try {
                InputStream is = context.getAssets().open("arzmod/game.png");
                Bitmap bitmap = BitmapFactory.decodeStream(is);
                backgroundView.setImageBitmap(bitmap);
                is.close();
            } catch (Exception e) {
                backgroundView.setBackgroundColor(Color.parseColor("#80000000"));
            }

            ImageView chatView = new ImageView(context);
            FrameLayout.LayoutParams chatParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            );
            chatView.setLayoutParams(chatParams);
            
            try {
                InputStream is = context.getAssets().open("arzmod/chat.png");
                Bitmap bitmap = BitmapFactory.decodeStream(is);
                chatView.setImageBitmap(bitmap);
                is.close();
            } catch (Exception e) {
                chatView.setBackgroundColor(Color.parseColor("#80000000"));
            }

            LinearLayout buttonsLayout = new LinearLayout(context);
            buttonsLayout.setOrientation(LinearLayout.HORIZONTAL);
            buttonsLayout.setGravity(Gravity.CENTER);
            buttonsLayout.setPadding(20, 20, 20, 20);
            buttonsLayout.setBackgroundColor(Color.parseColor("#80000000"));

            FrameLayout.LayoutParams buttonsParams = new FrameLayout.LayoutParams(
                screenWidth / 3,
                ViewGroup.LayoutParams.WRAP_CONTENT
            );
            buttonsParams.gravity = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
            buttonsParams.bottomMargin = 50;
            buttonsLayout.setLayoutParams(buttonsParams);

            android.widget.Button saveButton = new android.widget.Button(context);
            saveButton.setText("Сохранить");
            saveButton.setTextColor(Color.WHITE);
            saveButton.setBackgroundColor(Color.parseColor("#4CAF50"));
            saveButton.setTextSize(12);

            android.widget.Button resetButton = new android.widget.Button(context);
            resetButton.setText("Сбросить");
            resetButton.setTextColor(Color.WHITE);
            resetButton.setBackgroundColor(Color.parseColor("#FFC107"));
            resetButton.setTextSize(12);

            android.widget.Button cancelButton = new android.widget.Button(context);
            cancelButton.setText("Отменить");
            cancelButton.setTextColor(Color.WHITE);
            cancelButton.setBackgroundColor(Color.parseColor("#F44336"));
            cancelButton.setTextSize(12);

            LinearLayout.LayoutParams buttonParams = new LinearLayout.LayoutParams(
                0,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                1.0f
            );
            buttonParams.setMargins(5, 0, 5, 0);

            saveButton.setLayoutParams(buttonParams);
            resetButton.setLayoutParams(buttonParams);
            cancelButton.setLayoutParams(buttonParams);

            buttonsLayout.addView(saveButton);
            buttonsLayout.addView(resetButton);
            buttonsLayout.addView(cancelButton);

            mainLayout.addView(backgroundView);
            mainLayout.addView(chatView);
            mainLayout.addView(buttonsLayout);
            mainLayout.addView(warningText);

            chatView.setX(currentX);
            chatView.setY(currentY);

            chatView.setOnTouchListener(new View.OnTouchListener() {
                private float lastX = 0;
                private float lastY = 0;

                @Override
                public boolean onTouch(View v, MotionEvent event) {
                    switch (event.getAction()) {
                        case MotionEvent.ACTION_DOWN:
                            lastX = event.getRawX();
                            lastY = event.getRawY();
                            return true;
                        case MotionEvent.ACTION_MOVE:
                            float deltaX = event.getRawX() - lastX;
                            float deltaY = event.getRawY() - lastY;
                            
                            lastX = event.getRawX();
                            lastY = event.getRawY();
                            
                            float newX = Math.max(-500, Math.min(screenWidth + 500, v.getX() + deltaX));
                            float newY = Math.max(-300, Math.min(screenHeight + 300, v.getY() + deltaY));
                            
                            v.setX(newX);
                            v.setY(newY);
                            
                            currentX = newX;
                            currentY = newY;
                            return true;
                        case MotionEvent.ACTION_UP:
                            return true;
                    }
                    return false;
                }
            });

            saveButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    preferences.edit()
                        .putFloat(CHAT_POSITION_X, currentX)
                        .putFloat(CHAT_POSITION_Y, currentY)
                        .apply();
                    Toast.makeText(context, "Позиция сохранена", Toast.LENGTH_SHORT).show();
                    if (editDialog != null) {
                        editDialog.dismiss();
                    }
                }
            });

            resetButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    currentX = DEFAULT_X;
                    currentY = DEFAULT_Y;
                    chatView.setX(currentX);
                    chatView.setY(currentY);
                    preferences.edit()
                        .putFloat(CHAT_POSITION_X, DEFAULT_X)
                        .putFloat(CHAT_POSITION_Y, DEFAULT_Y)
                        .apply();
                    Toast.makeText(context, "Позиция сброшена", Toast.LENGTH_SHORT).show();
                }
            });

            cancelButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (editDialog != null) {
                        editDialog.dismiss();
                    }
                }
            });

            builder.setView(mainLayout);
            editDialog = builder.create();
            
            if (editDialog.getWindow() != null) {
                editDialog.getWindow().setLayout(
                    screenWidth,
                    screenHeight
                );
                editDialog.getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
                editDialog.getWindow().setFlags(
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                );
            }
            
            editDialog.show();
        }

        @Override
        public View createView(Context context) {
            LinearLayout layout = new LinearLayout(context);
            layout.setOrientation(LinearLayout.HORIZONTAL);
            layout.setPadding(20, 10, 20, 10);
            layout.setGravity(Gravity.CENTER_VERTICAL);

            float density = context.getResources().getDisplayMetrics().density;
            int iconPadding = (int)(8 * density);


            if (description != null && !description.trim().isEmpty()) {
                ImageView infoIcon = new ImageView(context);
                infoIcon.setImageResource(android.R.drawable.ic_dialog_info);
                infoIcon.setPadding(0, 0, iconPadding, 0);
                infoIcon.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        AlertDialog.Builder builder = new AlertDialog.Builder(context);
                        builder.setTitle(title);
                        builder.setMessage(createClickableLinksFromDescription(description));
                        builder.setPositiveButton("OK", null);
                        AlertDialog dialog = builder.create();
                        dialog.show();
                        TextView messageView = dialog.findViewById(android.R.id.message);
                        if (messageView != null) {
                            messageView.setMovementMethod(LinkMovementMethod.getInstance());
                        }
                    }
                });
                layout.addView(infoIcon);
            }

            TextView titleView = new TextView(context);
            titleView.setText(title);
            titleView.setTextSize(16);
            titleView.setTextColor(Color.WHITE);
            layout.addView(titleView);

            View spacer = new View(context);
            LinearLayout.LayoutParams spacerParams = new LinearLayout.LayoutParams(0, 0, 1f);
            spacer.setLayoutParams(spacerParams);
            layout.addView(spacer);

            Switch switchView = new Switch(context);
            switchView.setChecked(getCurrentValue());
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
                        if (isChecked) {
                            showEditDialog(context);
                        } else {
                            currentX = DEFAULT_X;
                            currentY = DEFAULT_Y;
                            preferences.edit()
                                .putFloat(CHAT_POSITION_X, DEFAULT_X)
                                .putFloat(CHAT_POSITION_Y, DEFAULT_Y)
                                .apply();
                        }
                    } else {
                        buttonView.setChecked(!isChecked);
                    }
                }
            });

            return layout;
        }
    }

    public static class ChatPosition {
        public final boolean enabled;
        public final float x;
        public final float y;

        public ChatPosition(boolean enabled, float x, float y) {
            this.enabled = enabled;
            this.x = x;
            this.y = y;
        }
    }

    public static ChatPosition getChatPosition() {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-settings-module", "Context is null (getChatPosition)");
            return new ChatPosition(false, 384.375f, 22.5f);
        }

        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
        boolean isEnabled = prefs.getBoolean(CHAT_POSITION_ENABLED, false);
        
        if (!isEnabled) {
            return new ChatPosition(false, 384.375f, 22.5f);
        }

        float x = prefs.getFloat(CHAT_POSITION_X, 384.375f);
        float y = prefs.getFloat(CHAT_POSITION_Y, 22.5f);
        return new ChatPosition(true, x, y);
    }

    private static Context context;
    private static Activity activity;
    private static List<AbstractSetting> settingsList;

    public static final String MONETLOADER_WORK = "monetloader_work";
    public static final String MODLOADER_STATE = "modloader_state";
    public static final String GAME_VERSION = "game_version";
    public static final String IS_NEW_KEYBOARD = "is_new_keyboard";
    public static final String IS_NEW_INTERFACE = "is_new_interface";
    public static final String IS_UNITY_ELEMENTS = "is_unity_elements";
    public static final String IS_MODS_MODE = "is_mods_mode";
    public static final String IS_CLEAR_MODE = "is_clear_mode";
    public static final String IS_MODE_MODS = "is_mode_mods";
    public static final String IS_FREE_LAUNCH = "is_free_launch";
    public static final String IS_VERSION_HIDED = "is_version_hided";
    public static final String IS_SKIP_VERIFY = "is_skip_verify";
    public static final String IS_ACTUAL_VERSION = "is_actual_version";
    public static final String IS_DEV_HUNGRY = "is_dev_hungry";
    public static final String IS_HIDE_DIALOGS = "is_hide_dialogs";
    public static final String VIDEO_HIDE_STEP = "video_hide_step";
    public static final String HUD_TYPE = "hud_type";
    public static final String RADAR_TYPE = "radar_type";
    public static List<AbstractSetting> getSettingsList(SharedPreferences sharedPreferences) {
        List<AbstractSetting> settingsList = new ArrayList<>();
        String cpu = Build.CPU_ABI;

        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-settings-module", "Context is null (getSettingsList)");
            return null;
        }

        String packageName = context.getPackageName();

        settingsList.add(new BooleanSetting(cpu.equals("arm64-v8a") ? "MonetLoader (LUA Загрузчик)" : "MonetLoader & AML (LUA & CLEO Загрузчик)", cpu.equals("arm64-v8a") ? "Включает основной функционал лаунчера - поддержка Lua (MonetLoader). Если вы испытываете проблемы с работой игры (краш, фризы) попробуйте отключить данную функцию" : "Включает основную идею лаунчера - поддержка Lua, CLEO, AML. Если вы испытываете проблемы с работой игры (краш, фризы) попробуйте отключить данную функцию", MONETLOADER_WORK, true, sharedPreferences));

        if (!cpu.equals("arm64-v8a")) {
            settingsList.add(new BooleanSetting("Новая клавиатура", "Включает Android клавиатуру, при отключении будет использоваться стандартная SA:MP Mobile клавиатура", IS_NEW_KEYBOARD, true, sharedPreferences));
            settingsList.add(new BooleanSetting("Новый интерфейс", "Включает новый интерфейс, диалоги станут на Java интерфейсе, кнопки под картой также.\nПри отключении под картой будут ESC, ALT (они сломаны разработчиками аризоны, фикс - https://t.me/tglangera/764 ), а диалоги станут стандартными из SA:MP Mobile", IS_NEW_INTERFACE, true, sharedPreferences));
        }
        settingsList.add(new BooleanSetting("Элементы UnityHUD", "При худе отличного от UnityHUD данная настройка покажет его элементы при этом не показывая его самого", IS_UNITY_ELEMENTS, false, sharedPreferences));
    
        settingsList.add(new BooleanSetting("Режим копирования сборки", "С помощью этой функции вы сможете копировать свою сборку с Android/media/"+packageName+"/files в Android/data/"+packageName+"/files.\nЧтобы удалить сборку используйте функции проверки файлов, и включите функцию очистки неиспользуемых файлов, для очистки остатков.", IS_MODS_MODE, false, sharedPreferences));
        settingsList.add(new BooleanSetting("Проверка обновлений кеша игры", "При отключении данной функции, лаунчер не будет проверять обновления кеша игры", IS_MODE_MODS, true, sharedPreferences));
        settingsList.add(new BooleanSetting("Свободная кнопка запуска", "Данная функция позовляет запустить игру во время проверки обновления", IS_FREE_LAUNCH, false, sharedPreferences));
        settingsList.add(new BooleanSetting("Эмуляция актуальной версии", "При включенной функции лаунчер отправляет на сервер самую актуальную версию игры независимую от текущей версии ARZMOD взятую с https://mob.maz-ins.com/game/release/app_version.json", IS_ACTUAL_VERSION, true, sharedPreferences));

        
        settingsList.add(new ChatPositionSetting("Позиция чата", CHAT_POSITION_ENABLED, sharedPreferences));
        settingsList.add(new BooleanSetting("Скрытие строки версии", "Скрывает строку версии в игре. Доступен также публичный метод, который позволяет вписать свою строку (пример использования есть в скрипте https://github.com/" + BuildConfig.GIT_OWNER + "/" + BuildConfig.GIT_REPO + "/tree/main/configs/scripts/setversionstring.lua )", IS_VERSION_HIDED, false, sharedPreferences));

        settingsList.add(new BooleanSetting("Не перезаписывать модифицированные ARZMOD файлы", "Не перезаписывает ваши файлы если для них есть замена с локальных файлов ARZMOD\nНапример, если вы изменяете файлы по умолчанию (скрипт менеджер, библиотеки), чтобы оно не перезаписывалось, включите эту функцию.\nОбратите внимание, что при обновлении ARZMOD лаунчера с этой функцией стоит держать первое время включенной", IS_SKIP_VERIFY, false, sharedPreferences));

        settingsList.add(new BooleanSetting("Не показывать вспомогательные диалоги", "При включении данной настройки не будут показываться вспомогательные диалоги (например, при неудачном подключении к серверу)", IS_HIDE_DIALOGS, false, sharedPreferences));
        settingsList.add(new SelectableValueSetting("Скрывать видео загрузки", "Скрывает видео загрузки. Функция работает вне от значения настройки при заходе на кастомный сервер.", VIDEO_HIDE_STEP, 0, MapsKt.mapOf(TuplesKt.to(0, "Не скрывать"), TuplesKt.to(1, "Сразу"), TuplesKt.to(2, "При подключении")), sharedPreferences));
        if (cpu.equals("arm64-v8a")) {
            settingsList.add(new SelectableValueSetting("Тип худа", "Настройка перенесенная с кастомизации интерфейса. Позволяет выбрать тип HUD", HUD_TYPE, 3, MapsKt.mapOf(TuplesKt.to(0, "Стандартный"), TuplesKt.to(3, "UnityHUD")), sharedPreferences));   
        }
        else {
            settingsList.add(new SelectableValueSetting("Тип худа", "Настройка перенесенная с кастомизации интерфейса. Позволяет выбрать тип HUD", HUD_TYPE, 3, MapsKt.mapOf(TuplesKt.to(0, "Стандартный"), TuplesKt.to(1, "Кастомный 1"), TuplesKt.to(2, "Кастомный 2"), TuplesKt.to(3, "UnityHUD")), sharedPreferences));    
            settingsList.add(new SelectableValueSetting("Тип радара", "Настройка перенесенная с кастомизации интерфейса. Позволяет выбрать тип карты радара", RADAR_TYPE, 0, MapsKt.mapOf(TuplesKt.to(0, "Стандартный"), TuplesKt.to(1, "Квадратный 1"), TuplesKt.to(2, "Квадратный 2")), sharedPreferences));  
            settingsList.add(new SelectableValueSetting("Загрузчик модов", "Альтернативное название - ModLoader", MODLOADER_STATE, 0, MapsKt.mapOf(TuplesKt.to(0, "Выкл"), TuplesKt.to(1, "Текстуры"), TuplesKt.to(2, "Вкл")), sharedPreferences));
            settingsList.add(new SelectableValueSetting("Версия игры", "Если вы испытываете проблемы на текущей версии игры - выберите другую.\nНекоторые функции, такие как Скрытие строки версии и Позиция чата могут не работать на старых версиях", GAME_VERSION, 0, GameVersions.getVersions(), sharedPreferences));
        }
        settingsList.add(new BooleanSetting("Оставить разработчика мода без еды", "При включении функции вы не увидите баннер-рекламу сверху. (Для полного скрытия еще и баннера слева можно перейти на offline версию - https://github.com/idmkdev/arzmod-patcher/releases/latest там нет никакой принудительной рекламы от ARZMOD)", IS_DEV_HUNGRY, false, sharedPreferences));
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
                        Activity activity = AppContext.getActivity();
                        if(activity == null) Log.e("arzmod-settings-module", "Activity is null (clickablespan)");
                        else
                        {
                            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse("https://" + url));
                            activity.startActivity(intent);
                        }
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

    private static void showResetConfirmationDialog(Activity activity, SharedPreferences sharedPreferences, AlertDialog parentDialog) {
        AlertDialog.Builder confirmBuilder = new AlertDialog.Builder(activity);
        
        LinearLayout mainLayout = new LinearLayout(activity);
        mainLayout.setOrientation(LinearLayout.VERTICAL);
        mainLayout.setPadding(40, 30, 40, 30);
        
        TextView titleView = new TextView(activity);
        titleView.setText("⚠️ Сброс настроек");
        titleView.setTextSize(18);
        titleView.setTextColor(Color.WHITE);
        titleView.setTypeface(null, android.graphics.Typeface.BOLD);
        titleView.setGravity(Gravity.CENTER);
        titleView.setPadding(0, 0, 0, 20);
        mainLayout.addView(titleView);
        
        TextView messageView = new TextView(activity);
        messageView.setText("Сбросить ВСЕ настройки к значениям по умолчанию?\n\nЭто действие нельзя отменить!");
        messageView.setTextSize(14);
        messageView.setTextColor(Color.WHITE);
        messageView.setGravity(Gravity.LEFT);
        messageView.setLineSpacing(2, 1.1f);
        messageView.setPadding(0, 0, 0, 30);
        mainLayout.addView(messageView);
        
        LinearLayout buttonsLayout = new LinearLayout(activity);
        buttonsLayout.setOrientation(LinearLayout.HORIZONTAL);
        buttonsLayout.setGravity(Gravity.CENTER);
        
        android.widget.Button cancelButton = new android.widget.Button(activity);
        cancelButton.setText("Отмена");
        cancelButton.setTextColor(Color.WHITE);
        cancelButton.setBackgroundColor(Color.parseColor("#757575"));
        cancelButton.setPadding(20, 10, 20, 10);
        
        android.widget.Button confirmButton = new android.widget.Button(activity);
        confirmButton.setText("Да, сбросить");
        confirmButton.setTextColor(Color.WHITE);
        confirmButton.setBackgroundColor(Color.parseColor("#F44336"));
        confirmButton.setPadding(20, 10, 20, 10);
        
        LinearLayout.LayoutParams buttonParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        );
        buttonParams.setMargins(10, 0, 10, 0);
        cancelButton.setLayoutParams(buttonParams);
        confirmButton.setLayoutParams(buttonParams);
        
        buttonsLayout.addView(cancelButton);
        buttonsLayout.addView(confirmButton);
        mainLayout.addView(buttonsLayout);
        
        confirmBuilder.setView(mainLayout);
        
        AlertDialog confirmDialog = confirmBuilder.create();
        if (confirmDialog.getWindow() != null) {
            confirmDialog.getWindow().setBackgroundDrawable(new ColorDrawable(Color.parseColor("#FF424242")));
        }
        
        cancelButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                confirmDialog.dismiss();
            }
        });
        
        confirmButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                resetAllSettings(activity, sharedPreferences);
                parentDialog.dismiss();
                confirmDialog.dismiss();
                Toast.makeText(activity, "Настройки сброшены", Toast.LENGTH_LONG).show();
                new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        openSettingsMenu();
                    }
                }, 500);
            }
        });
        
        confirmDialog.show();
    }

    private static void resetAllSettings(Activity activity, SharedPreferences sharedPreferences) {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        
        if (settingsList == null) {
            settingsList = getSettingsList(sharedPreferences);
        }
        
        if (settingsList != null) {
            for (AbstractSetting setting : settingsList) {
                Object defaultValue = setting.getDefaultValue();
                String key = setting.getSettingKey();
                
                if (setting instanceof BooleanSetting) {
                    editor.putBoolean(key, (Boolean) defaultValue);
                } else if (setting instanceof SelectableValueSetting) {
                    editor.putInt(key, (Integer) defaultValue);
                } else if (setting instanceof ChatPositionSetting) {
                    editor.putBoolean(key, false);
                }
            }
        }
        
        editor.apply();
    }

    public static void openSettingsMenu() {
        activity = AppContext.getActivity();
        if (activity == null) {
            Log.e("arzmod-settings-module", "Activity is null (openSettingsMenu)");
            return;
        }

        SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(activity);
        settingsList = getSettingsList(sharedPreferences);

        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        
        LinearLayout titleLayout = new LinearLayout(activity);
        titleLayout.setOrientation(LinearLayout.HORIZONTAL);
        titleLayout.setGravity(Gravity.CENTER_VERTICAL);
        titleLayout.setPadding(20, 20, 20, 20);
        
        TextView titleView = new TextView(activity);
        titleView.setText("Настройки ARZMOD");
        titleView.setTextSize(20);
        titleView.setTextColor(Color.WHITE);
        titleView.setTypeface(null, android.graphics.Typeface.BOLD);
        
        View spacer = new View(activity);
        LinearLayout.LayoutParams spacerParams = new LinearLayout.LayoutParams(0, 0, 1f);
        spacer.setLayoutParams(spacerParams);
        
        android.widget.Button resetButton = new android.widget.Button(activity);
        resetButton.setText("🔄 Сброс");
        resetButton.setTextSize(12);
        resetButton.setTextColor(Color.WHITE);
        resetButton.setPadding(16, 8, 16, 8);
        resetButton.setElevation(2);
        
        android.widget.Button decompilerButton = new android.widget.Button(activity);
        decompilerButton.setText("🔧");
        decompilerButton.setTextSize(12);
        decompilerButton.setTextColor(Color.WHITE);
        decompilerButton.setPadding(16, 8, 16, 8);
        decompilerButton.setElevation(2);
        
        android.graphics.drawable.GradientDrawable buttonShape = new android.graphics.drawable.GradientDrawable();
        buttonShape.setShape(android.graphics.drawable.GradientDrawable.RECTANGLE);
        buttonShape.setCornerRadius(20);
        buttonShape.setColors(new int[]{
            Color.parseColor("#40666666"),
            Color.parseColor("#80666666")
        });
        buttonShape.setOrientation(android.graphics.drawable.GradientDrawable.Orientation.TOP_BOTTOM);
        resetButton.setBackground(buttonShape);
        decompilerButton.setBackground(buttonShape);
        
        titleLayout.addView(titleView);
        titleLayout.addView(spacer);
        titleLayout.addView(decompilerButton);
        titleLayout.addView(resetButton);
        
        builder.setCustomTitle(titleLayout);

        LinearLayout mainLayout = new LinearLayout(activity);
        mainLayout.setOrientation(LinearLayout.VERTICAL);
        mainLayout.setPadding(0, 20, 0, 20);

        TextView descriptionView = new TextView(activity);
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

        View divider = new View(activity);
        divider.setBackgroundColor(Color.parseColor("#4DFFFFFF"));
        divider.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 1));
        mainLayout.addView(divider);

        String packageName = activity.getPackageName();

        for (AbstractSetting setting : settingsList) {
            setting.setCallback(new SettingChangeCallback() {
                @Override
                public boolean onSettingChange(String key, Object newValue, Object oldValue) {
                    if (key.equals(IS_MODE_MODS)) {
                        boolean isEnabled = (Boolean) newValue;
                        if (isEnabled) {
                            new AlertDialog.Builder(activity)
                                .setTitle("Проверка обновлений кеша игры")
                                .setMessage("Перезапустите лаунчер для корректной работы.")
                                .setPositiveButton("OK", null)
                                .show();
                        } else {
                            UpdateServicePatch.setHomeUi(false);
                        }
                    } else if (key.equals(GAME_VERSION)) {
                        Integer choosenVersion = (Integer) newValue;
                        if(choosenVersion != BuildConfig.VERSION_CODE)
                        {
                            new AlertDialog.Builder(activity)
                                .setTitle("Устаревшая версия игры")
                                .setMessage("Некоторые функции, такие как Скрытие строки версии и Позиция чата могут не работать на старых версиях. Если ваша игра вылетает, проверьте данные настройки")
                                .setPositiveButton("OK", null)
                                .show();
                        } 

                    } else if (key.equals(IS_DEV_HUNGRY)) {
                        boolean isEnabled = (Boolean) newValue;
                        if (isEnabled) {
                            AppAds.hideBanner();
                        } else {
                            Toast.makeText(activity, "Спасибо за поддержку! :>", Toast.LENGTH_SHORT).show();
                            AppAds.showBanner();
                        }
                    } 
                    return true;
                }
            });
            
            View settingView = setting.createView(activity);
            if (settingView.getParent() != null) {
                ((ViewGroup) settingView.getParent()).removeView(settingView);
            }
            mainLayout.addView(settingView);
            
            View itemDivider = new View(activity);
            itemDivider.setBackgroundColor(Color.parseColor("#4DFFFFFF"));
            itemDivider.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 1));
            mainLayout.addView(itemDivider);
        }

        android.widget.ScrollView scrollView = new android.widget.ScrollView(activity);
        scrollView.addView(mainLayout);

        builder.setView(scrollView);
        builder.setPositiveButton("Закрыть", null);

        AlertDialog dialog = builder.create();
        if (dialog.getWindow() != null) {
			dialog.getWindow().setBackgroundDrawable(BackgroundBlur.getBlurredBackgroundDarkened(activity, 25f, 0.25f));
        }
        
        resetButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showResetConfirmationDialog(activity, sharedPreferences, dialog);
            }
        });
        
        decompilerButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                dialog.dismiss();
                LuaJITDecompiler.showDecompiler(true, true);
            }
        });
        
        dialog.show();

        titleView = dialog.findViewById(android.R.id.title);
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
        return PreferenceManager.getDefaultSharedPreferences(context).getBoolean(key, false);
    }

    public static final int getSettingsKeyInt(String key) { 
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-settings-module", "Context is null (getSettingsKeyInt)");
            return 0;
        }

        if (settingsList == null) {
            SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(context);
            settingsList = getSettingsList(sharedPreferences);
        }

        if (settingsList != null) {
            for (AbstractSetting setting : settingsList) {
                if (setting.getSettingKey().equals(key)) {
                    if (setting instanceof SelectableValueSetting) {
                        return (int)setting.getCurrentValue();
                    }
                    break;
                }
            }
            
        }

        return PreferenceManager.getDefaultSharedPreferences(context).getInt(key, 0);
    }

    public static void dumpAllSettingsKeys() {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-settings-module", "Context is null (dumpAllSettingsKeys)");
            return;
        }

        if (settingsList == null) {
            SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(context);
            settingsList = getSettingsList(sharedPreferences);
        }

        if (settingsList != null) {
            Log.d("arzmod-settings-module", "User settings:");
            Log.d("arzmod-settings-module", "+----------------------+----------------------+-----------------+----------------+");
            Log.d("arzmod-settings-module", "| Key                  | Title                | Type            | Value          |");
            Log.d("arzmod-settings-module", "+----------------------+----------------------+-----------------+----------------+");
            
            for (AbstractSetting setting : settingsList) {
                String key = setting.getSettingKey();
                String title = setting.getTitle();
                Object value = setting.getCurrentValue();
                String type = setting.getClass().getSimpleName();
                
                String shortKey = key.length() > 20 ? key.substring(0, 17) + "..." : key;
                String shortTitle = title.length() > 20 ? title.substring(0, 17) + "..." : title;
                String shortType = type.length() > 15 ? type.substring(0, 12) + "..." : type;
                
                String displayValue;
                if (setting instanceof SelectableValueSetting) {
                    SelectableValueSetting selectableSetting = (SelectableValueSetting) setting;
                    displayValue = selectableSetting.getCurrentValueText() + " (" + value + ")";
                } else {
                    displayValue = String.valueOf(value);
                }
                
                if (displayValue.length() > 14) {
                    displayValue = displayValue.substring(0, 11) + "...";
                }
                
                String tableRow = String.format("| %-20s | %-20s | %-15s | %-14s |", shortKey, shortTitle, shortType, displayValue);
                Log.d("arzmod-settings-module", tableRow);
            }
            
            Log.d("arzmod-settings-module", "+----------------------+----------------------+-----------------+----------------+");
        } else {
            Log.e("arzmod-settings-module", "User settings: list is null");
        }
    }

    public static void shareLogs() {
        activity = AppContext.getActivity();
        if (activity == null) {
            Log.e("arzmod-settings-module", "Activity is null (shareLogs)");
            return;
        }

        File externalFilesDir = activity.getExternalFilesDir(null);
        if (externalFilesDir == null) {
            Log.e("arzmod-settings-module", "External files directory is null");
            return;
        }

        String packageName = activity.getPackageName();
        List<File> logFiles = new ArrayList<>();
        logFiles.add(new File(externalFilesDir, "logcat/samp.log"));
        logFiles.add(new File(externalFilesDir, "AZVoice/azvoice.log"));
        logFiles.add(new File(externalFilesDir, "logcat/client.log"));
        logFiles.add(new File(activity.getExternalMediaDirs()[0], "monetloader/logs/monetloader.log"));

        List<File> existingLogs = new ArrayList<>();
        for (File file : logFiles) {
            if (file.exists() && file.length() > 0) {
                existingLogs.add(file);
            }
        }

        if (existingLogs.isEmpty()) {
            Toast.makeText(activity, "Логи не найдены", Toast.LENGTH_SHORT).show();
            return;
        }

        Intent shareIntent = new Intent(Intent.ACTION_SEND_MULTIPLE);
        shareIntent.setType("*/*");
        shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

        ArrayList<Uri> uris = new ArrayList<>();
        for (File file : existingLogs) {
            uris.add(FileProvider.getUriForFile(activity, packageName + ".fileprovider", file));
        }

        shareIntent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris);
        activity.startActivity(Intent.createChooser(shareIntent, "Отправить логи"));
    }

    private static CharSequence createClickableLinksFromDescription(String description) {
        if (description == null) return "";
        SpannableString spannable = new SpannableString(description);
        java.util.regex.Pattern urlPattern = java.util.regex.Pattern.compile("(https?://[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=%]+)");
        java.util.regex.Matcher matcher = urlPattern.matcher(description);
        while (matcher.find()) {
            final String url = matcher.group(1);
            int start = matcher.start(1);
            int end = matcher.end(1);
            spannable.setSpan(new ClickableSpan() {
                @Override
                public void onClick(View widget) {
                    Activity activity = AppContext.getActivity();
                    if(activity == null) Log.e("arzmod-settings-module", "Activity is null (clickablespan)");
                    else
                    {
                        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                        activity.startActivity(intent);
                    }
                }
                @Override
                public void updateDrawState(TextPaint ds) {
                    ds.setColor(Color.CYAN);
                    ds.setUnderlineText(true);
                }
            }, start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        }
        return spannable;
    }

    public static class BackgroundBlur {
        public static Drawable getBlurredBackground(Activity activity, float radius) {
            try {
                java.io.InputStream is = activity.getAssets().open("background_home.webp");
                Drawable base = Drawable.createFromStream(is, null);
                Bitmap bmp = drawableToBitmap(base);
                Bitmap blurred = blurBitmap(activity, bmp, radius);
                return new BitmapDrawable(activity.getResources(), blurred);
            } catch (Throwable t) {
                return new ColorDrawable(Color.parseColor("#B3000000"));
            }
        }

        public static Drawable getBlurredBackgroundDarkened(Activity activity, float radius, float darkenAlpha) {
            try {
                java.io.InputStream is = activity.getAssets().open("background_home.webp");
                Drawable base = Drawable.createFromStream(is, null);
                Bitmap bmp = drawableToBitmap(base);
                Bitmap blurred = blurBitmap(activity, bmp, radius);
                Bitmap out = blurred.copy(Bitmap.Config.ARGB_8888, true);
                int a = Math.max(0, Math.min(255, (int)(darkenAlpha * 255f)));
                android.graphics.Canvas canvas = new android.graphics.Canvas(out);
                canvas.drawColor(Color.argb(a, 0, 0, 0));
                return new BitmapDrawable(activity.getResources(), out);
            } catch (Throwable t) {
                return new ColorDrawable(Color.parseColor("#B3000000"));
            }
        }

        private static Bitmap drawableToBitmap(Drawable drawable) {
            if (drawable instanceof BitmapDrawable) {
                Bitmap bm = ((BitmapDrawable) drawable).getBitmap();
                if (bm != null) return bm;
            }
            int w = Math.max(2, drawable.getIntrinsicWidth());
            int h = Math.max(2, drawable.getIntrinsicHeight());
            Bitmap bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
            android.graphics.Canvas canvas = new android.graphics.Canvas(bmp);
            drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
            drawable.draw(canvas);
            return bmp;
        }

        private static Bitmap blurBitmap(Context context, Bitmap source, float radius) {
            float r = Math.max(1f, Math.min(25f, radius));
            try {
                android.renderscript.RenderScript rs = android.renderscript.RenderScript.create(context);
                android.renderscript.Allocation inAlloc = android.renderscript.Allocation.createFromBitmap(rs, source);
                Bitmap out = Bitmap.createBitmap(source.getWidth(), source.getHeight(), Bitmap.Config.ARGB_8888);
                android.renderscript.Allocation outAlloc = android.renderscript.Allocation.createFromBitmap(rs, out);
                android.renderscript.ScriptIntrinsicBlur blur = android.renderscript.ScriptIntrinsicBlur.create(rs, android.renderscript.Element.U8_4(rs));
                blur.setRadius(r);
                blur.setInput(inAlloc);
                blur.forEach(outAlloc);
                outAlloc.copyTo(out);
                rs.destroy();
                return out;
            } catch (Throwable t) {
                return source;
            }
        }
    }
}