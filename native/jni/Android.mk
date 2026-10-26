LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

# dobby static lib
LOCAL_MODULE := dobby
LOCAL_SRC_FILES := dobby/lib/$(TARGET_ARCH_ABI)/libdobby.a
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/dobby/include
include $(PREBUILT_STATIC_LIBRARY)

# Main native module
ifeq ($(TARGET_ARCH_ABI), armeabi-v7a)
    include $(CLEAR_VARS)
    ifeq ($(TARGET_BUILD_TYPE),release)
        LOCAL_CFLAGS += -DRELEASE_BUILD=1
        $(info ARZMOD Native Release)
        $(info Cache clearance)
        ifeq ($(OS),Windows_NT)
            $(shell rmdir /s /q "$(LOCAL_PATH)/../obj")
            $(shell rmdir /s /q "$(LOCAL_PATH)/../libs")
        else
            $(shell rm -rf $(LOCAL_PATH)/../obj)
            $(shell rm -rf $(LOCAL_PATH)/../libs)
        endif
    else
        LOCAL_CFLAGS += -DDEBUG_BUILD=1
        $(info ARZMOD Native Debug)
    endif
    LOCAL_MODULE := arzmod
    LOCAL_SRC_FILES := utils/addresses.cpp utils/armhook.cpp main.cpp monetloader.cpp packetsfix.cpp gamefixes.cpp
else ifeq ($(TARGET_ARCH_ABI), arm64-v8a)
    include $(CLEAR_VARS)
    ifeq ($(TARGET_BUILD_TYPE),release)
        LOCAL_CFLAGS += -DRELEASE_BUILD=1
        $(info ARZMOD Native Release)
        $(info Cache clearance)
        ifeq ($(OS),Windows_NT)
            $(shell rmdir /s /q "$(LOCAL_PATH)/../obj")
            $(shell rmdir /s /q "$(LOCAL_PATH)/../libs")
        else
            $(shell rm -rf $(LOCAL_PATH)/../obj)
            $(shell rm -rf $(LOCAL_PATH)/../libs)
        endif
    else
        LOCAL_CFLAGS += -DDEBUG_BUILD=1
        $(info ARZMOD Native Debug)
    endif
    LOCAL_MODULE := arzmod
    LOCAL_SRC_FILES := utils/addresses.cpp utils/armhook.cpp main.cpp monetloader.cpp gamefixes.cpp
endif

LOCAL_STATIC_LIBRARIES := dobby
LOCAL_C_INCLUDES += $(LOCAL_PATH)/dobby/include

LOCAL_CPPFLAGS += -fexceptions -frtti
LOCAL_LDLIBS += -llog -ldl -lstdc++

include $(BUILD_SHARED_LIBRARY)
