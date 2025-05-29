# Компиляция Native части ARZMOD

## ⚠️ ВАЖНОЕ ПРЕДУПРЕЖДЕНИЕ
Если вы не знакомы с нативной разработкой для Android или не уверены в своих действиях, **настоятельно рекомендуется** использовать готовую библиотеку из `native/libs`. Неправильная компиляция может привести к неработоспособности мода.

## 📋 Требования
- Android NDK (рекомендуется r23e)
- Базовые знания C++ и Android нативной разработки

## 🚀 Компиляция

### 1️⃣ Подготовка
```bash
cd native/jni
```

### 2️⃣ Создание Android.mk
Создайте файл `Android.mk` со следующим содержимым:
```makefile
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := dobby
LOCAL_SRC_FILES := dobby/lib/$(TARGET_ARCH_ABI)/libdobby.a
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/dobby/include
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := arzmod
LOCAL_SRC_FILES := utils/addresses.cpp utils/armhook.cpp main.cpp packetsfix.cpp gamefixes.cpp

LOCAL_STATIC_LIBRARIES := dobby
LOCAL_C_INCLUDES += $(LOCAL_PATH)/dobby/include

LOCAL_LDLIBS += -llog -ldl -lstdc++

include $(BUILD_SHARED_LIBRARY)
```

### 3️⃣ Компиляция
```bash
ndk-build
```

## ⚙️ Настройка profile.json
После компиляции **обязательно** настройте `resource/profile.json`:
```json
{
    "gtasa_name": "libGTASA.so",
    "profile_name": "Profile Example",
    "compat_scripts": ["arzmod.lua", "user.lua"],
    "samp_name": "libsamp.so",
    "receiveignorerpc_pattern": "укажите реальный паттерн функции",
    "cnetgame_ctor_pattern": "укажите реальный паттерн функции",
    "rakclientinterface_netgame_offset": 528,
    "use_samp_touch_workaround": true,
    "nveventinsertnewest_offset": 2606320
}
```

## 🐛 Возможные проблемы
1. ❌ Ошибка компиляции - проверьте версию NDK
2. ❌ MonetLoader не работает - проверьте корректность profile.json
3. ❌ Крэш при запуске - проверьте совместимость версий

## ⚠️ Ответственность
Помните, что самостоятельная компиляция нативной части может привести к нестабильной работе мода. Если вы не уверены в своих действиях, используйте готовую библиотеку.
