-- Part of the @osp_x Android Lua library for MonetLoader.
-- JNI utility functions with a semi-safe wrapper for easier Java interaction
-- More info: t.me/monetbinder

local ffi = require("ffi")
local activity = require("android.jni-raw").activity
local env = require("android.jnienv")

local M = {
    classCache = {},
}

function M.ActivityClassloader()
    if M.classloader then
        return M.classloader
    end
 
    local cldr = M.CallObjectMethod(activity, "getClassLoader", "()Ljava/lang/ClassLoader;")
    M.classloader = env.NewGlobalRef(cldr)
    env.DeleteLocalRef(cldr)
 
    local classLoaderClass = env.FindClass("java/lang/ClassLoader")

    M.loadClassMethodId = env.GetMethodID(classLoaderClass, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;")

    return M.classloader
end

--- Находит Java класс по имени.
---@param class string Полное имя класса (включая пакет)
---@param cldr? jobject Загрузчик классов (необязательно)
---@return jclass @Найденный класс
function M.FindClass(class, cldr)
    if M.classCache[class] then
        return M.classCache[class]
    end
 
    local cldr = cldr or M.ActivityClassloader()
    local classStr = env.NewStringUTF(class)
    local clazz = env.CallObjectMethod_safe(
        cldr,
        M.loadClassMethodId,
        env.NewStringUTF(class)
    )
 
    M.classCache[class] = ffi.cast('jclass', env.NewGlobalRef(clazz))
    env.DeleteLocalRef(classStr)
    env.DeleteLocalRef(clazz)
 
    return M.classCache[class]
end
--- Get the class of an object or class name, and check if it is nil.
---@return jclass class
---@return boolean needToDeleteLocalRef
local function getClass(objectOrClass)
    if objectOrClass == nil then
        error("clazz is nil")
    end

    if type(objectOrClass) == "string" then
        return M.FindClass(objectOrClass), false
    elseif not ffi.istype("jclass", objectOrClass) then
        return env.GetObjectClass_safe(objectOrClass), true
    else
        return objectOrClass, false
    end
end

--- Вызывает конструктор Java класса.
---@param class string|jclass Имя класса или объект класса
---@param signature string Сигнатура конструктора
---@param ... any Аргументы для конструктора
---@return jobject @Созданный объект
function M.CallConstructor(class, signature, ...)
    local clazz, needToDeleteLocalRef = getClass(class)
    
    if clazz == nil then
        error("Failed to get class")
    end

    local methodID = env.GetMethodID_safe(clazz, "<init>", signature)

    local obj = env.NewObject_safe(clazz, methodID, ...)

    if needToDeleteLocalRef then env.DeleteLocalRef(clazz) end
    return obj
end

--- Вызывает void метод Java объекта.
---@param object jobject Java объект
---@param method string Имя метода
---@param signature string Сигнатура метода
---@param ... any Аргументы метода
function M.CallVoidMethod(object, method, signature, ...)
    local clazz = env.GetObjectClass_safe(object)
    local methodID = env.GetMethodID_safe(clazz, method, signature)
    env.CallVoidMethod_safe(object, methodID, ...)
    env.DeleteLocalRef(clazz)
end

--- Вызывает статический void метод Java класса.
---@param class string|jclass Имя класса или объект класса
---@param method string Имя метода
---@param signature string Сигнатура метода
---@param ... any Аргументы метода
function M.CallStaticVoidMethod(class, method, signature, ...)
    local clazz, del = getClass(class)
    local methodID = env.GetStaticMethodID_safe(clazz, method, signature)
    env.CallStaticVoidMethod_safe(clazz, methodID, ...)

    if del then env.DeleteLocalRef(clazz) end
end

--- Вызывает int метод Java объекта.
---@param object jobject Java объект
---@param method string Имя метода
---@param signature string Сигнатура метода
---@param ... any Аргументы метода
---@return number Результат вызова метода
function M.CallIntMethod(object, method, signature, ...)
    local clazz = env.GetObjectClass_safe(object)
    local methodID = env.GetMethodID_safe(clazz, method, signature)
    local result = env.CallIntMethod_safe(object, methodID, ...)
    env.DeleteLocalRef(clazz)
    return result
end

--- Вызывает статический int метод Java класса.
---@param class string|jclass Имя класса или объект класса
---@param method string Имя метода
---@param signature string Сигнатура метода
---@param ... any Аргументы метода
---@return number Результат вызова метода
function M.CallStaticIntMethod(class, method, signature, ...)
    local clazz, del = getClass(class)
    local methodID = env.GetStaticMethodID_safe(clazz, method, signature)
    local result = env.CallStaticIntMethod_safe(clazz, methodID, ...)

    if del then env.DeleteLocalRef(clazz) end
    return result
end

--- Вызывает long метод Java объекта.
---@param object jobject Java объект
---@param method string Имя метода
---@param signature string Сигнатура метода
---@param ... any Аргументы метода
---@return number @Результат вызова метода
function M.CallLongMethod(object, method, signature, ...)
    local clazz = env.GetObjectClass_safe(object)
    local methodID = env.GetMethodID_safe(clazz, method, signature)
    local result = env.CallLongMethod_safe(object, methodID, ...)
    env.DeleteLocalRef(clazz)
    return result
end

--- Вызывает статический long метод Java класса.
---@param class string|jclass Имя класса или объект класса
---@param method string Имя метода
---@param signature string Сигнатура метода
---@param ... any Аргументы метода
---@return number @Результат вызова метода
function M.CallStaticLongMethod(class, method, signature, ...)
    local clazz, del = getClass(class)
    local methodID = env.GetStaticMethodID_safe(clazz, method, signature)
    local result = env.CallStaticLongMethod_safe(clazz, methodID, ...)
    
    if del then env.DeleteLocalRef(clazz) end
    return result
end

--- Вызывает boolean метод Java объекта.
---@param object jobject Java объект
---@param method string Имя метода
---@param signature string Сигнатура метода
---@param ... any Аргументы метода
---@return boolean @Результат вызова метода
function M.CallBooleanMethod(object, method, signature, ...)
    local clazz = env.GetObjectClass_safe(object)
    local methodID = env.GetMethodID_safe(clazz, method, signature)
    local result = env.CallBooleanMethod_safe(object, methodID, ...)
    env.DeleteLocalRef(clazz)
    return result
end

--- Вызывает статический boolean метод Java класса.
---@param class string|jclass Имя класса или объект класса
---@param method string Имя метода
---@param signature string Сигнатура метода
---@param ... any Аргументы метода
---@return boolean @Результат вызова метода
function M.CallStaticBooleanMethod(class, method, signature, ...)
    local clazz, del = getClass(class)
    local methodID = env.GetStaticMethodID_safe(clazz, method, signature)
    local result = env.CallStaticBooleanMethod_safe(clazz, methodID, ...)
    
    if del then env.DeleteLocalRef(clazz) end
    return result
end

--- Вызывает Object метод Java объекта.
---@param object jobject Java объект
---@param method string Имя метода
---@param signature string Сигнатура метода
---@param ... any Аргументы метода
---@return jobject @Результат вызова метода
function M.CallObjectMethod(object, method, signature, ...)
    local clazz = env.GetObjectClass_safe(object)
    local methodID = env.GetMethodID_safe(clazz, method, signature)
    local result = env.CallObjectMethod_safe(object, methodID, ...)
    env.DeleteLocalRef(clazz)
    return result
end

--- Вызывает статический Object метод Java класса.
---@param class string|jclass Имя класса или объект класса
---@param method string Имя метода
---@param signature string Сигнатура метода
---@param ... any Аргументы метода
---@return jobject @Результат вызова метода
function M.CallStaticObjectMethod(class, method, signature, ...)
    local clazz, del = getClass(class)
    local methodID = env.GetStaticMethodID_safe(clazz, method, signature)
    local result = env.CallStaticObjectMethod_safe(clazz, methodID, ...)
    
    if del then env.DeleteLocalRef(clazz) end
    return result
end

--- Вызывает float метод Java объекта.
---@param object jobject Java объект
---@param method string Имя метода
---@param signature string Сигнатура метода
---@param ... any Аргументы метода
---@return number @Результат вызова метода
function M.CallFloatMethod(object, method, signature, ...)
    local clazz = env.GetObjectClass_safe(object)
    local methodID = env.GetMethodID_safe(clazz, method, signature)
    local result = env.CallFloatMethod_safe(object, methodID, ...)
    env.DeleteLocalRef(clazz)
    return result
end

--- Получает статическое поле Object из Java класса.
---@param class string|jclass Имя класса или объект класса
---@param field string Имя поля
---@param signature string Сигнатура поля
---@return jobject @Значение поля
function M.GetStaticObjectField(class, field, signature)
    local clazz, del = getClass(class)
    local fieldID = env.GetStaticFieldID_safe(clazz, field, signature)
    local result = env.GetStaticObjectField_safe(clazz, fieldID)
    
    if del then env.DeleteLocalRef(clazz) end
    return result
end

--- Получает поле Object из Java объекта.
---@param object jobject Java объект
---@param field string Имя поля
---@param signature string Сигнатура поля
---@return jobject @Значение поля
function M.GetObjectField(object, field, signature)
    local clazz = env.GetObjectClass_safe(object)
    local fieldID = env.GetFieldID_safe(clazz, field, signature)
    local result = env.GetObjectField_safe(object, fieldID)
    env.DeleteLocalRef(clazz)
    return result
end

--- Устанавливает значение поля Object в Java объекте.
---@param object jobject Java объект
---@param field string Имя поля
---@param signature string Сигнатура поля
---@param value jobject Новое значение поля
function M.SetObjectField(object, field, signature, value)
    local clazz = env.GetObjectClass_safe(object)
    local fieldID = env.GetFieldID_safe(clazz, field, signature)
    env.SetObjectField_safe(object, fieldID, value)
    env.DeleteLocalRef(clazz)
end

--- Устанавливает значение статического поля Object в Java классе.
---@param class string|jclass Имя класса или объект класса
---@param field string Имя поля
---@param signature string Сигнатура поля
---@param value jobject Новое значение поля
function M.SetStaticObjectField(class, field, signature, value)
    local clazz, del = getClass(class)
    local fieldID = env.GetStaticFieldID_safe(clazz, field, signature)
    env.SetStaticObjectField_safe(clazz, fieldID, value)
    
    if del then env.DeleteLocalRef(clazz) end
end

--- Преобразует Java строку в Lua строку.
---@param jstr jobject Java строка
---@return string Lua строка
function M.FromJString(jstr)
    local str = env.GetStringUTFChars(jstr, nil)
    local result = ffi.string(str)
    env.ReleaseStringUTFChars(jstr, str)
    return result
end

--- Создает Java Integer объект из Lua числа.
---@param number number Lua число
---@return jobject Java Integer объект
function M.toJavaInteger(number)
    return M.CallConstructor("java/lang/Integer", "(I)V", number)
end

M.ToastFlag = {
    LENGTH_SHORT = 0,
    LENGTH_LONG = 1,
}

--- Создает и возвращает объект Toast с методами для управления.<br/>
--- Перед использованием убедитесь, что перед этим хотя бы раз вызывали LooperPrepare.
---@param message string Сообщение для отображения
---@param duration? number Длительность отображения (по умолчанию SHORT)
function M.Toast(message, duration)
    local text = env.NewStringUTF(message)
    local duration = duration or M.ToastFlag.LENGTH_LONG
    local ltoast = M.CallStaticObjectMethod(
       "android/widget/Toast",
        "makeText",
        "(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;",
        activity,
        text,
        duration
    )
    local toast = ffi.cast('jobject', env.NewGlobalRef(ltoast)) ---@cast toast jobject
    env.DeleteLocalRef(text)
    env.DeleteLocalRef(ltoast)

    local self = {}
    function self.show()
        M.CallVoidMethod(toast, "show", "()V")
        return self
    end
    function self.cancel()
        M.CallVoidMethod(toast, "cancel", "()V")
        return self
    end
    function self.setText(message)
        local text = env.NewStringUTF(message)
        M.CallVoidMethod(toast, "setText", "(Ljava/lang/CharSequence;)V", text)
        env.DeleteLocalRef(text)
        return self
    end
    function self.setDuration(duration)
        M.CallVoidMethod(toast, "setDuration", "(I)V", duration)
        return self
    end
    function self.setGravity(gravity, xOffset, yOffset)
        M.CallVoidMethod(toast, "setGravity", "(III)V", gravity, xOffset, yOffset)
        return self
    end
    function self.setMargin(horizontalMargin, verticalMargin)
        M.CallVoidMethod(toast, "setMargin", "(FF)V", horizontalMargin, verticalMargin)
        return self
    end

    setmetatable(self, {
        __gc = function()
            env.DeleteGlobalRef(toast)
        end
    })

    return self
end

--- Подготавливает Looper для текущего потока, если он еще не подготовлен.
function M.LooperPrepare()
    local Looper = "android/os/Looper"
    local looper = M.CallStaticObjectMethod(
        Looper,
        "myLooper",
        "()Landroid/os/Looper;"
    )
    
    if looper == nil then
        M.CallStaticVoidMethod(
            Looper,
            "prepare",
            "()V"
        )
    end
end

---@enum SystemService
M.SystemService = {
    ACCESSIBILITY_SERVICE = "accessibility",
    ACCOUNT_SERVICE = "account",
    ACTIVITY_SERVICE = "activity",
    ALARM_SERVICE = "alarm",
    APPWIDGET_SERVICE = "appwidget",
    APP_OPS_SERVICE = "appops",
    AUDIO_SERVICE = "audio",
    BATTERY_SERVICE = "batterymanager",
    BLUETOOTH_SERVICE = "bluetooth",
    CAMERA_SERVICE = "camera",
    CAPTIONING_SERVICE = "captioning",
    CARRIER_CONFIG_SERVICE = "carrier_config",
    CLIPBOARD_SERVICE = "clipboard",
    CONNECTIVITY_SERVICE = "connectivity",
    CONSUMER_IR_SERVICE = "consumer_ir",
    DEVICE_POLICY_SERVICE = "device_policy",
    DISPLAY_SERVICE = "display",
    DOWNLOAD_SERVICE = "download",
    DROPBOX_SERVICE = "dropbox",
    INPUT_METHOD_SERVICE = "input_method",
    INPUT_SERVICE = "input",
    JOB_SCHEDULER_SERVICE = "jobscheduler",
    KEYGUARD_SERVICE = "keyguard",
    LAUNCHER_APPS_SERVICE = "launcherapps",
    LAYOUT_INFLATER_SERVICE = "layout_inflater",
    LOCATION_SERVICE = "location",
    MEDIA_PROJECTION_SERVICE = "media_projection",
    MEDIA_ROUTER_SERVICE = "media_router",
    MEDIA_SESSION_SERVICE = "media_session",
    MIDI_SERVICE = "midi",
    NETWORK_STATS_SERVICE = "netstats",
    NFC_SERVICE = "nfc",
    NOTIFICATION_SERVICE = "notification",
    NSD_SERVICE = "servicediscovery",
    POWER_SERVICE = "power",
    PRINT_SERVICE = "print",
    RESTRICTIONS_SERVICE = "restrictions",
    SEARCH_SERVICE = "search",
    SENSOR_SERVICE = "sensor",
    STORAGE_SERVICE = "storage",
    TELECOM_SERVICE = "telecom",
    TELEPHONY_SERVICE = "phone",
    TELEPHONY_SUBSCRIPTION_SERVICE = "telephony_subscription_service",
    TEXT_SERVICES_MANAGER_SERVICE = "textservices",
    TV_INPUT_SERVICE = "tv_input",
    UI_MODE_SERVICE = "uimode",
    USAGE_STATS_SERVICE = "usagestats",
    USB_SERVICE = "usb",
    USER_SERVICE = "user",
    VIBRATOR_SERVICE = "vibrator",
    WALLPAPER_SERVICE = "wallpaper",
    WIFI_P2P_SERVICE = "wifip2p",
    WIFI_SERVICE = "wifi",
    WINDOW_SERVICE = "window",
}

--- Получает системный сервис по его имени.
---@param service SystemService Имя сервиса
---@return jobject @Объект системного сервиса
function M.GetSystemService(service)
    local name = env.NewStringUTF(service)
    local res = M.CallObjectMethod(
        activity,
        "getSystemService",
        "(Ljava/lang/String;)Ljava/lang/Object;",
        name
    )
    env.DeleteLocalRef(name)

    return res
end

function copyFile(source, destination)
    local inputFile = io.open(source, "rb")
    if not inputFile then
        return false, "Can't open source file: " .. source
    end

    local outputFile = io.open(destination, "wb")
    if not outputFile then
        inputFile:close()
        return false, "Can't create destination file: " .. destination
    end

    local ok = true
    local errMsg = nil
    local totalWritten = 0

    while true do
        local block = inputFile:read(8192)
        if not block then break end

        local written = outputFile:write(block)
        if not written then
            ok = false
            errMsg = "Write failed (disk full?)"
            break
        end
        totalWritten = totalWritten + #block
    end

    inputFile:close()
    outputFile:close()

    local checkFile = io.open(destination, "rb")
    if checkFile then
        local actualSize = checkFile:seek("end")
        checkFile:close()
        if actualSize ~= totalWritten then
            return false, "File size mismatch after copy"
        end
    end

    return ok, errMsg
end

function getFilenameFromPath(path)
    return path:match("^.+/(.+)$")
end

--- Инжектит JAR-файл и вызывает указанный статический метод.<br/>
---<br/>
--- Эта функция загружает JAR-файл, находит указанный класс и вызывает<br/>
--- статический метод из этого класса.<br/>
---<br/>
--- @param jarPath string Путь к JAR-файлу для инжекции
--- @param className string Полное имя класса (включая пакет)
--- @param methodName string Имя статического метода для вызова
--- @param methodSignature string Сигнатура метода в формате JNI
--- @param ... any Дополнительные аргументы для передачи в метод
---
--- @return boolean success Флаг успешности операции
--- @return string|jclass result Если успешно, возвращает загруженный класс, иначе возвращает строку с описанием ошибки
--- @return jclass|nil dexClassLoader DexClassLoader, если операция успешна, иначе nil
 
function M.InjectJar(jarPath, className, methodName, methodSignature, ...)
    local activityClassLoader = M.ActivityClassloader()
    if not activityClassLoader then
        return false, "Activity class loader is nil"
    end

    local src = io.open(jarPath, "rb")
    if not src then
        return false, "JAR file not found at: " .. jarPath
    end
    src:close()

	local codeCacheDir = M.CallObjectMethod(activity, "getCodeCacheDir", "()Ljava/io/File;")
	local codeCachePath = M.CallObjectMethod(codeCacheDir, "getAbsolutePath", "()Ljava/lang/String;")
	local codeCachePathStr = M.FromJString(codeCachePath)
    local cacheDir = M.CallObjectMethod(activity, "getCacheDir", "()Ljava/io/File;")
    local cachePath = M.CallObjectMethod(cacheDir, "getAbsolutePath", "()Ljava/lang/String;")
    local cachePathStr = M.FromJString(cachePath)
    local destJarPath = codeCachePathStr .. "/" ..getFilenameFromPath(jarPath)
    local dest = io.open(destJarPath, "rb")
	if dest then
	    dest:close()
	    os.remove(destJarPath)
	end


    local ok, err = copyFile(jarPath, destJarPath)
    if not ok then return false, err end
    

	local FileClass = M.FindClass("java/io/File")
	local fileObj = M.CallConstructor(FileClass, "(Ljava/lang/String;)V", env.NewStringUTF(destJarPath))
	M.CallBooleanMethod(fileObj, "setReadOnly", "()Z")


    local ok, DexCldr = pcall(M.FindClass, "dalvik/system/DexClassLoader")
    if not ok then
        return false, "Failed to find DexClassLoader class"
    end

    local ok, dexCldr = pcall(M.CallConstructor,
        DexCldr,
        "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/ClassLoader;)V",
        env.NewStringUTF(destJarPath),
        env.NewStringUTF(cachePathStr),
        nil,
        activityClassLoader
    )
    if not ok then
        return false, "Failed to create DexClassLoader"
    end

    local loadedClass = M.FindClass(className, dexCldr)

    local ok, methodID = pcall(env.GetStaticMethodID_safe, loadedClass, methodName, methodSignature)
    if not ok then
        return false, "Failed to get method ID: " .. methodName
    end
    
    env.CallStaticVoidMethod_safe(loadedClass, methodID, ...)

    return true, loadedClass, dexCldr
end


return M