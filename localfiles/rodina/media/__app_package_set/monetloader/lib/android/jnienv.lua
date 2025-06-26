-- Part of the @osp_x Android Lua library for MonetLoader.
-- JNIEnv wrapper with exception handling and type definitions
-- Auto-generated.
-- More info: t.me/monetbinder

local JNIEnv = {}
local ffi = require("ffi")
local jni = require("android.jni-raw")
local C = jni.const

---@alias jboolean boolean
---@alias jbyte number
---@alias jchar number
---@alias jshort number
---@alias jint number
---@alias jlong number
---@alias jfloat number
---@alias jdouble number
---@alias jsize number
---@alias jobject jclass | jstring | jarray | string
---@class jclass
---@class jstring
---@class jarray
---@class jobjectArray
---@class jbooleanArray
---@class jbyteArray
---@class jcharArray
---@class jshortArray
---@class jintArray
---@class jlongArray
---@class jfloatArray
---@class jdoubleArray
---@class jthrowable
---@class jweak
---@class jfieldID
---@class jmethodID

---@class jvalue
---@field z jboolean
---@field b jbyte
---@field c jchar
---@field s jshort
---@field i jint
---@field j jlong
---@field f jfloat
---@field d jdouble
---@field l jobject

---@class jobjectRefType
---@field JNIInvalidRefType number
---@field JNILocalRefType number
---@field JNIGlobalRefType number
---@field JNIWeakGlobalRefType number

---@class JNINativeMethod
---@field name string
---@field signature string
---@field fnPtr void

---@class va_list
---@class void
---@class void*

function JNIEnv.checkExceptions()
    if JNIEnv.ExceptionCheck() == C.JNI_TRUE then
        local e = JNIEnv.ExceptionOccurred()
        JNIEnv.ExceptionClear() -- clears the exception; e seems to remain valid

        if e == nil then
            error("ExceptionCheck() returned JNI_TRUE but ExceptionOccurred() returned nil")
        end

        local clazz = JNIEnv.GetObjectClass(e)
        local getMessage = JNIEnv.GetMethodID(clazz, "getMessage", "()Ljava/lang/String;")
        local message = JNIEnv.CallObjectMethod(e, getMessage)
        local mstr = JNIEnv.GetStringUTFChars(message, nil)
        -- do whatever with mstr
        local msg = ffi.string(mstr)
        JNIEnv.ReleaseStringUTFChars(message, mstr)
        JNIEnv.DeleteLocalRef(message)
        JNIEnv.DeleteLocalRef(clazz)
        JNIEnv.DeleteLocalRef(e)

        error(msg)
    end
end

--- jint GetVersion(JNIEnv *env);
--- @return jint
function JNIEnv.GetVersion()
    return jni.env[0].GetVersion(jni.env)
end
    
--- jclass DefineClass(JNIEnv *env, const char *name, jobject loader, const jbyte *buf, jsize len);
--- @param name string
--- @param loader jobject
--- @param buf string
--- @param len jsize
--- @return jclass
function JNIEnv.DefineClass(name, loader, buf, len)
    return jni.env[0].DefineClass(jni.env, name, loader, buf, len)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of DefineClass
--- @param name string
--- @param loader jobject
--- @param buf string
--- @param len jsize
--- @return jclass
function JNIEnv.DefineClass_safe(name, loader, buf, len)
    local result = JNIEnv.DefineClass(name, loader, buf, len)
    JNIEnv.checkExceptions()
    return result
end
        
--- jclass FindClass(JNIEnv *env, const char *name);
--- @param name string
--- @return jclass
function JNIEnv.FindClass(name)
    return jni.env[0].FindClass(jni.env, name)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of FindClass
--- @param name string
--- @return jclass
function JNIEnv.FindClass_safe(name)
    local result = JNIEnv.FindClass(name)
    JNIEnv.checkExceptions()
    return result
end
        
--- jmethodID FromReflectedMethod(JNIEnv *env, jobject method);
--- @param method jobject
--- @return jmethodID
function JNIEnv.FromReflectedMethod(method)
    return jni.env[0].FromReflectedMethod(jni.env, method)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of FromReflectedMethod
--- @param method jobject
--- @return jmethodID
function JNIEnv.FromReflectedMethod_safe(method)
    local result = JNIEnv.FromReflectedMethod(method)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfieldID FromReflectedField(JNIEnv *env, jobject field);
--- @param field jobject
--- @return jfieldID
function JNIEnv.FromReflectedField(field)
    return jni.env[0].FromReflectedField(jni.env, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of FromReflectedField
--- @param field jobject
--- @return jfieldID
function JNIEnv.FromReflectedField_safe(field)
    local result = JNIEnv.FromReflectedField(field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject ToReflectedMethod(JNIEnv *env, jclass cls, jmethodID method, jboolean isStatic);
--- @param cls jclass
--- @param method jmethodID
--- @param isStatic jboolean
--- @return jobject
function JNIEnv.ToReflectedMethod(cls, method, isStatic)
    return jni.env[0].ToReflectedMethod(jni.env, cls, method, isStatic)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ToReflectedMethod
--- @param cls jclass
--- @param method jmethodID
--- @param isStatic jboolean
--- @return jobject
function JNIEnv.ToReflectedMethod_safe(cls, method, isStatic)
    local result = JNIEnv.ToReflectedMethod(cls, method, isStatic)
    JNIEnv.checkExceptions()
    return result
end
        
--- jclass GetSuperclass(JNIEnv *env, jclass cls);
--- @param cls jclass
--- @return jclass
function JNIEnv.GetSuperclass(cls)
    return jni.env[0].GetSuperclass(jni.env, cls)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetSuperclass
--- @param cls jclass
--- @return jclass
function JNIEnv.GetSuperclass_safe(cls)
    local result = JNIEnv.GetSuperclass(cls)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean IsAssignableFrom(JNIEnv *env, jclass cls1, jclass cls2);
--- @param cls1 jclass
--- @param cls2 jclass
--- @return jboolean
function JNIEnv.IsAssignableFrom(cls1, cls2)
    return jni.env[0].IsAssignableFrom(jni.env, cls1, cls2)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of IsAssignableFrom
--- @param cls1 jclass
--- @param cls2 jclass
--- @return jboolean
function JNIEnv.IsAssignableFrom_safe(cls1, cls2)
    local result = JNIEnv.IsAssignableFrom(cls1, cls2)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject ToReflectedField(JNIEnv *env, jclass cls, jfieldID field, jboolean isStatic);
--- @param cls jclass
--- @param field jfieldID
--- @param isStatic jboolean
--- @return jobject
function JNIEnv.ToReflectedField(cls, field, isStatic)
    return jni.env[0].ToReflectedField(jni.env, cls, field, isStatic)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ToReflectedField
--- @param cls jclass
--- @param field jfieldID
--- @param isStatic jboolean
--- @return jobject
function JNIEnv.ToReflectedField_safe(cls, field, isStatic)
    local result = JNIEnv.ToReflectedField(cls, field, isStatic)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint Throw(JNIEnv *env, jthrowable obj);
--- @param obj jthrowable
--- @return jint
function JNIEnv.Throw(obj)
    return jni.env[0].Throw(jni.env, obj)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of Throw
--- @param obj jthrowable
--- @return jint
function JNIEnv.Throw_safe(obj)
    local result = JNIEnv.Throw(obj)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint ThrowNew(JNIEnv *env, jclass cls, const char *msg);
--- @param cls jclass
--- @param msg string
--- @return jint
function JNIEnv.ThrowNew(cls, msg)
    return jni.env[0].ThrowNew(jni.env, cls, msg)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ThrowNew
--- @param cls jclass
--- @param msg string
--- @return jint
function JNIEnv.ThrowNew_safe(cls, msg)
    local result = JNIEnv.ThrowNew(cls, msg)
    JNIEnv.checkExceptions()
    return result
end
        
--- jthrowable ExceptionOccurred(JNIEnv *env);
--- @return jthrowable
function JNIEnv.ExceptionOccurred()
    return jni.env[0].ExceptionOccurred(jni.env)
end
    
--- void ExceptionDescribe(JNIEnv *env);
--- @return void
function JNIEnv.ExceptionDescribe()
    return jni.env[0].ExceptionDescribe(jni.env)
end
    
--- void ExceptionClear(JNIEnv *env);
--- @return void
function JNIEnv.ExceptionClear()
    return jni.env[0].ExceptionClear(jni.env)
end
    
--- void FatalError(JNIEnv *env, const char *msg);
--- @param msg string
--- @return void
function JNIEnv.FatalError(msg)
    return jni.env[0].FatalError(jni.env, msg)
end
    
--- jint PushLocalFrame(JNIEnv *env, jint capacity);
--- @param capacity jint
--- @return jint
function JNIEnv.PushLocalFrame(capacity)
    return jni.env[0].PushLocalFrame(jni.env, capacity)
end
    
--- jobject PopLocalFrame(JNIEnv *env, jobject result);
--- @param result jobject
--- @return jobject
function JNIEnv.PopLocalFrame(result)
    return jni.env[0].PopLocalFrame(jni.env, result)
end
    
--- jobject NewGlobalRef(JNIEnv *env, jobject obj);
--- @param obj jobject
--- @return jobject
function JNIEnv.NewGlobalRef(obj)
    return jni.env[0].NewGlobalRef(jni.env, obj)
end
    
--- void DeleteGlobalRef(JNIEnv *env, jobject obj);
--- @param obj jobject
--- @return void
function JNIEnv.DeleteGlobalRef(obj)
    return jni.env[0].DeleteGlobalRef(jni.env, obj)
end
    
--- void DeleteLocalRef(JNIEnv *env, jobject obj);
--- @param obj jobject
--- @return void
function JNIEnv.DeleteLocalRef(obj)
    return jni.env[0].DeleteLocalRef(jni.env, obj)
end
    
--- jboolean IsSameObject(JNIEnv *env, jobject obj1, jobject obj2);
--- @param obj1 jobject
--- @param obj2 jobject
--- @return jboolean
function JNIEnv.IsSameObject(obj1, obj2)
    return jni.env[0].IsSameObject(jni.env, obj1, obj2)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of IsSameObject
--- @param obj1 jobject
--- @param obj2 jobject
--- @return jboolean
function JNIEnv.IsSameObject_safe(obj1, obj2)
    local result = JNIEnv.IsSameObject(obj1, obj2)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject NewLocalRef(JNIEnv *env, jobject obj);
--- @param obj jobject
--- @return jobject
function JNIEnv.NewLocalRef(obj)
    return jni.env[0].NewLocalRef(jni.env, obj)
end
    
--- jint EnsureLocalCapacity(JNIEnv *env, jint capacity);
--- @param capacity jint
--- @return jint
function JNIEnv.EnsureLocalCapacity(capacity)
    return jni.env[0].EnsureLocalCapacity(jni.env, capacity)
end
    
--- jobject AllocObject(JNIEnv *env, jclass cls);
--- @param cls jclass
--- @return jobject
function JNIEnv.AllocObject(cls)
    return jni.env[0].AllocObject(jni.env, cls)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of AllocObject
--- @param cls jclass
--- @return jobject
function JNIEnv.AllocObject_safe(cls)
    local result = JNIEnv.AllocObject(cls)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject NewObject(JNIEnv *env, jclass cls, jmethodID method, ...);
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jobject
function JNIEnv.NewObject(cls, method, ...)
    return jni.env[0].NewObject(jni.env, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewObject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jobject
function JNIEnv.NewObject_safe(cls, method, ...)
    local result = JNIEnv.NewObject(cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject NewObjectV(JNIEnv *env, jclass cls, jmethodID method, va_list args);
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jobject
function JNIEnv.NewObjectV(cls, method, args)
    return jni.env[0].NewObjectV(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewObjectV
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jobject
function JNIEnv.NewObjectV_safe(cls, method, args)
    local result = JNIEnv.NewObjectV(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject NewObjectA(JNIEnv *env, jclass cls, jmethodID method, const jvalue *args);
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jobject
function JNIEnv.NewObjectA(cls, method, args)
    return jni.env[0].NewObjectA(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewObjectA
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jobject
function JNIEnv.NewObjectA_safe(cls, method, args)
    local result = JNIEnv.NewObjectA(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jclass GetObjectClass(JNIEnv *env, jobject obj);
--- @param obj jobject
--- @return jclass
function JNIEnv.GetObjectClass(obj)
    return jni.env[0].GetObjectClass(jni.env, obj)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetObjectClass
--- @param obj jobject
--- @return jclass
function JNIEnv.GetObjectClass_safe(obj)
    local result = JNIEnv.GetObjectClass(obj)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean IsInstanceOf(JNIEnv *env, jobject obj, jclass cls);
--- @param obj jobject
--- @param cls jclass
--- @return jboolean
function JNIEnv.IsInstanceOf(obj, cls)
    return jni.env[0].IsInstanceOf(jni.env, obj, cls)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of IsInstanceOf
--- @param obj jobject
--- @param cls jclass
--- @return jboolean
function JNIEnv.IsInstanceOf_safe(obj, cls)
    local result = JNIEnv.IsInstanceOf(obj, cls)
    JNIEnv.checkExceptions()
    return result
end
        
--- jmethodID GetMethodID(JNIEnv *env, jclass cls, const char *name, const char *sig);
--- @param cls jclass
--- @param name string
--- @param sig string
--- @return jmethodID
function JNIEnv.GetMethodID(cls, name, sig)
    return jni.env[0].GetMethodID(jni.env, cls, name, sig)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetMethodID
--- @param cls jclass
--- @param name string
--- @param sig string
--- @return jmethodID
function JNIEnv.GetMethodID_safe(cls, name, sig)
    local result = JNIEnv.GetMethodID(cls, name, sig)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject CallObjectMethod(JNIEnv *env, jobject obj, jmethodID method, ...);
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jobject
function JNIEnv.CallObjectMethod(obj, method, ...)
    return jni.env[0].CallObjectMethod(jni.env, obj, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallObjectMethod
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jobject
function JNIEnv.CallObjectMethod_safe(obj, method, ...)
    local result = JNIEnv.CallObjectMethod(obj, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject CallObjectMethodV(JNIEnv *env, jobject obj, jmethodID method, va_list args);
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jobject
function JNIEnv.CallObjectMethodV(obj, method, args)
    return jni.env[0].CallObjectMethodV(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallObjectMethodV
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jobject
function JNIEnv.CallObjectMethodV_safe(obj, method, args)
    local result = JNIEnv.CallObjectMethodV(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject CallObjectMethodA(JNIEnv *env, jobject obj, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jobject
function JNIEnv.CallObjectMethodA(obj, method, args)
    return jni.env[0].CallObjectMethodA(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallObjectMethodA
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jobject
function JNIEnv.CallObjectMethodA_safe(obj, method, args)
    local result = JNIEnv.CallObjectMethodA(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean CallBooleanMethod(JNIEnv *env, jobject obj, jmethodID method, ...);
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jboolean
function JNIEnv.CallBooleanMethod(obj, method, ...)
    return jni.env[0].CallBooleanMethod(jni.env, obj, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallBooleanMethod
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jboolean
function JNIEnv.CallBooleanMethod_safe(obj, method, ...)
    local result = JNIEnv.CallBooleanMethod(obj, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean CallBooleanMethodV(JNIEnv *env, jobject obj, jmethodID method, va_list args);
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jboolean
function JNIEnv.CallBooleanMethodV(obj, method, args)
    return jni.env[0].CallBooleanMethodV(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallBooleanMethodV
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jboolean
function JNIEnv.CallBooleanMethodV_safe(obj, method, args)
    local result = JNIEnv.CallBooleanMethodV(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean CallBooleanMethodA(JNIEnv *env, jobject obj, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jboolean
function JNIEnv.CallBooleanMethodA(obj, method, args)
    return jni.env[0].CallBooleanMethodA(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallBooleanMethodA
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jboolean
function JNIEnv.CallBooleanMethodA_safe(obj, method, args)
    local result = JNIEnv.CallBooleanMethodA(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyte CallByteMethod(JNIEnv *env, jobject obj, jmethodID method, ...);
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jbyte
function JNIEnv.CallByteMethod(obj, method, ...)
    return jni.env[0].CallByteMethod(jni.env, obj, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallByteMethod
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jbyte
function JNIEnv.CallByteMethod_safe(obj, method, ...)
    local result = JNIEnv.CallByteMethod(obj, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyte CallByteMethodV(JNIEnv *env, jobject obj, jmethodID method, va_list args);
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jbyte
function JNIEnv.CallByteMethodV(obj, method, args)
    return jni.env[0].CallByteMethodV(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallByteMethodV
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jbyte
function JNIEnv.CallByteMethodV_safe(obj, method, args)
    local result = JNIEnv.CallByteMethodV(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyte CallByteMethodA(JNIEnv *env, jobject obj, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jbyte
function JNIEnv.CallByteMethodA(obj, method, args)
    return jni.env[0].CallByteMethodA(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallByteMethodA
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jbyte
function JNIEnv.CallByteMethodA_safe(obj, method, args)
    local result = JNIEnv.CallByteMethodA(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jchar CallCharMethod(JNIEnv *env, jobject obj, jmethodID method, ...);
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jchar
function JNIEnv.CallCharMethod(obj, method, ...)
    return jni.env[0].CallCharMethod(jni.env, obj, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallCharMethod
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jchar
function JNIEnv.CallCharMethod_safe(obj, method, ...)
    local result = JNIEnv.CallCharMethod(obj, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jchar CallCharMethodV(JNIEnv *env, jobject obj, jmethodID method, va_list args);
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jchar
function JNIEnv.CallCharMethodV(obj, method, args)
    return jni.env[0].CallCharMethodV(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallCharMethodV
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jchar
function JNIEnv.CallCharMethodV_safe(obj, method, args)
    local result = JNIEnv.CallCharMethodV(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jchar CallCharMethodA(JNIEnv *env, jobject obj, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jchar
function JNIEnv.CallCharMethodA(obj, method, args)
    return jni.env[0].CallCharMethodA(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallCharMethodA
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jchar
function JNIEnv.CallCharMethodA_safe(obj, method, args)
    local result = JNIEnv.CallCharMethodA(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshort CallShortMethod(JNIEnv *env, jobject obj, jmethodID method, ...);
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jshort
function JNIEnv.CallShortMethod(obj, method, ...)
    return jni.env[0].CallShortMethod(jni.env, obj, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallShortMethod
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jshort
function JNIEnv.CallShortMethod_safe(obj, method, ...)
    local result = JNIEnv.CallShortMethod(obj, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshort CallShortMethodV(JNIEnv *env, jobject obj, jmethodID method, va_list args);
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jshort
function JNIEnv.CallShortMethodV(obj, method, args)
    return jni.env[0].CallShortMethodV(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallShortMethodV
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jshort
function JNIEnv.CallShortMethodV_safe(obj, method, args)
    local result = JNIEnv.CallShortMethodV(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshort CallShortMethodA(JNIEnv *env, jobject obj, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jshort
function JNIEnv.CallShortMethodA(obj, method, args)
    return jni.env[0].CallShortMethodA(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallShortMethodA
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jshort
function JNIEnv.CallShortMethodA_safe(obj, method, args)
    local result = JNIEnv.CallShortMethodA(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint CallIntMethod(JNIEnv *env, jobject obj, jmethodID method, ...);
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jint
function JNIEnv.CallIntMethod(obj, method, ...)
    return jni.env[0].CallIntMethod(jni.env, obj, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallIntMethod
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jint
function JNIEnv.CallIntMethod_safe(obj, method, ...)
    local result = JNIEnv.CallIntMethod(obj, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint CallIntMethodV(JNIEnv *env, jobject obj, jmethodID method, va_list args);
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jint
function JNIEnv.CallIntMethodV(obj, method, args)
    return jni.env[0].CallIntMethodV(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallIntMethodV
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jint
function JNIEnv.CallIntMethodV_safe(obj, method, args)
    local result = JNIEnv.CallIntMethodV(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint CallIntMethodA(JNIEnv *env, jobject obj, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jint
function JNIEnv.CallIntMethodA(obj, method, args)
    return jni.env[0].CallIntMethodA(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallIntMethodA
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jint
function JNIEnv.CallIntMethodA_safe(obj, method, args)
    local result = JNIEnv.CallIntMethodA(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlong CallLongMethod(JNIEnv *env, jobject obj, jmethodID method, ...);
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jlong
function JNIEnv.CallLongMethod(obj, method, ...)
    return jni.env[0].CallLongMethod(jni.env, obj, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallLongMethod
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jlong
function JNIEnv.CallLongMethod_safe(obj, method, ...)
    local result = JNIEnv.CallLongMethod(obj, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlong CallLongMethodV(JNIEnv *env, jobject obj, jmethodID method, va_list args);
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jlong
function JNIEnv.CallLongMethodV(obj, method, args)
    return jni.env[0].CallLongMethodV(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallLongMethodV
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jlong
function JNIEnv.CallLongMethodV_safe(obj, method, args)
    local result = JNIEnv.CallLongMethodV(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlong CallLongMethodA(JNIEnv *env, jobject obj, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jlong
function JNIEnv.CallLongMethodA(obj, method, args)
    return jni.env[0].CallLongMethodA(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallLongMethodA
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jlong
function JNIEnv.CallLongMethodA_safe(obj, method, args)
    local result = JNIEnv.CallLongMethodA(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloat CallFloatMethod(JNIEnv *env, jobject obj, jmethodID method, ...);
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jfloat
function JNIEnv.CallFloatMethod(obj, method, ...)
    return jni.env[0].CallFloatMethod(jni.env, obj, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallFloatMethod
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jfloat
function JNIEnv.CallFloatMethod_safe(obj, method, ...)
    local result = JNIEnv.CallFloatMethod(obj, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloat CallFloatMethodV(JNIEnv *env, jobject obj, jmethodID method, va_list args);
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jfloat
function JNIEnv.CallFloatMethodV(obj, method, args)
    return jni.env[0].CallFloatMethodV(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallFloatMethodV
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jfloat
function JNIEnv.CallFloatMethodV_safe(obj, method, args)
    local result = JNIEnv.CallFloatMethodV(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloat CallFloatMethodA(JNIEnv *env, jobject obj, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jfloat
function JNIEnv.CallFloatMethodA(obj, method, args)
    return jni.env[0].CallFloatMethodA(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallFloatMethodA
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jfloat
function JNIEnv.CallFloatMethodA_safe(obj, method, args)
    local result = JNIEnv.CallFloatMethodA(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdouble CallDoubleMethod(JNIEnv *env, jobject obj, jmethodID method, ...);
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jdouble
function JNIEnv.CallDoubleMethod(obj, method, ...)
    return jni.env[0].CallDoubleMethod(jni.env, obj, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallDoubleMethod
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return jdouble
function JNIEnv.CallDoubleMethod_safe(obj, method, ...)
    local result = JNIEnv.CallDoubleMethod(obj, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdouble CallDoubleMethodV(JNIEnv *env, jobject obj, jmethodID method, va_list args);
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jdouble
function JNIEnv.CallDoubleMethodV(obj, method, args)
    return jni.env[0].CallDoubleMethodV(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallDoubleMethodV
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return jdouble
function JNIEnv.CallDoubleMethodV_safe(obj, method, args)
    local result = JNIEnv.CallDoubleMethodV(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdouble CallDoubleMethodA(JNIEnv *env, jobject obj, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jdouble
function JNIEnv.CallDoubleMethodA(obj, method, args)
    return jni.env[0].CallDoubleMethodA(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallDoubleMethodA
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return jdouble
function JNIEnv.CallDoubleMethodA_safe(obj, method, args)
    local result = JNIEnv.CallDoubleMethodA(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- void CallVoidMethod(JNIEnv *env, jobject obj, jmethodID method, ...);
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return void
function JNIEnv.CallVoidMethod(obj, method, ...)
    return jni.env[0].CallVoidMethod(jni.env, obj, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallVoidMethod
--- @param obj jobject
--- @param method jmethodID
--- @param ... jobject
--- @return void
function JNIEnv.CallVoidMethod_safe(obj, method, ...)
    local result = JNIEnv.CallVoidMethod(obj, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- void CallVoidMethodV(JNIEnv *env, jobject obj, jmethodID method, va_list args);
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return void
function JNIEnv.CallVoidMethodV(obj, method, args)
    return jni.env[0].CallVoidMethodV(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallVoidMethodV
--- @param obj jobject
--- @param method jmethodID
--- @param args va_list
--- @return void
function JNIEnv.CallVoidMethodV_safe(obj, method, args)
    local result = JNIEnv.CallVoidMethodV(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- void CallVoidMethodA(JNIEnv *env, jobject obj, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return void
function JNIEnv.CallVoidMethodA(obj, method, args)
    return jni.env[0].CallVoidMethodA(jni.env, obj, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallVoidMethodA
--- @param obj jobject
--- @param method jmethodID
--- @param args jvalue
--- @return void
function JNIEnv.CallVoidMethodA_safe(obj, method, args)
    local result = JNIEnv.CallVoidMethodA(obj, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject CallNonvirtualObjectMethod(JNIEnv *env, jobject obj, jclass cls, jmethodID method, ...);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jobject
function JNIEnv.CallNonvirtualObjectMethod(obj, cls, method, ...)
    return jni.env[0].CallNonvirtualObjectMethod(jni.env, obj, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualObjectMethod
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jobject
function JNIEnv.CallNonvirtualObjectMethod_safe(obj, cls, method, ...)
    local result = JNIEnv.CallNonvirtualObjectMethod(obj, cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject CallNonvirtualObjectMethodV(JNIEnv *env, jobject obj, jclass cls, jmethodID method, va_list args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jobject
function JNIEnv.CallNonvirtualObjectMethodV(obj, cls, method, args)
    return jni.env[0].CallNonvirtualObjectMethodV(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualObjectMethodV
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jobject
function JNIEnv.CallNonvirtualObjectMethodV_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualObjectMethodV(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject CallNonvirtualObjectMethodA(JNIEnv *env, jobject obj, jclass cls, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jobject
function JNIEnv.CallNonvirtualObjectMethodA(obj, cls, method, args)
    return jni.env[0].CallNonvirtualObjectMethodA(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualObjectMethodA
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jobject
function JNIEnv.CallNonvirtualObjectMethodA_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualObjectMethodA(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean CallNonvirtualBooleanMethod(JNIEnv *env, jobject obj, jclass cls, jmethodID method, ...);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jboolean
function JNIEnv.CallNonvirtualBooleanMethod(obj, cls, method, ...)
    return jni.env[0].CallNonvirtualBooleanMethod(jni.env, obj, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualBooleanMethod
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jboolean
function JNIEnv.CallNonvirtualBooleanMethod_safe(obj, cls, method, ...)
    local result = JNIEnv.CallNonvirtualBooleanMethod(obj, cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean CallNonvirtualBooleanMethodV(JNIEnv *env, jobject obj, jclass cls, jmethodID method, va_list args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jboolean
function JNIEnv.CallNonvirtualBooleanMethodV(obj, cls, method, args)
    return jni.env[0].CallNonvirtualBooleanMethodV(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualBooleanMethodV
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jboolean
function JNIEnv.CallNonvirtualBooleanMethodV_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualBooleanMethodV(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean CallNonvirtualBooleanMethodA(JNIEnv *env, jobject obj, jclass cls, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jboolean
function JNIEnv.CallNonvirtualBooleanMethodA(obj, cls, method, args)
    return jni.env[0].CallNonvirtualBooleanMethodA(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualBooleanMethodA
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jboolean
function JNIEnv.CallNonvirtualBooleanMethodA_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualBooleanMethodA(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyte CallNonvirtualByteMethod(JNIEnv *env, jobject obj, jclass cls, jmethodID method, ...);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jbyte
function JNIEnv.CallNonvirtualByteMethod(obj, cls, method, ...)
    return jni.env[0].CallNonvirtualByteMethod(jni.env, obj, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualByteMethod
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jbyte
function JNIEnv.CallNonvirtualByteMethod_safe(obj, cls, method, ...)
    local result = JNIEnv.CallNonvirtualByteMethod(obj, cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyte CallNonvirtualByteMethodV(JNIEnv *env, jobject obj, jclass cls, jmethodID method, va_list args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jbyte
function JNIEnv.CallNonvirtualByteMethodV(obj, cls, method, args)
    return jni.env[0].CallNonvirtualByteMethodV(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualByteMethodV
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jbyte
function JNIEnv.CallNonvirtualByteMethodV_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualByteMethodV(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyte CallNonvirtualByteMethodA(JNIEnv *env, jobject obj, jclass cls, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jbyte
function JNIEnv.CallNonvirtualByteMethodA(obj, cls, method, args)
    return jni.env[0].CallNonvirtualByteMethodA(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualByteMethodA
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jbyte
function JNIEnv.CallNonvirtualByteMethodA_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualByteMethodA(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jchar CallNonvirtualCharMethod(JNIEnv *env, jobject obj, jclass cls, jmethodID method, ...);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jchar
function JNIEnv.CallNonvirtualCharMethod(obj, cls, method, ...)
    return jni.env[0].CallNonvirtualCharMethod(jni.env, obj, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualCharMethod
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jchar
function JNIEnv.CallNonvirtualCharMethod_safe(obj, cls, method, ...)
    local result = JNIEnv.CallNonvirtualCharMethod(obj, cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jchar CallNonvirtualCharMethodV(JNIEnv *env, jobject obj, jclass cls, jmethodID method, va_list args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jchar
function JNIEnv.CallNonvirtualCharMethodV(obj, cls, method, args)
    return jni.env[0].CallNonvirtualCharMethodV(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualCharMethodV
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jchar
function JNIEnv.CallNonvirtualCharMethodV_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualCharMethodV(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jchar CallNonvirtualCharMethodA(JNIEnv *env, jobject obj, jclass cls, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jchar
function JNIEnv.CallNonvirtualCharMethodA(obj, cls, method, args)
    return jni.env[0].CallNonvirtualCharMethodA(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualCharMethodA
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jchar
function JNIEnv.CallNonvirtualCharMethodA_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualCharMethodA(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshort CallNonvirtualShortMethod(JNIEnv *env, jobject obj, jclass cls, jmethodID method, ...);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jshort
function JNIEnv.CallNonvirtualShortMethod(obj, cls, method, ...)
    return jni.env[0].CallNonvirtualShortMethod(jni.env, obj, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualShortMethod
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jshort
function JNIEnv.CallNonvirtualShortMethod_safe(obj, cls, method, ...)
    local result = JNIEnv.CallNonvirtualShortMethod(obj, cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshort CallNonvirtualShortMethodV(JNIEnv *env, jobject obj, jclass cls, jmethodID method, va_list args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jshort
function JNIEnv.CallNonvirtualShortMethodV(obj, cls, method, args)
    return jni.env[0].CallNonvirtualShortMethodV(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualShortMethodV
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jshort
function JNIEnv.CallNonvirtualShortMethodV_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualShortMethodV(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshort CallNonvirtualShortMethodA(JNIEnv *env, jobject obj, jclass cls, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jshort
function JNIEnv.CallNonvirtualShortMethodA(obj, cls, method, args)
    return jni.env[0].CallNonvirtualShortMethodA(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualShortMethodA
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jshort
function JNIEnv.CallNonvirtualShortMethodA_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualShortMethodA(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint CallNonvirtualIntMethod(JNIEnv *env, jobject obj, jclass cls, jmethodID method, ...);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jint
function JNIEnv.CallNonvirtualIntMethod(obj, cls, method, ...)
    return jni.env[0].CallNonvirtualIntMethod(jni.env, obj, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualIntMethod
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jint
function JNIEnv.CallNonvirtualIntMethod_safe(obj, cls, method, ...)
    local result = JNIEnv.CallNonvirtualIntMethod(obj, cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint CallNonvirtualIntMethodV(JNIEnv *env, jobject obj, jclass cls, jmethodID method, va_list args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jint
function JNIEnv.CallNonvirtualIntMethodV(obj, cls, method, args)
    return jni.env[0].CallNonvirtualIntMethodV(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualIntMethodV
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jint
function JNIEnv.CallNonvirtualIntMethodV_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualIntMethodV(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint CallNonvirtualIntMethodA(JNIEnv *env, jobject obj, jclass cls, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jint
function JNIEnv.CallNonvirtualIntMethodA(obj, cls, method, args)
    return jni.env[0].CallNonvirtualIntMethodA(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualIntMethodA
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jint
function JNIEnv.CallNonvirtualIntMethodA_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualIntMethodA(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlong CallNonvirtualLongMethod(JNIEnv *env, jobject obj, jclass cls, jmethodID method, ...);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jlong
function JNIEnv.CallNonvirtualLongMethod(obj, cls, method, ...)
    return jni.env[0].CallNonvirtualLongMethod(jni.env, obj, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualLongMethod
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jlong
function JNIEnv.CallNonvirtualLongMethod_safe(obj, cls, method, ...)
    local result = JNIEnv.CallNonvirtualLongMethod(obj, cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlong CallNonvirtualLongMethodV(JNIEnv *env, jobject obj, jclass cls, jmethodID method, va_list args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jlong
function JNIEnv.CallNonvirtualLongMethodV(obj, cls, method, args)
    return jni.env[0].CallNonvirtualLongMethodV(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualLongMethodV
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jlong
function JNIEnv.CallNonvirtualLongMethodV_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualLongMethodV(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlong CallNonvirtualLongMethodA(JNIEnv *env, jobject obj, jclass cls, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jlong
function JNIEnv.CallNonvirtualLongMethodA(obj, cls, method, args)
    return jni.env[0].CallNonvirtualLongMethodA(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualLongMethodA
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jlong
function JNIEnv.CallNonvirtualLongMethodA_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualLongMethodA(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloat CallNonvirtualFloatMethod(JNIEnv *env, jobject obj, jclass cls, jmethodID method, ...);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jfloat
function JNIEnv.CallNonvirtualFloatMethod(obj, cls, method, ...)
    return jni.env[0].CallNonvirtualFloatMethod(jni.env, obj, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualFloatMethod
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jfloat
function JNIEnv.CallNonvirtualFloatMethod_safe(obj, cls, method, ...)
    local result = JNIEnv.CallNonvirtualFloatMethod(obj, cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloat CallNonvirtualFloatMethodV(JNIEnv *env, jobject obj, jclass cls, jmethodID method, va_list args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jfloat
function JNIEnv.CallNonvirtualFloatMethodV(obj, cls, method, args)
    return jni.env[0].CallNonvirtualFloatMethodV(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualFloatMethodV
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jfloat
function JNIEnv.CallNonvirtualFloatMethodV_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualFloatMethodV(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloat CallNonvirtualFloatMethodA(JNIEnv *env, jobject obj, jclass cls, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jfloat
function JNIEnv.CallNonvirtualFloatMethodA(obj, cls, method, args)
    return jni.env[0].CallNonvirtualFloatMethodA(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualFloatMethodA
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jfloat
function JNIEnv.CallNonvirtualFloatMethodA_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualFloatMethodA(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdouble CallNonvirtualDoubleMethod(JNIEnv *env, jobject obj, jclass cls, jmethodID method, ...);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jdouble
function JNIEnv.CallNonvirtualDoubleMethod(obj, cls, method, ...)
    return jni.env[0].CallNonvirtualDoubleMethod(jni.env, obj, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualDoubleMethod
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jdouble
function JNIEnv.CallNonvirtualDoubleMethod_safe(obj, cls, method, ...)
    local result = JNIEnv.CallNonvirtualDoubleMethod(obj, cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdouble CallNonvirtualDoubleMethodV(JNIEnv *env, jobject obj, jclass cls, jmethodID method, va_list args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jdouble
function JNIEnv.CallNonvirtualDoubleMethodV(obj, cls, method, args)
    return jni.env[0].CallNonvirtualDoubleMethodV(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualDoubleMethodV
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jdouble
function JNIEnv.CallNonvirtualDoubleMethodV_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualDoubleMethodV(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdouble CallNonvirtualDoubleMethodA(JNIEnv *env, jobject obj, jclass cls, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jdouble
function JNIEnv.CallNonvirtualDoubleMethodA(obj, cls, method, args)
    return jni.env[0].CallNonvirtualDoubleMethodA(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualDoubleMethodA
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jdouble
function JNIEnv.CallNonvirtualDoubleMethodA_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualDoubleMethodA(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- void CallNonvirtualVoidMethod(JNIEnv *env, jobject obj, jclass cls, jmethodID method, ...);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return void
function JNIEnv.CallNonvirtualVoidMethod(obj, cls, method, ...)
    return jni.env[0].CallNonvirtualVoidMethod(jni.env, obj, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualVoidMethod
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return void
function JNIEnv.CallNonvirtualVoidMethod_safe(obj, cls, method, ...)
    local result = JNIEnv.CallNonvirtualVoidMethod(obj, cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- void CallNonvirtualVoidMethodV(JNIEnv *env, jobject obj, jclass cls, jmethodID method, va_list args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return void
function JNIEnv.CallNonvirtualVoidMethodV(obj, cls, method, args)
    return jni.env[0].CallNonvirtualVoidMethodV(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualVoidMethodV
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return void
function JNIEnv.CallNonvirtualVoidMethodV_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualVoidMethodV(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- void CallNonvirtualVoidMethodA(JNIEnv *env, jobject obj, jclass cls, jmethodID method, const jvalue *args);
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return void
function JNIEnv.CallNonvirtualVoidMethodA(obj, cls, method, args)
    return jni.env[0].CallNonvirtualVoidMethodA(jni.env, obj, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallNonvirtualVoidMethodA
--- @param obj jobject
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return void
function JNIEnv.CallNonvirtualVoidMethodA_safe(obj, cls, method, args)
    local result = JNIEnv.CallNonvirtualVoidMethodA(obj, cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfieldID GetFieldID(JNIEnv *env, jclass cls, const char *name, const char *sig);
--- @param cls jclass
--- @param name string
--- @param sig string
--- @return jfieldID
function JNIEnv.GetFieldID(cls, name, sig)
    return jni.env[0].GetFieldID(jni.env, cls, name, sig)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetFieldID
--- @param cls jclass
--- @param name string
--- @param sig string
--- @return jfieldID
function JNIEnv.GetFieldID_safe(cls, name, sig)
    local result = JNIEnv.GetFieldID(cls, name, sig)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject GetObjectField(JNIEnv *env, jobject obj, jfieldID field);
--- @param obj jobject
--- @param field jfieldID
--- @return jobject
function JNIEnv.GetObjectField(obj, field)
    return jni.env[0].GetObjectField(jni.env, obj, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetObjectField
--- @param obj jobject
--- @param field jfieldID
--- @return jobject
function JNIEnv.GetObjectField_safe(obj, field)
    local result = JNIEnv.GetObjectField(obj, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean GetBooleanField(JNIEnv *env, jobject obj, jfieldID field);
--- @param obj jobject
--- @param field jfieldID
--- @return jboolean
function JNIEnv.GetBooleanField(obj, field)
    return jni.env[0].GetBooleanField(jni.env, obj, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetBooleanField
--- @param obj jobject
--- @param field jfieldID
--- @return jboolean
function JNIEnv.GetBooleanField_safe(obj, field)
    local result = JNIEnv.GetBooleanField(obj, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyte GetByteField(JNIEnv *env, jobject obj, jfieldID field);
--- @param obj jobject
--- @param field jfieldID
--- @return jbyte
function JNIEnv.GetByteField(obj, field)
    return jni.env[0].GetByteField(jni.env, obj, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetByteField
--- @param obj jobject
--- @param field jfieldID
--- @return jbyte
function JNIEnv.GetByteField_safe(obj, field)
    local result = JNIEnv.GetByteField(obj, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jchar GetCharField(JNIEnv *env, jobject obj, jfieldID field);
--- @param obj jobject
--- @param field jfieldID
--- @return jchar
function JNIEnv.GetCharField(obj, field)
    return jni.env[0].GetCharField(jni.env, obj, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetCharField
--- @param obj jobject
--- @param field jfieldID
--- @return jchar
function JNIEnv.GetCharField_safe(obj, field)
    local result = JNIEnv.GetCharField(obj, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshort GetShortField(JNIEnv *env, jobject obj, jfieldID field);
--- @param obj jobject
--- @param field jfieldID
--- @return jshort
function JNIEnv.GetShortField(obj, field)
    return jni.env[0].GetShortField(jni.env, obj, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetShortField
--- @param obj jobject
--- @param field jfieldID
--- @return jshort
function JNIEnv.GetShortField_safe(obj, field)
    local result = JNIEnv.GetShortField(obj, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint GetIntField(JNIEnv *env, jobject obj, jfieldID field);
--- @param obj jobject
--- @param field jfieldID
--- @return jint
function JNIEnv.GetIntField(obj, field)
    return jni.env[0].GetIntField(jni.env, obj, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetIntField
--- @param obj jobject
--- @param field jfieldID
--- @return jint
function JNIEnv.GetIntField_safe(obj, field)
    local result = JNIEnv.GetIntField(obj, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlong GetLongField(JNIEnv *env, jobject obj, jfieldID field);
--- @param obj jobject
--- @param field jfieldID
--- @return jlong
function JNIEnv.GetLongField(obj, field)
    return jni.env[0].GetLongField(jni.env, obj, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetLongField
--- @param obj jobject
--- @param field jfieldID
--- @return jlong
function JNIEnv.GetLongField_safe(obj, field)
    local result = JNIEnv.GetLongField(obj, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloat GetFloatField(JNIEnv *env, jobject obj, jfieldID field);
--- @param obj jobject
--- @param field jfieldID
--- @return jfloat
function JNIEnv.GetFloatField(obj, field)
    return jni.env[0].GetFloatField(jni.env, obj, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetFloatField
--- @param obj jobject
--- @param field jfieldID
--- @return jfloat
function JNIEnv.GetFloatField_safe(obj, field)
    local result = JNIEnv.GetFloatField(obj, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdouble GetDoubleField(JNIEnv *env, jobject obj, jfieldID field);
--- @param obj jobject
--- @param field jfieldID
--- @return jdouble
function JNIEnv.GetDoubleField(obj, field)
    return jni.env[0].GetDoubleField(jni.env, obj, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetDoubleField
--- @param obj jobject
--- @param field jfieldID
--- @return jdouble
function JNIEnv.GetDoubleField_safe(obj, field)
    local result = JNIEnv.GetDoubleField(obj, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetObjectField(JNIEnv *env, jobject obj, jfieldID field, jobject val);
--- @param obj jobject
--- @param field jfieldID
--- @param val jobject
--- @return void
function JNIEnv.SetObjectField(obj, field, val)
    return jni.env[0].SetObjectField(jni.env, obj, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetObjectField
--- @param obj jobject
--- @param field jfieldID
--- @param val jobject
--- @return void
function JNIEnv.SetObjectField_safe(obj, field, val)
    local result = JNIEnv.SetObjectField(obj, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetBooleanField(JNIEnv *env, jobject obj, jfieldID field, jboolean val);
--- @param obj jobject
--- @param field jfieldID
--- @param val jboolean
--- @return void
function JNIEnv.SetBooleanField(obj, field, val)
    return jni.env[0].SetBooleanField(jni.env, obj, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetBooleanField
--- @param obj jobject
--- @param field jfieldID
--- @param val jboolean
--- @return void
function JNIEnv.SetBooleanField_safe(obj, field, val)
    local result = JNIEnv.SetBooleanField(obj, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetByteField(JNIEnv *env, jobject obj, jfieldID field, jbyte val);
--- @param obj jobject
--- @param field jfieldID
--- @param val jbyte
--- @return void
function JNIEnv.SetByteField(obj, field, val)
    return jni.env[0].SetByteField(jni.env, obj, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetByteField
--- @param obj jobject
--- @param field jfieldID
--- @param val jbyte
--- @return void
function JNIEnv.SetByteField_safe(obj, field, val)
    local result = JNIEnv.SetByteField(obj, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetCharField(JNIEnv *env, jobject obj, jfieldID field, jchar val);
--- @param obj jobject
--- @param field jfieldID
--- @param val jchar
--- @return void
function JNIEnv.SetCharField(obj, field, val)
    return jni.env[0].SetCharField(jni.env, obj, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetCharField
--- @param obj jobject
--- @param field jfieldID
--- @param val jchar
--- @return void
function JNIEnv.SetCharField_safe(obj, field, val)
    local result = JNIEnv.SetCharField(obj, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetShortField(JNIEnv *env, jobject obj, jfieldID field, jshort val);
--- @param obj jobject
--- @param field jfieldID
--- @param val jshort
--- @return void
function JNIEnv.SetShortField(obj, field, val)
    return jni.env[0].SetShortField(jni.env, obj, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetShortField
--- @param obj jobject
--- @param field jfieldID
--- @param val jshort
--- @return void
function JNIEnv.SetShortField_safe(obj, field, val)
    local result = JNIEnv.SetShortField(obj, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetIntField(JNIEnv *env, jobject obj, jfieldID field, jint val);
--- @param obj jobject
--- @param field jfieldID
--- @param val jint
--- @return void
function JNIEnv.SetIntField(obj, field, val)
    return jni.env[0].SetIntField(jni.env, obj, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetIntField
--- @param obj jobject
--- @param field jfieldID
--- @param val jint
--- @return void
function JNIEnv.SetIntField_safe(obj, field, val)
    local result = JNIEnv.SetIntField(obj, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetLongField(JNIEnv *env, jobject obj, jfieldID field, jlong val);
--- @param obj jobject
--- @param field jfieldID
--- @param val jlong
--- @return void
function JNIEnv.SetLongField(obj, field, val)
    return jni.env[0].SetLongField(jni.env, obj, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetLongField
--- @param obj jobject
--- @param field jfieldID
--- @param val jlong
--- @return void
function JNIEnv.SetLongField_safe(obj, field, val)
    local result = JNIEnv.SetLongField(obj, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetFloatField(JNIEnv *env, jobject obj, jfieldID field, jfloat val);
--- @param obj jobject
--- @param field jfieldID
--- @param val jfloat
--- @return void
function JNIEnv.SetFloatField(obj, field, val)
    return jni.env[0].SetFloatField(jni.env, obj, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetFloatField
--- @param obj jobject
--- @param field jfieldID
--- @param val jfloat
--- @return void
function JNIEnv.SetFloatField_safe(obj, field, val)
    local result = JNIEnv.SetFloatField(obj, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetDoubleField(JNIEnv *env, jobject obj, jfieldID field, jdouble val);
--- @param obj jobject
--- @param field jfieldID
--- @param val jdouble
--- @return void
function JNIEnv.SetDoubleField(obj, field, val)
    return jni.env[0].SetDoubleField(jni.env, obj, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetDoubleField
--- @param obj jobject
--- @param field jfieldID
--- @param val jdouble
--- @return void
function JNIEnv.SetDoubleField_safe(obj, field, val)
    local result = JNIEnv.SetDoubleField(obj, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- jmethodID GetStaticMethodID(JNIEnv *env, jclass cls, const char *name, const char *sig);
--- @param cls jclass
--- @param name string
--- @param sig string
--- @return jmethodID
function JNIEnv.GetStaticMethodID(cls, name, sig)
    return jni.env[0].GetStaticMethodID(jni.env, cls, name, sig)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStaticMethodID
--- @param cls jclass
--- @param name string
--- @param sig string
--- @return jmethodID
function JNIEnv.GetStaticMethodID_safe(cls, name, sig)
    local result = JNIEnv.GetStaticMethodID(cls, name, sig)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject CallStaticObjectMethod(JNIEnv *env, jclass cls, jmethodID method, ...);
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jobject
function JNIEnv.CallStaticObjectMethod(cls, method, ...)
    return jni.env[0].CallStaticObjectMethod(jni.env, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticObjectMethod
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jobject
function JNIEnv.CallStaticObjectMethod_safe(cls, method, ...)
    local result = JNIEnv.CallStaticObjectMethod(cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject CallStaticObjectMethodV(JNIEnv *env, jclass cls, jmethodID method, va_list args);
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jobject
function JNIEnv.CallStaticObjectMethodV(cls, method, args)
    return jni.env[0].CallStaticObjectMethodV(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticObjectMethodV
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jobject
function JNIEnv.CallStaticObjectMethodV_safe(cls, method, args)
    local result = JNIEnv.CallStaticObjectMethodV(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject CallStaticObjectMethodA(JNIEnv *env, jclass cls, jmethodID method, const jvalue *args);
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jobject
function JNIEnv.CallStaticObjectMethodA(cls, method, args)
    return jni.env[0].CallStaticObjectMethodA(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticObjectMethodA
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jobject
function JNIEnv.CallStaticObjectMethodA_safe(cls, method, args)
    local result = JNIEnv.CallStaticObjectMethodA(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean CallStaticBooleanMethod(JNIEnv *env, jclass cls, jmethodID method, ...);
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jboolean
function JNIEnv.CallStaticBooleanMethod(cls, method, ...)
    return jni.env[0].CallStaticBooleanMethod(jni.env, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticBooleanMethod
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jboolean
function JNIEnv.CallStaticBooleanMethod_safe(cls, method, ...)
    local result = JNIEnv.CallStaticBooleanMethod(cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean CallStaticBooleanMethodV(JNIEnv *env, jclass cls, jmethodID method, va_list args);
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jboolean
function JNIEnv.CallStaticBooleanMethodV(cls, method, args)
    return jni.env[0].CallStaticBooleanMethodV(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticBooleanMethodV
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jboolean
function JNIEnv.CallStaticBooleanMethodV_safe(cls, method, args)
    local result = JNIEnv.CallStaticBooleanMethodV(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean CallStaticBooleanMethodA(JNIEnv *env, jclass cls, jmethodID method, const jvalue *args);
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jboolean
function JNIEnv.CallStaticBooleanMethodA(cls, method, args)
    return jni.env[0].CallStaticBooleanMethodA(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticBooleanMethodA
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jboolean
function JNIEnv.CallStaticBooleanMethodA_safe(cls, method, args)
    local result = JNIEnv.CallStaticBooleanMethodA(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyte CallStaticByteMethod(JNIEnv *env, jclass cls, jmethodID method, ...);
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jbyte
function JNIEnv.CallStaticByteMethod(cls, method, ...)
    return jni.env[0].CallStaticByteMethod(jni.env, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticByteMethod
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jbyte
function JNIEnv.CallStaticByteMethod_safe(cls, method, ...)
    local result = JNIEnv.CallStaticByteMethod(cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyte CallStaticByteMethodV(JNIEnv *env, jclass cls, jmethodID method, va_list args);
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jbyte
function JNIEnv.CallStaticByteMethodV(cls, method, args)
    return jni.env[0].CallStaticByteMethodV(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticByteMethodV
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jbyte
function JNIEnv.CallStaticByteMethodV_safe(cls, method, args)
    local result = JNIEnv.CallStaticByteMethodV(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyte CallStaticByteMethodA(JNIEnv *env, jclass cls, jmethodID method, const jvalue *args);
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jbyte
function JNIEnv.CallStaticByteMethodA(cls, method, args)
    return jni.env[0].CallStaticByteMethodA(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticByteMethodA
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jbyte
function JNIEnv.CallStaticByteMethodA_safe(cls, method, args)
    local result = JNIEnv.CallStaticByteMethodA(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jchar CallStaticCharMethod(JNIEnv *env, jclass cls, jmethodID method, ...);
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jchar
function JNIEnv.CallStaticCharMethod(cls, method, ...)
    return jni.env[0].CallStaticCharMethod(jni.env, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticCharMethod
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jchar
function JNIEnv.CallStaticCharMethod_safe(cls, method, ...)
    local result = JNIEnv.CallStaticCharMethod(cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jchar CallStaticCharMethodV(JNIEnv *env, jclass cls, jmethodID method, va_list args);
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jchar
function JNIEnv.CallStaticCharMethodV(cls, method, args)
    return jni.env[0].CallStaticCharMethodV(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticCharMethodV
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jchar
function JNIEnv.CallStaticCharMethodV_safe(cls, method, args)
    local result = JNIEnv.CallStaticCharMethodV(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jchar CallStaticCharMethodA(JNIEnv *env, jclass cls, jmethodID method, const jvalue *args);
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jchar
function JNIEnv.CallStaticCharMethodA(cls, method, args)
    return jni.env[0].CallStaticCharMethodA(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticCharMethodA
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jchar
function JNIEnv.CallStaticCharMethodA_safe(cls, method, args)
    local result = JNIEnv.CallStaticCharMethodA(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshort CallStaticShortMethod(JNIEnv *env, jclass cls, jmethodID method, ...);
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jshort
function JNIEnv.CallStaticShortMethod(cls, method, ...)
    return jni.env[0].CallStaticShortMethod(jni.env, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticShortMethod
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jshort
function JNIEnv.CallStaticShortMethod_safe(cls, method, ...)
    local result = JNIEnv.CallStaticShortMethod(cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshort CallStaticShortMethodV(JNIEnv *env, jclass cls, jmethodID method, va_list args);
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jshort
function JNIEnv.CallStaticShortMethodV(cls, method, args)
    return jni.env[0].CallStaticShortMethodV(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticShortMethodV
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jshort
function JNIEnv.CallStaticShortMethodV_safe(cls, method, args)
    local result = JNIEnv.CallStaticShortMethodV(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshort CallStaticShortMethodA(JNIEnv *env, jclass cls, jmethodID method, const jvalue *args);
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jshort
function JNIEnv.CallStaticShortMethodA(cls, method, args)
    return jni.env[0].CallStaticShortMethodA(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticShortMethodA
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jshort
function JNIEnv.CallStaticShortMethodA_safe(cls, method, args)
    local result = JNIEnv.CallStaticShortMethodA(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint CallStaticIntMethod(JNIEnv *env, jclass cls, jmethodID method, ...);
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jint
function JNIEnv.CallStaticIntMethod(cls, method, ...)
    return jni.env[0].CallStaticIntMethod(jni.env, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticIntMethod
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jint
function JNIEnv.CallStaticIntMethod_safe(cls, method, ...)
    local result = JNIEnv.CallStaticIntMethod(cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint CallStaticIntMethodV(JNIEnv *env, jclass cls, jmethodID method, va_list args);
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jint
function JNIEnv.CallStaticIntMethodV(cls, method, args)
    return jni.env[0].CallStaticIntMethodV(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticIntMethodV
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jint
function JNIEnv.CallStaticIntMethodV_safe(cls, method, args)
    local result = JNIEnv.CallStaticIntMethodV(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint CallStaticIntMethodA(JNIEnv *env, jclass cls, jmethodID method, const jvalue *args);
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jint
function JNIEnv.CallStaticIntMethodA(cls, method, args)
    return jni.env[0].CallStaticIntMethodA(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticIntMethodA
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jint
function JNIEnv.CallStaticIntMethodA_safe(cls, method, args)
    local result = JNIEnv.CallStaticIntMethodA(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlong CallStaticLongMethod(JNIEnv *env, jclass cls, jmethodID method, ...);
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jlong
function JNIEnv.CallStaticLongMethod(cls, method, ...)
    return jni.env[0].CallStaticLongMethod(jni.env, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticLongMethod
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jlong
function JNIEnv.CallStaticLongMethod_safe(cls, method, ...)
    local result = JNIEnv.CallStaticLongMethod(cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlong CallStaticLongMethodV(JNIEnv *env, jclass cls, jmethodID method, va_list args);
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jlong
function JNIEnv.CallStaticLongMethodV(cls, method, args)
    return jni.env[0].CallStaticLongMethodV(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticLongMethodV
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jlong
function JNIEnv.CallStaticLongMethodV_safe(cls, method, args)
    local result = JNIEnv.CallStaticLongMethodV(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlong CallStaticLongMethodA(JNIEnv *env, jclass cls, jmethodID method, const jvalue *args);
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jlong
function JNIEnv.CallStaticLongMethodA(cls, method, args)
    return jni.env[0].CallStaticLongMethodA(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticLongMethodA
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jlong
function JNIEnv.CallStaticLongMethodA_safe(cls, method, args)
    local result = JNIEnv.CallStaticLongMethodA(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloat CallStaticFloatMethod(JNIEnv *env, jclass cls, jmethodID method, ...);
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jfloat
function JNIEnv.CallStaticFloatMethod(cls, method, ...)
    return jni.env[0].CallStaticFloatMethod(jni.env, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticFloatMethod
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jfloat
function JNIEnv.CallStaticFloatMethod_safe(cls, method, ...)
    local result = JNIEnv.CallStaticFloatMethod(cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloat CallStaticFloatMethodV(JNIEnv *env, jclass cls, jmethodID method, va_list args);
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jfloat
function JNIEnv.CallStaticFloatMethodV(cls, method, args)
    return jni.env[0].CallStaticFloatMethodV(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticFloatMethodV
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jfloat
function JNIEnv.CallStaticFloatMethodV_safe(cls, method, args)
    local result = JNIEnv.CallStaticFloatMethodV(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloat CallStaticFloatMethodA(JNIEnv *env, jclass cls, jmethodID method, const jvalue *args);
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jfloat
function JNIEnv.CallStaticFloatMethodA(cls, method, args)
    return jni.env[0].CallStaticFloatMethodA(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticFloatMethodA
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jfloat
function JNIEnv.CallStaticFloatMethodA_safe(cls, method, args)
    local result = JNIEnv.CallStaticFloatMethodA(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdouble CallStaticDoubleMethod(JNIEnv *env, jclass cls, jmethodID method, ...);
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jdouble
function JNIEnv.CallStaticDoubleMethod(cls, method, ...)
    return jni.env[0].CallStaticDoubleMethod(jni.env, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticDoubleMethod
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return jdouble
function JNIEnv.CallStaticDoubleMethod_safe(cls, method, ...)
    local result = JNIEnv.CallStaticDoubleMethod(cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdouble CallStaticDoubleMethodV(JNIEnv *env, jclass cls, jmethodID method, va_list args);
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jdouble
function JNIEnv.CallStaticDoubleMethodV(cls, method, args)
    return jni.env[0].CallStaticDoubleMethodV(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticDoubleMethodV
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return jdouble
function JNIEnv.CallStaticDoubleMethodV_safe(cls, method, args)
    local result = JNIEnv.CallStaticDoubleMethodV(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdouble CallStaticDoubleMethodA(JNIEnv *env, jclass cls, jmethodID method, const jvalue *args);
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jdouble
function JNIEnv.CallStaticDoubleMethodA(cls, method, args)
    return jni.env[0].CallStaticDoubleMethodA(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticDoubleMethodA
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return jdouble
function JNIEnv.CallStaticDoubleMethodA_safe(cls, method, args)
    local result = JNIEnv.CallStaticDoubleMethodA(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- void CallStaticVoidMethod(JNIEnv *env, jclass cls, jmethodID method, ...);
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return void
function JNIEnv.CallStaticVoidMethod(cls, method, ...)
    return jni.env[0].CallStaticVoidMethod(jni.env, cls, method, ...)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticVoidMethod
--- @param cls jclass
--- @param method jmethodID
--- @param ... jobject
--- @return void
function JNIEnv.CallStaticVoidMethod_safe(cls, method, ...)
    local result = JNIEnv.CallStaticVoidMethod(cls, method, ...)
    JNIEnv.checkExceptions()
    return result
end
        
--- void CallStaticVoidMethodV(JNIEnv *env, jclass cls, jmethodID method, va_list args);
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return void
function JNIEnv.CallStaticVoidMethodV(cls, method, args)
    return jni.env[0].CallStaticVoidMethodV(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticVoidMethodV
--- @param cls jclass
--- @param method jmethodID
--- @param args va_list
--- @return void
function JNIEnv.CallStaticVoidMethodV_safe(cls, method, args)
    local result = JNIEnv.CallStaticVoidMethodV(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- void CallStaticVoidMethodA(JNIEnv *env, jclass cls, jmethodID method, const jvalue *args);
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return void
function JNIEnv.CallStaticVoidMethodA(cls, method, args)
    return jni.env[0].CallStaticVoidMethodA(jni.env, cls, method, args)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of CallStaticVoidMethodA
--- @param cls jclass
--- @param method jmethodID
--- @param args jvalue
--- @return void
function JNIEnv.CallStaticVoidMethodA_safe(cls, method, args)
    local result = JNIEnv.CallStaticVoidMethodA(cls, method, args)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfieldID GetStaticFieldID(JNIEnv *env, jclass cls, const char *name, const char *sig);
--- @param cls jclass
--- @param name string
--- @param sig string
--- @return jfieldID
function JNIEnv.GetStaticFieldID(cls, name, sig)
    return jni.env[0].GetStaticFieldID(jni.env, cls, name, sig)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStaticFieldID
--- @param cls jclass
--- @param name string
--- @param sig string
--- @return jfieldID
function JNIEnv.GetStaticFieldID_safe(cls, name, sig)
    local result = JNIEnv.GetStaticFieldID(cls, name, sig)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject GetStaticObjectField(JNIEnv *env, jclass cls, jfieldID field);
--- @param cls jclass
--- @param field jfieldID
--- @return jobject
function JNIEnv.GetStaticObjectField(cls, field)
    return jni.env[0].GetStaticObjectField(jni.env, cls, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStaticObjectField
--- @param cls jclass
--- @param field jfieldID
--- @return jobject
function JNIEnv.GetStaticObjectField_safe(cls, field)
    local result = JNIEnv.GetStaticObjectField(cls, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean GetStaticBooleanField(JNIEnv *env, jclass cls, jfieldID field);
--- @param cls jclass
--- @param field jfieldID
--- @return jboolean
function JNIEnv.GetStaticBooleanField(cls, field)
    return jni.env[0].GetStaticBooleanField(jni.env, cls, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStaticBooleanField
--- @param cls jclass
--- @param field jfieldID
--- @return jboolean
function JNIEnv.GetStaticBooleanField_safe(cls, field)
    local result = JNIEnv.GetStaticBooleanField(cls, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyte GetStaticByteField(JNIEnv *env, jclass cls, jfieldID field);
--- @param cls jclass
--- @param field jfieldID
--- @return jbyte
function JNIEnv.GetStaticByteField(cls, field)
    return jni.env[0].GetStaticByteField(jni.env, cls, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStaticByteField
--- @param cls jclass
--- @param field jfieldID
--- @return jbyte
function JNIEnv.GetStaticByteField_safe(cls, field)
    local result = JNIEnv.GetStaticByteField(cls, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jchar GetStaticCharField(JNIEnv *env, jclass cls, jfieldID field);
--- @param cls jclass
--- @param field jfieldID
--- @return jchar
function JNIEnv.GetStaticCharField(cls, field)
    return jni.env[0].GetStaticCharField(jni.env, cls, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStaticCharField
--- @param cls jclass
--- @param field jfieldID
--- @return jchar
function JNIEnv.GetStaticCharField_safe(cls, field)
    local result = JNIEnv.GetStaticCharField(cls, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshort GetStaticShortField(JNIEnv *env, jclass cls, jfieldID field);
--- @param cls jclass
--- @param field jfieldID
--- @return jshort
function JNIEnv.GetStaticShortField(cls, field)
    return jni.env[0].GetStaticShortField(jni.env, cls, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStaticShortField
--- @param cls jclass
--- @param field jfieldID
--- @return jshort
function JNIEnv.GetStaticShortField_safe(cls, field)
    local result = JNIEnv.GetStaticShortField(cls, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint GetStaticIntField(JNIEnv *env, jclass cls, jfieldID field);
--- @param cls jclass
--- @param field jfieldID
--- @return jint
function JNIEnv.GetStaticIntField(cls, field)
    return jni.env[0].GetStaticIntField(jni.env, cls, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStaticIntField
--- @param cls jclass
--- @param field jfieldID
--- @return jint
function JNIEnv.GetStaticIntField_safe(cls, field)
    local result = JNIEnv.GetStaticIntField(cls, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlong GetStaticLongField(JNIEnv *env, jclass cls, jfieldID field);
--- @param cls jclass
--- @param field jfieldID
--- @return jlong
function JNIEnv.GetStaticLongField(cls, field)
    return jni.env[0].GetStaticLongField(jni.env, cls, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStaticLongField
--- @param cls jclass
--- @param field jfieldID
--- @return jlong
function JNIEnv.GetStaticLongField_safe(cls, field)
    local result = JNIEnv.GetStaticLongField(cls, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloat GetStaticFloatField(JNIEnv *env, jclass cls, jfieldID field);
--- @param cls jclass
--- @param field jfieldID
--- @return jfloat
function JNIEnv.GetStaticFloatField(cls, field)
    return jni.env[0].GetStaticFloatField(jni.env, cls, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStaticFloatField
--- @param cls jclass
--- @param field jfieldID
--- @return jfloat
function JNIEnv.GetStaticFloatField_safe(cls, field)
    local result = JNIEnv.GetStaticFloatField(cls, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdouble GetStaticDoubleField(JNIEnv *env, jclass cls, jfieldID field);
--- @param cls jclass
--- @param field jfieldID
--- @return jdouble
function JNIEnv.GetStaticDoubleField(cls, field)
    return jni.env[0].GetStaticDoubleField(jni.env, cls, field)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStaticDoubleField
--- @param cls jclass
--- @param field jfieldID
--- @return jdouble
function JNIEnv.GetStaticDoubleField_safe(cls, field)
    local result = JNIEnv.GetStaticDoubleField(cls, field)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetStaticObjectField(JNIEnv *env, jclass cls, jfieldID field, jobject val);
--- @param cls jclass
--- @param field jfieldID
--- @param val jobject
--- @return void
function JNIEnv.SetStaticObjectField(cls, field, val)
    return jni.env[0].SetStaticObjectField(jni.env, cls, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetStaticObjectField
--- @param cls jclass
--- @param field jfieldID
--- @param val jobject
--- @return void
function JNIEnv.SetStaticObjectField_safe(cls, field, val)
    local result = JNIEnv.SetStaticObjectField(cls, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetStaticBooleanField(JNIEnv *env, jclass cls, jfieldID field, jboolean val);
--- @param cls jclass
--- @param field jfieldID
--- @param val jboolean
--- @return void
function JNIEnv.SetStaticBooleanField(cls, field, val)
    return jni.env[0].SetStaticBooleanField(jni.env, cls, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetStaticBooleanField
--- @param cls jclass
--- @param field jfieldID
--- @param val jboolean
--- @return void
function JNIEnv.SetStaticBooleanField_safe(cls, field, val)
    local result = JNIEnv.SetStaticBooleanField(cls, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetStaticByteField(JNIEnv *env, jclass cls, jfieldID field, jbyte val);
--- @param cls jclass
--- @param field jfieldID
--- @param val jbyte
--- @return void
function JNIEnv.SetStaticByteField(cls, field, val)
    return jni.env[0].SetStaticByteField(jni.env, cls, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetStaticByteField
--- @param cls jclass
--- @param field jfieldID
--- @param val jbyte
--- @return void
function JNIEnv.SetStaticByteField_safe(cls, field, val)
    local result = JNIEnv.SetStaticByteField(cls, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetStaticCharField(JNIEnv *env, jclass cls, jfieldID field, jchar val);
--- @param cls jclass
--- @param field jfieldID
--- @param val jchar
--- @return void
function JNIEnv.SetStaticCharField(cls, field, val)
    return jni.env[0].SetStaticCharField(jni.env, cls, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetStaticCharField
--- @param cls jclass
--- @param field jfieldID
--- @param val jchar
--- @return void
function JNIEnv.SetStaticCharField_safe(cls, field, val)
    local result = JNIEnv.SetStaticCharField(cls, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetStaticShortField(JNIEnv *env, jclass cls, jfieldID field, jshort val);
--- @param cls jclass
--- @param field jfieldID
--- @param val jshort
--- @return void
function JNIEnv.SetStaticShortField(cls, field, val)
    return jni.env[0].SetStaticShortField(jni.env, cls, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetStaticShortField
--- @param cls jclass
--- @param field jfieldID
--- @param val jshort
--- @return void
function JNIEnv.SetStaticShortField_safe(cls, field, val)
    local result = JNIEnv.SetStaticShortField(cls, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetStaticIntField(JNIEnv *env, jclass cls, jfieldID field, jint val);
--- @param cls jclass
--- @param field jfieldID
--- @param val jint
--- @return void
function JNIEnv.SetStaticIntField(cls, field, val)
    return jni.env[0].SetStaticIntField(jni.env, cls, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetStaticIntField
--- @param cls jclass
--- @param field jfieldID
--- @param val jint
--- @return void
function JNIEnv.SetStaticIntField_safe(cls, field, val)
    local result = JNIEnv.SetStaticIntField(cls, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetStaticLongField(JNIEnv *env, jclass cls, jfieldID field, jlong val);
--- @param cls jclass
--- @param field jfieldID
--- @param val jlong
--- @return void
function JNIEnv.SetStaticLongField(cls, field, val)
    return jni.env[0].SetStaticLongField(jni.env, cls, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetStaticLongField
--- @param cls jclass
--- @param field jfieldID
--- @param val jlong
--- @return void
function JNIEnv.SetStaticLongField_safe(cls, field, val)
    local result = JNIEnv.SetStaticLongField(cls, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetStaticFloatField(JNIEnv *env, jclass cls, jfieldID field, jfloat val);
--- @param cls jclass
--- @param field jfieldID
--- @param val jfloat
--- @return void
function JNIEnv.SetStaticFloatField(cls, field, val)
    return jni.env[0].SetStaticFloatField(jni.env, cls, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetStaticFloatField
--- @param cls jclass
--- @param field jfieldID
--- @param val jfloat
--- @return void
function JNIEnv.SetStaticFloatField_safe(cls, field, val)
    local result = JNIEnv.SetStaticFloatField(cls, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetStaticDoubleField(JNIEnv *env, jclass cls, jfieldID field, jdouble val);
--- @param cls jclass
--- @param field jfieldID
--- @param val jdouble
--- @return void
function JNIEnv.SetStaticDoubleField(cls, field, val)
    return jni.env[0].SetStaticDoubleField(jni.env, cls, field, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetStaticDoubleField
--- @param cls jclass
--- @param field jfieldID
--- @param val jdouble
--- @return void
function JNIEnv.SetStaticDoubleField_safe(cls, field, val)
    local result = JNIEnv.SetStaticDoubleField(cls, field, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- jstring NewString(JNIEnv *env, const jchar *unicode, jsize len);
--- @param unicode jchar[]
--- @param len jsize
--- @return jstring
function JNIEnv.NewString(unicode, len)
    return jni.env[0].NewString(jni.env, unicode, len)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewString
--- @param unicode jchar[]
--- @param len jsize
--- @return jstring
function JNIEnv.NewString_safe(unicode, len)
    local result = JNIEnv.NewString(unicode, len)
    JNIEnv.checkExceptions()
    return result
end
        
--- jsize GetStringLength(JNIEnv *env, jstring str);
--- @param str jstring
--- @return jsize
function JNIEnv.GetStringLength(str)
    return jni.env[0].GetStringLength(jni.env, str)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStringLength
--- @param str jstring
--- @return jsize
function JNIEnv.GetStringLength_safe(str)
    local result = JNIEnv.GetStringLength(str)
    JNIEnv.checkExceptions()
    return result
end
        
--- const jchar *GetStringChars(JNIEnv *env, jstring str, jboolean *isCopy);
--- @param str jstring
--- @param isCopy jboolean
--- @return jchar[]
function JNIEnv.GetStringChars(str, isCopy)
    return jni.env[0].GetStringChars(jni.env, str, isCopy)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStringChars
--- @param str jstring
--- @param isCopy jboolean
--- @return jchar[]
function JNIEnv.GetStringChars_safe(str, isCopy)
    local result = JNIEnv.GetStringChars(str, isCopy)
    JNIEnv.checkExceptions()
    return result
end
        
--- void ReleaseStringChars(JNIEnv *env, jstring str, const jchar *chars);
--- @param str jstring
--- @param chars jchar[]
--- @return void
function JNIEnv.ReleaseStringChars(str, chars)
    return jni.env[0].ReleaseStringChars(jni.env, str, chars)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ReleaseStringChars
--- @param str jstring
--- @param chars jchar[]
--- @return void
function JNIEnv.ReleaseStringChars_safe(str, chars)
    local result = JNIEnv.ReleaseStringChars(str, chars)
    JNIEnv.checkExceptions()
    return result
end
        
--- jstring NewStringUTF(JNIEnv *env, const char *utf);
--- @param utf string
--- @return jstring
function JNIEnv.NewStringUTF(utf)
    return jni.env[0].NewStringUTF(jni.env, utf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewStringUTF
--- @param utf string
--- @return jstring
function JNIEnv.NewStringUTF_safe(utf)
    local result = JNIEnv.NewStringUTF(utf)
    JNIEnv.checkExceptions()
    return result
end
        
--- jsize GetStringUTFLength(JNIEnv *env, jstring str);
--- @param str jstring
--- @return jsize
function JNIEnv.GetStringUTFLength(str)
    return jni.env[0].GetStringUTFLength(jni.env, str)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStringUTFLength
--- @param str jstring
--- @return jsize
function JNIEnv.GetStringUTFLength_safe(str)
    local result = JNIEnv.GetStringUTFLength(str)
    JNIEnv.checkExceptions()
    return result
end
        
--- const char *GetStringUTFChars(JNIEnv *env, jstring str, jboolean *isCopy);
--- @param str jstring
--- @param isCopy jboolean
--- @return string
function JNIEnv.GetStringUTFChars(str, isCopy)
    return jni.env[0].GetStringUTFChars(jni.env, str, isCopy)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStringUTFChars
--- @param str jstring
--- @param isCopy jboolean
--- @return string
function JNIEnv.GetStringUTFChars_safe(str, isCopy)
    local result = JNIEnv.GetStringUTFChars(str, isCopy)
    JNIEnv.checkExceptions()
    return result
end
        
--- void ReleaseStringUTFChars(JNIEnv *env, jstring str, const char *utf);
--- @param str jstring
--- @param utf string
--- @return void
function JNIEnv.ReleaseStringUTFChars(str, utf)
    return jni.env[0].ReleaseStringUTFChars(jni.env, str, utf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ReleaseStringUTFChars
--- @param str jstring
--- @param utf string
--- @return void
function JNIEnv.ReleaseStringUTFChars_safe(str, utf)
    local result = JNIEnv.ReleaseStringUTFChars(str, utf)
    JNIEnv.checkExceptions()
    return result
end
        
--- jsize GetArrayLength(JNIEnv *env, jarray array);
--- @param array jarray
--- @return jsize
function JNIEnv.GetArrayLength(array)
    return jni.env[0].GetArrayLength(jni.env, array)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetArrayLength
--- @param array jarray
--- @return jsize
function JNIEnv.GetArrayLength_safe(array)
    local result = JNIEnv.GetArrayLength(array)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobjectArray NewObjectArray(JNIEnv *env, jsize len, jclass cls, jobject init);
--- @param len jsize
--- @param cls jclass
--- @param init jobject
--- @return jobjectArray
function JNIEnv.NewObjectArray(len, cls, init)
    return jni.env[0].NewObjectArray(jni.env, len, cls, init)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewObjectArray
--- @param len jsize
--- @param cls jclass
--- @param init jobject
--- @return jobjectArray
function JNIEnv.NewObjectArray_safe(len, cls, init)
    local result = JNIEnv.NewObjectArray(len, cls, init)
    JNIEnv.checkExceptions()
    return result
end
        
--- jobject GetObjectArrayElement(JNIEnv *env, jobjectArray array, jsize index);
--- @param array jobjectArray
--- @param index jsize
--- @return jobject
function JNIEnv.GetObjectArrayElement(array, index)
    return jni.env[0].GetObjectArrayElement(jni.env, array, index)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetObjectArrayElement
--- @param array jobjectArray
--- @param index jsize
--- @return jobject
function JNIEnv.GetObjectArrayElement_safe(array, index)
    local result = JNIEnv.GetObjectArrayElement(array, index)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetObjectArrayElement(JNIEnv *env, jobjectArray array, jsize index, jobject val);
--- @param array jobjectArray
--- @param index jsize
--- @param val jobject
--- @return void
function JNIEnv.SetObjectArrayElement(array, index, val)
    return jni.env[0].SetObjectArrayElement(jni.env, array, index, val)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetObjectArrayElement
--- @param array jobjectArray
--- @param index jsize
--- @param val jobject
--- @return void
function JNIEnv.SetObjectArrayElement_safe(array, index, val)
    local result = JNIEnv.SetObjectArrayElement(array, index, val)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbooleanArray NewBooleanArray(JNIEnv *env, jsize len);
--- @param len jsize
--- @return jbooleanArray
function JNIEnv.NewBooleanArray(len)
    return jni.env[0].NewBooleanArray(jni.env, len)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewBooleanArray
--- @param len jsize
--- @return jbooleanArray
function JNIEnv.NewBooleanArray_safe(len)
    local result = JNIEnv.NewBooleanArray(len)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyteArray NewByteArray(JNIEnv *env, jsize len);
--- @param len jsize
--- @return jbyteArray
function JNIEnv.NewByteArray(len)
    return jni.env[0].NewByteArray(jni.env, len)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewByteArray
--- @param len jsize
--- @return jbyteArray
function JNIEnv.NewByteArray_safe(len)
    local result = JNIEnv.NewByteArray(len)
    JNIEnv.checkExceptions()
    return result
end
        
--- jcharArray NewCharArray(JNIEnv *env, jsize len);
--- @param len jsize
--- @return jcharArray
function JNIEnv.NewCharArray(len)
    return jni.env[0].NewCharArray(jni.env, len)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewCharArray
--- @param len jsize
--- @return jcharArray
function JNIEnv.NewCharArray_safe(len)
    local result = JNIEnv.NewCharArray(len)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshortArray NewShortArray(JNIEnv *env, jsize len);
--- @param len jsize
--- @return jshortArray
function JNIEnv.NewShortArray(len)
    return jni.env[0].NewShortArray(jni.env, len)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewShortArray
--- @param len jsize
--- @return jshortArray
function JNIEnv.NewShortArray_safe(len)
    local result = JNIEnv.NewShortArray(len)
    JNIEnv.checkExceptions()
    return result
end
        
--- jintArray NewIntArray(JNIEnv *env, jsize len);
--- @param len jsize
--- @return jintArray
function JNIEnv.NewIntArray(len)
    return jni.env[0].NewIntArray(jni.env, len)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewIntArray
--- @param len jsize
--- @return jintArray
function JNIEnv.NewIntArray_safe(len)
    local result = JNIEnv.NewIntArray(len)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlongArray NewLongArray(JNIEnv *env, jsize len);
--- @param len jsize
--- @return jlongArray
function JNIEnv.NewLongArray(len)
    return jni.env[0].NewLongArray(jni.env, len)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewLongArray
--- @param len jsize
--- @return jlongArray
function JNIEnv.NewLongArray_safe(len)
    local result = JNIEnv.NewLongArray(len)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloatArray NewFloatArray(JNIEnv *env, jsize len);
--- @param len jsize
--- @return jfloatArray
function JNIEnv.NewFloatArray(len)
    return jni.env[0].NewFloatArray(jni.env, len)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewFloatArray
--- @param len jsize
--- @return jfloatArray
function JNIEnv.NewFloatArray_safe(len)
    local result = JNIEnv.NewFloatArray(len)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdoubleArray NewDoubleArray(JNIEnv *env, jsize len);
--- @param len jsize
--- @return jdoubleArray
function JNIEnv.NewDoubleArray(len)
    return jni.env[0].NewDoubleArray(jni.env, len)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of NewDoubleArray
--- @param len jsize
--- @return jdoubleArray
function JNIEnv.NewDoubleArray_safe(len)
    local result = JNIEnv.NewDoubleArray(len)
    JNIEnv.checkExceptions()
    return result
end
        
--- jboolean *GetBooleanArrayElements(JNIEnv *env, jbooleanArray array, jboolean *isCopy);
--- @param array jbooleanArray
--- @param isCopy jboolean
--- @return jboolean[]
function JNIEnv.GetBooleanArrayElements(array, isCopy)
    return jni.env[0].GetBooleanArrayElements(jni.env, array, isCopy)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetBooleanArrayElements
--- @param array jbooleanArray
--- @param isCopy jboolean
--- @return jboolean[]
function JNIEnv.GetBooleanArrayElements_safe(array, isCopy)
    local result = JNIEnv.GetBooleanArrayElements(array, isCopy)
    JNIEnv.checkExceptions()
    return result
end
        
--- jbyte *GetByteArrayElements(JNIEnv *env, jbyteArray array, jboolean *isCopy);
--- @param array jbyteArray
--- @param isCopy jboolean
--- @return jbyte[]
function JNIEnv.GetByteArrayElements(array, isCopy)
    return jni.env[0].GetByteArrayElements(jni.env, array, isCopy)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetByteArrayElements
--- @param array jbyteArray
--- @param isCopy jboolean
--- @return jbyte[]
function JNIEnv.GetByteArrayElements_safe(array, isCopy)
    local result = JNIEnv.GetByteArrayElements(array, isCopy)
    JNIEnv.checkExceptions()
    return result
end
        
--- jchar *GetCharArrayElements(JNIEnv *env, jcharArray array, jboolean *isCopy);
--- @param array jcharArray
--- @param isCopy jboolean
--- @return jchar[]
function JNIEnv.GetCharArrayElements(array, isCopy)
    return jni.env[0].GetCharArrayElements(jni.env, array, isCopy)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetCharArrayElements
--- @param array jcharArray
--- @param isCopy jboolean
--- @return jchar[]
function JNIEnv.GetCharArrayElements_safe(array, isCopy)
    local result = JNIEnv.GetCharArrayElements(array, isCopy)
    JNIEnv.checkExceptions()
    return result
end
        
--- jshort *GetShortArrayElements(JNIEnv *env, jshortArray array, jboolean *isCopy);
--- @param array jshortArray
--- @param isCopy jboolean
--- @return jshort[]
function JNIEnv.GetShortArrayElements(array, isCopy)
    return jni.env[0].GetShortArrayElements(jni.env, array, isCopy)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetShortArrayElements
--- @param array jshortArray
--- @param isCopy jboolean
--- @return jshort[]
function JNIEnv.GetShortArrayElements_safe(array, isCopy)
    local result = JNIEnv.GetShortArrayElements(array, isCopy)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint *GetIntArrayElements(JNIEnv *env, jintArray array, jboolean *isCopy);
--- @param array jintArray
--- @param isCopy jboolean
--- @return jint[]
function JNIEnv.GetIntArrayElements(array, isCopy)
    return jni.env[0].GetIntArrayElements(jni.env, array, isCopy)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetIntArrayElements
--- @param array jintArray
--- @param isCopy jboolean
--- @return jint[]
function JNIEnv.GetIntArrayElements_safe(array, isCopy)
    local result = JNIEnv.GetIntArrayElements(array, isCopy)
    JNIEnv.checkExceptions()
    return result
end
        
--- jlong *GetLongArrayElements(JNIEnv *env, jlongArray array, jboolean *isCopy);
--- @param array jlongArray
--- @param isCopy jboolean
--- @return jlong[]
function JNIEnv.GetLongArrayElements(array, isCopy)
    return jni.env[0].GetLongArrayElements(jni.env, array, isCopy)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetLongArrayElements
--- @param array jlongArray
--- @param isCopy jboolean
--- @return jlong[]
function JNIEnv.GetLongArrayElements_safe(array, isCopy)
    local result = JNIEnv.GetLongArrayElements(array, isCopy)
    JNIEnv.checkExceptions()
    return result
end
        
--- jfloat *GetFloatArrayElements(JNIEnv *env, jfloatArray array, jboolean *isCopy);
--- @param array jfloatArray
--- @param isCopy jboolean
--- @return jfloat[]
function JNIEnv.GetFloatArrayElements(array, isCopy)
    return jni.env[0].GetFloatArrayElements(jni.env, array, isCopy)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetFloatArrayElements
--- @param array jfloatArray
--- @param isCopy jboolean
--- @return jfloat[]
function JNIEnv.GetFloatArrayElements_safe(array, isCopy)
    local result = JNIEnv.GetFloatArrayElements(array, isCopy)
    JNIEnv.checkExceptions()
    return result
end
        
--- jdouble *GetDoubleArrayElements(JNIEnv *env, jdoubleArray array, jboolean *isCopy);
--- @param array jdoubleArray
--- @param isCopy jboolean
--- @return jdouble[]
function JNIEnv.GetDoubleArrayElements(array, isCopy)
    return jni.env[0].GetDoubleArrayElements(jni.env, array, isCopy)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetDoubleArrayElements
--- @param array jdoubleArray
--- @param isCopy jboolean
--- @return jdouble[]
function JNIEnv.GetDoubleArrayElements_safe(array, isCopy)
    local result = JNIEnv.GetDoubleArrayElements(array, isCopy)
    JNIEnv.checkExceptions()
    return result
end
        
--- void ReleaseBooleanArrayElements(JNIEnv *env, jbooleanArray array, jboolean *elems, jint mode);
--- @param array jbooleanArray
--- @param elems jboolean[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseBooleanArrayElements(array, elems, mode)
    return jni.env[0].ReleaseBooleanArrayElements(jni.env, array, elems, mode)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ReleaseBooleanArrayElements
--- @param array jbooleanArray
--- @param elems jboolean[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseBooleanArrayElements_safe(array, elems, mode)
    local result = JNIEnv.ReleaseBooleanArrayElements(array, elems, mode)
    JNIEnv.checkExceptions()
    return result
end
        
--- void ReleaseByteArrayElements(JNIEnv *env, jbyteArray array, jbyte *elems, jint mode);
--- @param array jbyteArray
--- @param elems jbyte[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseByteArrayElements(array, elems, mode)
    return jni.env[0].ReleaseByteArrayElements(jni.env, array, elems, mode)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ReleaseByteArrayElements
--- @param array jbyteArray
--- @param elems jbyte[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseByteArrayElements_safe(array, elems, mode)
    local result = JNIEnv.ReleaseByteArrayElements(array, elems, mode)
    JNIEnv.checkExceptions()
    return result
end
        
--- void ReleaseCharArrayElements(JNIEnv *env, jcharArray array, jchar *elems, jint mode);
--- @param array jcharArray
--- @param elems jchar[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseCharArrayElements(array, elems, mode)
    return jni.env[0].ReleaseCharArrayElements(jni.env, array, elems, mode)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ReleaseCharArrayElements
--- @param array jcharArray
--- @param elems jchar[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseCharArrayElements_safe(array, elems, mode)
    local result = JNIEnv.ReleaseCharArrayElements(array, elems, mode)
    JNIEnv.checkExceptions()
    return result
end
        
--- void ReleaseShortArrayElements(JNIEnv *env, jshortArray array, jshort *elems, jint mode);
--- @param array jshortArray
--- @param elems jshort[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseShortArrayElements(array, elems, mode)
    return jni.env[0].ReleaseShortArrayElements(jni.env, array, elems, mode)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ReleaseShortArrayElements
--- @param array jshortArray
--- @param elems jshort[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseShortArrayElements_safe(array, elems, mode)
    local result = JNIEnv.ReleaseShortArrayElements(array, elems, mode)
    JNIEnv.checkExceptions()
    return result
end
        
--- void ReleaseIntArrayElements(JNIEnv *env, jintArray array, jint *elems, jint mode);
--- @param array jintArray
--- @param elems jint[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseIntArrayElements(array, elems, mode)
    return jni.env[0].ReleaseIntArrayElements(jni.env, array, elems, mode)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ReleaseIntArrayElements
--- @param array jintArray
--- @param elems jint[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseIntArrayElements_safe(array, elems, mode)
    local result = JNIEnv.ReleaseIntArrayElements(array, elems, mode)
    JNIEnv.checkExceptions()
    return result
end
        
--- void ReleaseLongArrayElements(JNIEnv *env, jlongArray array, jlong *elems, jint mode);
--- @param array jlongArray
--- @param elems jlong[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseLongArrayElements(array, elems, mode)
    return jni.env[0].ReleaseLongArrayElements(jni.env, array, elems, mode)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ReleaseLongArrayElements
--- @param array jlongArray
--- @param elems jlong[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseLongArrayElements_safe(array, elems, mode)
    local result = JNIEnv.ReleaseLongArrayElements(array, elems, mode)
    JNIEnv.checkExceptions()
    return result
end
        
--- void ReleaseFloatArrayElements(JNIEnv *env, jfloatArray array, jfloat *elems, jint mode);
--- @param array jfloatArray
--- @param elems jfloat[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseFloatArrayElements(array, elems, mode)
    return jni.env[0].ReleaseFloatArrayElements(jni.env, array, elems, mode)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ReleaseFloatArrayElements
--- @param array jfloatArray
--- @param elems jfloat[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseFloatArrayElements_safe(array, elems, mode)
    local result = JNIEnv.ReleaseFloatArrayElements(array, elems, mode)
    JNIEnv.checkExceptions()
    return result
end
        
--- void ReleaseDoubleArrayElements(JNIEnv *env, jdoubleArray array, jdouble *elems, jint mode);
--- @param array jdoubleArray
--- @param elems jdouble[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseDoubleArrayElements(array, elems, mode)
    return jni.env[0].ReleaseDoubleArrayElements(jni.env, array, elems, mode)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ReleaseDoubleArrayElements
--- @param array jdoubleArray
--- @param elems jdouble[]
--- @param mode jint
--- @return void
function JNIEnv.ReleaseDoubleArrayElements_safe(array, elems, mode)
    local result = JNIEnv.ReleaseDoubleArrayElements(array, elems, mode)
    JNIEnv.checkExceptions()
    return result
end
        
--- void GetBooleanArrayRegion(JNIEnv *env, jbooleanArray array, jsize start, jsize len, jboolean *buf);
--- @param array jbooleanArray
--- @param start jsize
--- @param len jsize
--- @param buf jboolean[]
--- @return void
function JNIEnv.GetBooleanArrayRegion(array, start, len, buf)
    return jni.env[0].GetBooleanArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetBooleanArrayRegion
--- @param array jbooleanArray
--- @param start jsize
--- @param len jsize
--- @param buf jboolean[]
--- @return void
function JNIEnv.GetBooleanArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.GetBooleanArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void GetByteArrayRegion(JNIEnv *env, jbyteArray array, jsize start, jsize len, jbyte *buf);
--- @param array jbyteArray
--- @param start jsize
--- @param len jsize
--- @param buf jbyte[]
--- @return void
function JNIEnv.GetByteArrayRegion(array, start, len, buf)
    return jni.env[0].GetByteArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetByteArrayRegion
--- @param array jbyteArray
--- @param start jsize
--- @param len jsize
--- @param buf jbyte[]
--- @return void
function JNIEnv.GetByteArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.GetByteArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void GetCharArrayRegion(JNIEnv *env, jcharArray array, jsize start, jsize len, jchar *buf);
--- @param array jcharArray
--- @param start jsize
--- @param len jsize
--- @param buf jchar[]
--- @return void
function JNIEnv.GetCharArrayRegion(array, start, len, buf)
    return jni.env[0].GetCharArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetCharArrayRegion
--- @param array jcharArray
--- @param start jsize
--- @param len jsize
--- @param buf jchar[]
--- @return void
function JNIEnv.GetCharArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.GetCharArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void GetShortArrayRegion(JNIEnv *env, jshortArray array, jsize start, jsize len, jshort *buf);
--- @param array jshortArray
--- @param start jsize
--- @param len jsize
--- @param buf jshort[]
--- @return void
function JNIEnv.GetShortArrayRegion(array, start, len, buf)
    return jni.env[0].GetShortArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetShortArrayRegion
--- @param array jshortArray
--- @param start jsize
--- @param len jsize
--- @param buf jshort[]
--- @return void
function JNIEnv.GetShortArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.GetShortArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void GetIntArrayRegion(JNIEnv *env, jintArray array, jsize start, jsize len, jint *buf);
--- @param array jintArray
--- @param start jsize
--- @param len jsize
--- @param buf jint[]
--- @return void
function JNIEnv.GetIntArrayRegion(array, start, len, buf)
    return jni.env[0].GetIntArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetIntArrayRegion
--- @param array jintArray
--- @param start jsize
--- @param len jsize
--- @param buf jint[]
--- @return void
function JNIEnv.GetIntArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.GetIntArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void GetLongArrayRegion(JNIEnv *env, jlongArray array, jsize start, jsize len, jlong *buf);
--- @param array jlongArray
--- @param start jsize
--- @param len jsize
--- @param buf jlong[]
--- @return void
function JNIEnv.GetLongArrayRegion(array, start, len, buf)
    return jni.env[0].GetLongArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetLongArrayRegion
--- @param array jlongArray
--- @param start jsize
--- @param len jsize
--- @param buf jlong[]
--- @return void
function JNIEnv.GetLongArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.GetLongArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void GetFloatArrayRegion(JNIEnv *env, jfloatArray array, jsize start, jsize len, jfloat *buf);
--- @param array jfloatArray
--- @param start jsize
--- @param len jsize
--- @param buf jfloat[]
--- @return void
function JNIEnv.GetFloatArrayRegion(array, start, len, buf)
    return jni.env[0].GetFloatArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetFloatArrayRegion
--- @param array jfloatArray
--- @param start jsize
--- @param len jsize
--- @param buf jfloat[]
--- @return void
function JNIEnv.GetFloatArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.GetFloatArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void GetDoubleArrayRegion(JNIEnv *env, jdoubleArray array, jsize start, jsize len, jdouble *buf);
--- @param array jdoubleArray
--- @param start jsize
--- @param len jsize
--- @param buf jdouble[]
--- @return void
function JNIEnv.GetDoubleArrayRegion(array, start, len, buf)
    return jni.env[0].GetDoubleArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetDoubleArrayRegion
--- @param array jdoubleArray
--- @param start jsize
--- @param len jsize
--- @param buf jdouble[]
--- @return void
function JNIEnv.GetDoubleArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.GetDoubleArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetBooleanArrayRegion(JNIEnv *env, jbooleanArray array, jsize start, jsize len, const jboolean *buf);
--- @param array jbooleanArray
--- @param start jsize
--- @param len jsize
--- @param buf jboolean[]
--- @return void
function JNIEnv.SetBooleanArrayRegion(array, start, len, buf)
    return jni.env[0].SetBooleanArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetBooleanArrayRegion
--- @param array jbooleanArray
--- @param start jsize
--- @param len jsize
--- @param buf jboolean[]
--- @return void
function JNIEnv.SetBooleanArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.SetBooleanArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetByteArrayRegion(JNIEnv *env, jbyteArray array, jsize start, jsize len, const jbyte *buf);
--- @param array jbyteArray
--- @param start jsize
--- @param len jsize
--- @param buf jbyte[]
--- @return void
function JNIEnv.SetByteArrayRegion(array, start, len, buf)
    return jni.env[0].SetByteArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetByteArrayRegion
--- @param array jbyteArray
--- @param start jsize
--- @param len jsize
--- @param buf jbyte[]
--- @return void
function JNIEnv.SetByteArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.SetByteArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetCharArrayRegion(JNIEnv *env, jcharArray array, jsize start, jsize len, const jchar *buf);
--- @param array jcharArray
--- @param start jsize
--- @param len jsize
--- @param buf jchar[]
--- @return void
function JNIEnv.SetCharArrayRegion(array, start, len, buf)
    return jni.env[0].SetCharArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetCharArrayRegion
--- @param array jcharArray
--- @param start jsize
--- @param len jsize
--- @param buf jchar[]
--- @return void
function JNIEnv.SetCharArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.SetCharArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetShortArrayRegion(JNIEnv *env, jshortArray array, jsize start, jsize len, const jshort *buf);
--- @param array jshortArray
--- @param start jsize
--- @param len jsize
--- @param buf jshort[]
--- @return void
function JNIEnv.SetShortArrayRegion(array, start, len, buf)
    return jni.env[0].SetShortArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetShortArrayRegion
--- @param array jshortArray
--- @param start jsize
--- @param len jsize
--- @param buf jshort[]
--- @return void
function JNIEnv.SetShortArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.SetShortArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetIntArrayRegion(JNIEnv *env, jintArray array, jsize start, jsize len, const jint *buf);
--- @param array jintArray
--- @param start jsize
--- @param len jsize
--- @param buf jint[]
--- @return void
function JNIEnv.SetIntArrayRegion(array, start, len, buf)
    return jni.env[0].SetIntArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetIntArrayRegion
--- @param array jintArray
--- @param start jsize
--- @param len jsize
--- @param buf jint[]
--- @return void
function JNIEnv.SetIntArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.SetIntArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetLongArrayRegion(JNIEnv *env, jlongArray array, jsize start, jsize len, const jlong *buf);
--- @param array jlongArray
--- @param start jsize
--- @param len jsize
--- @param buf jlong[]
--- @return void
function JNIEnv.SetLongArrayRegion(array, start, len, buf)
    return jni.env[0].SetLongArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetLongArrayRegion
--- @param array jlongArray
--- @param start jsize
--- @param len jsize
--- @param buf jlong[]
--- @return void
function JNIEnv.SetLongArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.SetLongArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetFloatArrayRegion(JNIEnv *env, jfloatArray array, jsize start, jsize len, const jfloat *buf);
--- @param array jfloatArray
--- @param start jsize
--- @param len jsize
--- @param buf jfloat[]
--- @return void
function JNIEnv.SetFloatArrayRegion(array, start, len, buf)
    return jni.env[0].SetFloatArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetFloatArrayRegion
--- @param array jfloatArray
--- @param start jsize
--- @param len jsize
--- @param buf jfloat[]
--- @return void
function JNIEnv.SetFloatArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.SetFloatArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void SetDoubleArrayRegion(JNIEnv *env, jdoubleArray array, jsize start, jsize len, const jdouble *buf);
--- @param array jdoubleArray
--- @param start jsize
--- @param len jsize
--- @param buf jdouble[]
--- @return void
function JNIEnv.SetDoubleArrayRegion(array, start, len, buf)
    return jni.env[0].SetDoubleArrayRegion(jni.env, array, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of SetDoubleArrayRegion
--- @param array jdoubleArray
--- @param start jsize
--- @param len jsize
--- @param buf jdouble[]
--- @return void
function JNIEnv.SetDoubleArrayRegion_safe(array, start, len, buf)
    local result = JNIEnv.SetDoubleArrayRegion(array, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint RegisterNatives(JNIEnv *env, jclass cls, const JNINativeMethod *methods, jint nMethods);
--- @param cls jclass
--- @param methods JNINativeMethod[]
--- @param nMethods jint
--- @return jint
function JNIEnv.RegisterNatives(cls, methods, nMethods)
    return jni.env[0].RegisterNatives(jni.env, cls, methods, nMethods)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of RegisterNatives
--- @param cls jclass
--- @param methods JNINativeMethod[]
--- @param nMethods jint
--- @return jint
function JNIEnv.RegisterNatives_safe(cls, methods, nMethods)
    local result = JNIEnv.RegisterNatives(cls, methods, nMethods)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint UnregisterNatives(JNIEnv *env, jclass cls);
--- @param cls jclass
--- @return jint
function JNIEnv.UnregisterNatives(cls)
    return jni.env[0].UnregisterNatives(jni.env, cls)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of UnregisterNatives
--- @param cls jclass
--- @return jint
function JNIEnv.UnregisterNatives_safe(cls)
    local result = JNIEnv.UnregisterNatives(cls)
    JNIEnv.checkExceptions()
    return result
end
        
--- jint MonitorEnter(JNIEnv *env, jobject obj);
--- @param obj jobject
--- @return jint
function JNIEnv.MonitorEnter(obj)
    return jni.env[0].MonitorEnter(jni.env, obj)
end
    
--- jint MonitorExit(JNIEnv *env, jobject obj);
--- @param obj jobject
--- @return jint
function JNIEnv.MonitorExit(obj)
    return jni.env[0].MonitorExit(jni.env, obj)
end
    
--- jint GetJavaVM(JNIEnv *env, JavaVM **vm);
--- @param vm JavaVM**
--- @return jint
function JNIEnv.GetJavaVM(vm)
    return jni.env[0].GetJavaVM(jni.env, vm)
end
    
--- void GetStringRegion(JNIEnv *env, jstring str, jsize start, jsize len, jchar *buf);
--- @param str jstring
--- @param start jsize
--- @param len jsize
--- @param buf jchar[]
--- @return void
function JNIEnv.GetStringRegion(str, start, len, buf)
    return jni.env[0].GetStringRegion(jni.env, str, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStringRegion
--- @param str jstring
--- @param start jsize
--- @param len jsize
--- @param buf jchar[]
--- @return void
function JNIEnv.GetStringRegion_safe(str, start, len, buf)
    local result = JNIEnv.GetStringRegion(str, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void GetStringUTFRegion(JNIEnv *env, jstring str, jsize start, jsize len, char *buf);
--- @param str jstring
--- @param start jsize
--- @param len jsize
--- @param buf string
--- @return void
function JNIEnv.GetStringUTFRegion(str, start, len, buf)
    return jni.env[0].GetStringUTFRegion(jni.env, str, start, len, buf)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStringUTFRegion
--- @param str jstring
--- @param start jsize
--- @param len jsize
--- @param buf string
--- @return void
function JNIEnv.GetStringUTFRegion_safe(str, start, len, buf)
    local result = JNIEnv.GetStringUTFRegion(str, start, len, buf)
    JNIEnv.checkExceptions()
    return result
end
        
--- void *GetPrimitiveArrayCritical(JNIEnv *env, jarray array, jboolean *isCopy);
--- @param array jarray
--- @param isCopy jboolean
--- @return void*
function JNIEnv.GetPrimitiveArrayCritical(array, isCopy)
    return jni.env[0].GetPrimitiveArrayCritical(jni.env, array, isCopy)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetPrimitiveArrayCritical
--- @param array jarray
--- @param isCopy jboolean
--- @return void*
function JNIEnv.GetPrimitiveArrayCritical_safe(array, isCopy)
    local result = JNIEnv.GetPrimitiveArrayCritical(array, isCopy)
    JNIEnv.checkExceptions()
    return result
end
        
--- void ReleasePrimitiveArrayCritical(JNIEnv *env, jarray array, void *carray, jint mode);
--- @param array jarray
--- @param carray void*
--- @param mode jint
--- @return void
function JNIEnv.ReleasePrimitiveArrayCritical(array, carray, mode)
    return jni.env[0].ReleasePrimitiveArrayCritical(jni.env, array, carray, mode)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ReleasePrimitiveArrayCritical
--- @param array jarray
--- @param carray void*
--- @param mode jint
--- @return void
function JNIEnv.ReleasePrimitiveArrayCritical_safe(array, carray, mode)
    local result = JNIEnv.ReleasePrimitiveArrayCritical(array, carray, mode)
    JNIEnv.checkExceptions()
    return result
end
        
--- const jchar *GetStringCritical(JNIEnv *env, jstring string, jboolean *isCopy);
--- @param string jstring
--- @param isCopy jboolean
--- @return jchar[]
function JNIEnv.GetStringCritical(string, isCopy)
    return jni.env[0].GetStringCritical(jni.env, string, isCopy)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetStringCritical
--- @param string jstring
--- @param isCopy jboolean
--- @return jchar[]
function JNIEnv.GetStringCritical_safe(string, isCopy)
    local result = JNIEnv.GetStringCritical(string, isCopy)
    JNIEnv.checkExceptions()
    return result
end
        
--- void ReleaseStringCritical(JNIEnv *env, jstring string, const jchar *cstring);
--- @param string jstring
--- @param cstring jchar[]
--- @return void
function JNIEnv.ReleaseStringCritical(string, cstring)
    return jni.env[0].ReleaseStringCritical(jni.env, string, cstring)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of ReleaseStringCritical
--- @param string jstring
--- @param cstring jchar[]
--- @return void
function JNIEnv.ReleaseStringCritical_safe(string, cstring)
    local result = JNIEnv.ReleaseStringCritical(string, cstring)
    JNIEnv.checkExceptions()
    return result
end
        
--- jweak NewWeakGlobalRef(JNIEnv *env, jobject obj);
--- @param obj jobject
--- @return jweak
function JNIEnv.NewWeakGlobalRef(obj)
    return jni.env[0].NewWeakGlobalRef(jni.env, obj)
end
    
--- void DeleteWeakGlobalRef(JNIEnv *env, jweak obj);
--- @param obj jweak
--- @return void
function JNIEnv.DeleteWeakGlobalRef(obj)
    return jni.env[0].DeleteWeakGlobalRef(jni.env, obj)
end
    
--- jboolean ExceptionCheck(JNIEnv *env);
--- @return jboolean
function JNIEnv.ExceptionCheck()
    return jni.env[0].ExceptionCheck(jni.env)
end
    
--- jobject NewDirectByteBuffer(JNIEnv *env, void *address, jlong capacity);
--- @param address void*
--- @param capacity jlong
--- @return jobject
function JNIEnv.NewDirectByteBuffer(address, capacity)
    return jni.env[0].NewDirectByteBuffer(jni.env, address, capacity)
end
    
--- void* GetDirectBufferAddress(JNIEnv *env, jobject buf);
--- @param buf jobject
--- @return void
function JNIEnv.GetDirectBufferAddress(buf)
    return jni.env[0].GetDirectBufferAddress(jni.env, buf)
end
    
--- jlong GetDirectBufferCapacity(JNIEnv *env, jobject buf);
--- @param buf jobject
--- @return jlong
function JNIEnv.GetDirectBufferCapacity(buf)
    return jni.env[0].GetDirectBufferCapacity(jni.env, buf)
end
    
--- jobjectRefType GetObjectRefType(JNIEnv *env, jobject obj);
--- @param obj jobject
--- @return jobjectRefType
function JNIEnv.GetObjectRefType(obj)
    return jni.env[0].GetObjectRefType(jni.env, obj)
end
    
--- Exception-safe (doesnt crashes whole program on exception) version of GetObjectRefType
--- @param obj jobject
--- @return jobjectRefType
function JNIEnv.GetObjectRefType_safe(obj)
    local result = JNIEnv.GetObjectRefType(obj)
    JNIEnv.checkExceptions()
    return result
end
        
return JNIEnv