#include "monetloader.h"
#include "dobby/include/dobby.h"
#include "utils/logging.h"
#include <unistd.h>
#include <fcntl.h>
#include <android/log.h>
#include <sys/system_properties.h>
#include <jni.h>
#include <utils/armhook.h>
#include <main.h>
#include <sys/stat.h>
#include <fstream>
#include <sstream>
#include <utils/json.hpp>
#include <dlfcn.h>
#include <map>
#include <sys/socket.h>
#include <cstring>
#include <errno.h>
#include <thread>
#include <vector>
#include <signal.h>
#include <sys/epoll.h>
#include <sys/prctl.h>
#include <sys/mman.h>
#include <pthread.h>
#include <sys/resource.h>
#include <dirent.h>
#include <algorithm>
#include <dlfcn.h>
#include <ucontext.h>
#include <unwind.h>
#include <cinttypes>
#include <cxxabi.h>

std::string current_version = "default";
std::string version_str;
int is_patched = 0;


#ifdef __arm__
    void CNetGameHook(int ptr, const char* ipAddr, int serverPort, const char* nickName, const char* serverPass);
    int ReceiveIgnoreRPCHook(int a1);
#elif defined __aarch64__
    void CNetGameHook(long ptr, const char* ipAddr, uint64_t ipSize, uint16_t serverPort, const char* nickName, uint64_t nickNameSize, const char* serverPass, uint64_t serverPassSize);
    long ReceiveIgnoreRPCHook(long a1);
#endif


struct TestServerInfo {
    bool exists;
    std::string ip;
    int port;
    std::string password;
};

TestServerInfo getTestServerInfo() {
    TestServerInfo info{false, "", 0};
    std::string settingsPath = "/storage/emulated/0/Android/data/" + std::string(g_package) + "/files/SAMP/settings.json";
    struct stat buffer;
    if (stat(settingsPath.c_str(), &buffer) != 0) return info;
    std::ifstream file(settingsPath);
    if (!file.is_open()) return info;
    std::stringstream ss;
    ss << file.rdbuf();
    file.close();
    auto j = nlohmann::json::parse(ss.str(), nullptr, false);
    if (j.is_discarded()) {
        LOGI("Error parsing settings.json");
        return info;
    }
    if (j.contains("client") && j["client"].contains("test")) {
        info.exists = true;
        info.ip = j["client"]["test"].value("ip", "");
        info.port = j["client"]["test"].value("port", 0);
        info.password = j["client"]["test"].value("pass", "");
    }
    return info;
} 


#ifdef __arm__
    void (*CNetGame)(int ptr, const char* ipAddr, int serverPort, const char* nickName, const char* serverPass);
    void CNetGameHook(int ptr, const char* ipAddr, int serverPort, const char* nickName, const char* serverPass)
    {
        return CNetGame(ptr, ipAddr, serverPort, nickName, serverPass);
    }

    int (*ReceiveIgnoreRPC)(int a1) = nullptr;
    int ReceiveIgnoreRPCHook(int a1) {
        return ReceiveIgnoreRPC(a1);
    }

    static int* (*VoiceHandler)(int *result) = nullptr;
    static int* VoiceHandlerHook(int *result)
    {
        if (!result)
            return VoiceHandler(result);

        if (result[1] >= 8)
        {
            if ((uint32_t)result[2] == 0xFFFFFFFFu)
            {
                uint8_t* data   = (uint8_t*)result[0];
                memcpy((uint8_t*)result + 8, data, 6);
            }
        }

        return VoiceHandler(result);
    }


#elif defined __aarch64__
    unsigned char sampEncrTable[256] = {
        0x27, 0x69, 0xFD, 0x87, 0x60, 0x7D, 0x83, 0x02, 0xF2, 0x3F, 0x71, 0x99, 0xA3, 0x7C, 0x1B, 0x9D,
        0x76, 0x30, 0x23, 0x25, 0xC5, 0x82, 0x9B, 0xEB, 0x1E, 0xFA, 0x46, 0x4F, 0x98, 0xC9, 0x37, 0x88,
        0x18, 0xA2, 0x68, 0xD6, 0xD7, 0x22, 0xD1, 0x74, 0x7A, 0x79, 0x2E, 0xD2, 0x6D, 0x48, 0x0F, 0xB1,
        0x62, 0x97, 0xBC, 0x8B, 0x59, 0x7F, 0x29, 0xB6, 0xB9, 0x61, 0xBE, 0xC8, 0xC1, 0xC6, 0x40, 0xEF,
        0x11, 0x6A, 0xA5, 0xC7, 0x3A, 0xF4, 0x4C, 0x13, 0x6C, 0x2B, 0x1C, 0x54, 0x56, 0x55, 0x53, 0xA8,
        0xDC, 0x9C, 0x9A, 0x16, 0xDD, 0xB0, 0xF5, 0x2D, 0xFF, 0xDE, 0x8A, 0x90, 0xFC, 0x95, 0xEC, 0x31,
        0x85, 0xC2, 0x01, 0x06, 0xDB, 0x28, 0xD8, 0xEA, 0xA0, 0xDA, 0x10, 0x0E, 0xF0, 0x2A, 0x6B, 0x21,
        0xF1, 0x86, 0xFB, 0x65, 0xE1, 0x6F, 0xF6, 0x26, 0x33, 0x39, 0xAE, 0xBF, 0xD4, 0xE4, 0xE9, 0x44,
        0x75, 0x3D, 0x63, 0xBD, 0xC0, 0x7B, 0x9E, 0xA6, 0x5C, 0x1F, 0xB2, 0xA4, 0xC4, 0x8D, 0xB3, 0xFE,
        0x8F, 0x19, 0x8C, 0x4D, 0x5E, 0x34, 0xCC, 0xF9, 0xB5, 0xF3, 0xF8, 0xA1, 0x50, 0x04, 0x93, 0x73,
        0xE0, 0xBA, 0xCB, 0x45, 0x35, 0x1A, 0x49, 0x47, 0x6E, 0x2F, 0x51, 0x12, 0xE2, 0x4A, 0x72, 0x05,
        0x66, 0x70, 0xB8, 0xCD, 0x00, 0xE5, 0xBB, 0x24, 0x58, 0xEE, 0xB4, 0x80, 0x81, 0x36, 0xA9, 0x67,
        0x5A, 0x4B, 0xE8, 0xCA, 0xCF, 0x9F, 0xE3, 0xAC, 0xAA, 0x14, 0x5B, 0x5F, 0x0A, 0x3B, 0x77, 0x92,
        0x09, 0x15, 0x4E, 0x94, 0xAD, 0x17, 0x64, 0x52, 0xD3, 0x38, 0x43, 0x0D, 0x0C, 0x07, 0x3C, 0x1D,
        0xAF, 0xED, 0xE7, 0x08, 0xB7, 0x03, 0xE6, 0x8E, 0xAB, 0x91, 0x89, 0x3E, 0x2C, 0x96, 0x42, 0xD9,
        0x78, 0xDF, 0xD0, 0x57, 0x5D, 0x84, 0x41, 0x7E, 0xCE, 0xF7, 0x32, 0xC3, 0xD5, 0x20, 0x0B, 0xA7
    };

    struct kyretardizeData {
        uintptr_t target_buffer = 0;
        size_t expected_packet_size = 0;
        int buffer_hits = 0;
        bool buffer_confirmed = false;
    };
    static kyretardizeData kyretardize;
    

    void (*kyretardizeDatagram)(unsigned char *buf, int len, int port, int unk) = nullptr;
    void kyretardizeDatagramHook(unsigned char *buf, int len, int port, int unk) {
        unsigned char* target_addr = nullptr;
        
        kyretardize.expected_packet_size = len + 4;
        if (kyretardize.target_buffer != 0) {
            target_addr = (unsigned char*)(kyretardize.target_buffer);
        } else {
            return kyretardizeDatagram(buf, len, port, unk);
        }

        UnFuck((uintptr_t)target_addr);
        
        unsigned char bChecksum = 0;
        for(int i = 0; i < len; i++) {
            bChecksum ^= buf[i] & 0xAA;
        }
        target_addr[0] = bChecksum;

        for(int i = 0; i < len; i++) {
            unsigned char transformed = sampEncrTable[buf[i]];
            if (unk)
                transformed ^= ((unsigned char*)&port)[0] ^ 0xCC;
            target_addr[i + 1] = transformed;
            unk ^= 1u;
        }

        __builtin___clear_cache((char*)target_addr, (char*)(target_addr + len + 1));
    }

    static std::chrono::steady_clock::time_point last155;

    static int64_t (*MonetLoaderRakPeerRPC)(int64_t a1, uintptr_t a2, int64_t a3, uint32_t a4, uint32_t a5, uint8_t a6, char a7, uint64_t v31, uint64_t mask48, uint64_t mask16, uint64_t zero) = nullptr;
    static int64_t MonetLoaderRakPeerRPCHook(int64_t a1, uintptr_t a2, int64_t a3, uint32_t a4, uint32_t a5, uint8_t a6, char a7, uint64_t v31, uint64_t mask48, uint64_t mask16, uint64_t zero) {
        if(a2 > 255) a2 = *(uint8_t*)a2;
        if(a2 == 155) {
            if(std::chrono::steady_clock::now() - last155 < std::chrono::seconds(3)) return 0;
            last155 = std::chrono::steady_clock::now();
        }
        return MonetLoaderRakPeerRPC(a1, a2, a3, a4, a5, a6, a7, v31, mask48, mask16, zero);
    }


    void (*CNetGame)(long ptr, const char* ipAddr, uint64_t ipSize, uint16_t serverPort, const char* nickName, uint64_t nickNameSize, const char* serverPass, uint64_t serverPassSize);
    void CNetGameHook(long ptr, const char* ipAddr, uint64_t ipSize, uint16_t serverPort, const char* nickName, uint64_t nickNameSize, const char* serverPass, uint64_t serverPassSize)
    {
        DobbyHook((void*)(FindLibrary("libmonetloader.so") + 0x379AD4), (void*)MonetLoaderRakPeerRPCHook, (void**)&MonetLoaderRakPeerRPC);

        void* handle = dlopen("libbass.so", RTLD_NOW | RTLD_NOLOAD);
        if (handle) {
            static bool (*BASS_Free_ptr)() = nullptr;
            BASS_Free_ptr = (bool(*)())dlsym(handle, "BASS_Free");
            if (BASS_Free_ptr) BASS_Free_ptr();
        }

        TestServerInfo info = getTestServerInfo();
        if (info.exists) {
            LOGI("Custom server: %s:%d [%s]", info.ip.c_str(), info.port, info.password.c_str());
            return CNetGame(ptr, info.ip.c_str(), info.ip.size(), info.port, nickName, nickNameSize, info.password.c_str(), info.password.size());
        }        

        return CNetGame(ptr, ipAddr, ipSize, serverPort, nickName, nickNameSize, serverPass, serverPassSize);
    }

    static int64_t (*RakPeerRPC)(int64_t a1, uintptr_t  a2, const unsigned char* a3, int a4, unsigned int a5, unsigned int a6, unsigned int a7, int64_t a8, unsigned char a9, char a10, int a11, int a12, int64_t a13)  = nullptr;
    static int64_t RakPeerRPCHook(int64_t a1, uintptr_t  a2, const unsigned char* a3, int a4, unsigned int a5, unsigned int a6, unsigned int a7, int64_t a8, unsigned char a9, char a10, int a11, int a12, int64_t a13) 
    {    
        return RakPeerRPC(a1, *(uint8_t*)a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13);
    }

    long (*ReceiveIgnoreRPC)(long a1) = nullptr;
    long ReceiveIgnoreRPCHook(long a1) {
        return ReceiveIgnoreRPC(a1);
    }

    static void (*VoiceHandler)(long *param_1) = nullptr;
    static void VoiceHandlerHook(long *param_1)
    {
        if (!param_1) {
            VoiceHandler(param_1);
            return;
        }

        if (*(uint32_t*)((uint8_t*)param_1 + 8) >= 8)
        {
            uint8_t* playerIdField = (uint8_t*)param_1 + 0x0C;

            uint32_t* ip   = (uint32_t*)playerIdField;
            uint16_t* port = (uint16_t*)(playerIdField + 4);

            if (*ip == 0xFFFFFFFF && *port == 0xFFFF)
            {
                uint8_t* data = (uint8_t*)(*(uint64_t*)param_1);
                memcpy(playerIdField, data, 6);
            }
        }

        VoiceHandler(param_1);
    }
#endif



std::string getAppLabel(JNIEnv* env, jobject context) {
    jclass contextClass = env->GetObjectClass(context);
    jmethodID getAppContext = env->GetMethodID(contextClass, "getApplicationContext", "()Landroid/content/Context;");
    jobject appContext = env->CallObjectMethod(context, getAppContext);

    jmethodID getPackageManager = env->GetMethodID(contextClass, "getPackageManager", "()Landroid/content/pm/PackageManager;");
    jobject pm = env->CallObjectMethod(appContext, getPackageManager);

    jmethodID getAppInfo = env->GetMethodID(contextClass, "getApplicationInfo", "()Landroid/content/pm/ApplicationInfo;");
    jobject appInfo = env->CallObjectMethod(appContext, getAppInfo);

    jclass pmClass = env->GetObjectClass(pm);
    jmethodID getLabel = env->GetMethodID(pmClass, "getApplicationLabel", "(Landroid/content/pm/ApplicationInfo;)Ljava/lang/CharSequence;");
    jobject labelCharSeq = env->CallObjectMethod(pm, getLabel, appInfo);

    jclass charSeqClass = env->GetObjectClass(labelCharSeq);
    jmethodID toString = env->GetMethodID(charSeqClass, "toString", "()Ljava/lang/String;");
    jstring labelStr = (jstring) env->CallObjectMethod(labelCharSeq, toString);

    const char* cLabel = env->GetStringUTFChars(labelStr, nullptr);
    std::string result(cLabel);
    env->ReleaseStringUTFChars(labelStr, cLabel);
    return result;
}


static void ensureDirRecursive(const std::string &path) {
	if (path.empty()) return;
	std::string current;
	current.reserve(path.size());
	for (size_t i = 0; i < path.size(); ++i) {
		char ch = path[i];
		current.push_back(ch);
		if (ch == '/' || i == path.size() - 1) {
			if (!current.empty()) {
				if (current.back() == '/') current.pop_back();
				if (!current.empty()) {
					struct stat st {};
					if (stat(current.c_str(), &st) != 0) {
						mkdir(current.c_str(), 0777);
					}
				}
			}
		}
	}
}



static bool createProfile() {
	try {
		nlohmann::json j;
		j["gtasa_name"] = "libGTASA.so";
		j["compat_scripts"] = {"arzmod.lua", "user.lua"};
		j["samp_name"] = "libarzmod.so";
#ifdef __arm__
        j["profile_name"] = std::string("ARZMOD_GAME x32 | Version: ") + version_str;
        j["receiveignorerpc_pattern"] = std::string(GetFunctionPattern((void*)ReceiveIgnoreRPCHook, 64).c_str());
        j["cnetgame_ctor_pattern"] = std::string(GetFunctionPattern((void*)CNetGameHook, 64).c_str());
		j["rakclientinterface_netgame_offset"] = 536;
		j["nveventinsertnewest_offset"] = 2606320;
#elif defined __aarch64__
        j["profile_name"] = std::string("ARZMOD_GAME x64 | Version: ") + version_str;
        j["receiveignorerpc_pattern"] = std::string(GetFunctionPattern((void*)ReceiveIgnoreRPCHook, 64).c_str());
        j["cnetgame_ctor_pattern"] = std::string(GetFunctionPattern((void*)CNetGameHook, 64).c_str());
		j["rakclientinterface_netgame_offset"] = 48;
		j["nveventinsertnewest_offset"] = 3362884;
#endif
		j["use_samp_touch_workaround"] = true;

		std::string baseDir = "/storage/emulated/0/Android/media/" + std::string(g_package) + "/monetloader/compat";
		std::string filePath = baseDir + "/profile.json";
		ensureDirRecursive(baseDir + "/");

		std::ofstream ofs(filePath, std::ios::binary | std::ios::trunc);
		if (!ofs.is_open()) {
			LOGI("createProfile: cannot open %s (errno=%d)", filePath.c_str(), errno);
			return false;
		}
		ofs << j.dump(4);
		ofs.close();
		LOGI("createProfile: written to %s", filePath.c_str());
		return true;
	} catch (...) {
		LOGI("createProfile: exception while generating/writing profile");
		return false;
	}
}


void showToastFromCpp(const char* message) {
    JNIEnv* env = nullptr;
    if (g_jvm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        if (g_jvm->AttachCurrentThread(&env, nullptr) != JNI_OK) return;
    }

    jclass toastCls = env->FindClass("android/widget/Toast");
    if (!toastCls) return;

    jmethodID makeText = env->GetStaticMethodID(
        toastCls, "makeText",
        "(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;");
    if (!makeText) return;

    jstring jmsg = env->NewStringUTF(message ? message : "");
    jobject toastObj = env->CallStaticObjectMethod(toastCls, makeText, g_activity, jmsg, 1);

    if (toastObj) {
        jmethodID show = env->GetMethodID(toastCls, "show", "()V");
        if (show) {
            env->CallVoidMethod(toastObj, show);
        }
        env->DeleteLocalRef(toastObj);
    }

    env->DeleteLocalRef(jmsg);
    env->DeleteLocalRef(toastCls);
}

extern "C" {
    JNIEXPORT void JNICALL
    Java_com_arzmod_radare_InitGamePatch_setVersion(JNIEnv* env, jobject thiz, jstring version) {
        const char* temp = env->GetStringUTFChars(version, nullptr);
        version_str = temp;
        LOGI("[Deprecated] Current version is actual - %s...", version_str.c_str());
        env->ReleaseStringUTFChars(version, temp);
    }

    JNIEXPORT void JNICALL
    Java_com_arzmod_radare_InitGamePatch_versionFix(JNIEnv* env, jobject thiz) {
        if (is_patched == 0) {                
            #ifdef __arm__
                PatternHook(CNetGame_ctorPattern, libHandle, libSize, reinterpret_cast<uintptr_t>(CNetGameHook), reinterpret_cast<uintptr_t*>(&CNetGame), "CNetGameHook");
                PatternHook(ReceiveIgnoreRPCPattern, libHandle, libSize, reinterpret_cast<uintptr_t>(ReceiveIgnoreRPCHook), reinterpret_cast<uintptr_t*>(&ReceiveIgnoreRPC), "ReceiveIgnoreRPCHook");
                PatternHook(VoiceHandlerPattern, libHandle, libSize, reinterpret_cast<uintptr_t>(VoiceHandlerHook), reinterpret_cast<uintptr_t*>(&VoiceHandler), "VoiceHandlerHook");
            #elif defined __aarch64__
                PatternHook(CNetGame_ctorPattern, libHandle, libSize, reinterpret_cast<uintptr_t>(CNetGameHook), reinterpret_cast<uintptr_t*>(&CNetGame), "CNetGameHook");
                PatternHook(ReceiveIgnoreRPCPattern, raknetHandle, raknetSize, reinterpret_cast<uintptr_t>(ReceiveIgnoreRPCHook), reinterpret_cast<uintptr_t*>(&ReceiveIgnoreRPC), "ReceiveIgnoreRPCHook"); 
                PatternHook(RakPeerRPCPattern, raknetHandle, raknetSize, reinterpret_cast<uintptr_t>(RakPeerRPCHook), reinterpret_cast<uintptr_t*>(&RakPeerRPC), "RakPeerRPCHook");
                PatternHook(VoiceHandlerPattern, libHandle, libSize, reinterpret_cast<uintptr_t>(VoiceHandlerHook), reinterpret_cast<uintptr_t*>(&VoiceHandler), "VoiceHandlerHook");
                showToastFromCpp("x64 by t.me/cleoarizona <3");
            #endif
            createProfile();
            LOGI("Version fix applied");
        } else {
            LOGI("Version fix already applied");
        }
    }

    
    #ifdef __aarch64__
        ssize_t (*orig_sendto)(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen) = nullptr;
        ssize_t sendto_hook(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen) {
            if (!kyretardize.buffer_confirmed && kyretardize.expected_packet_size > 0 && len == kyretardize.expected_packet_size) {
                if ((uintptr_t)buf == kyretardize.target_buffer) {
                    kyretardize.buffer_hits++;
      
                    if (kyretardize.buffer_hits >= 10) {
                        kyretardize.buffer_confirmed = true;
                    }
                    return orig_sendto(sockfd, buf, len - 3, flags, dest_addr, addrlen);

                } else {
                    kyretardize.target_buffer = (uintptr_t)buf;
                    kyretardize.buffer_hits = 1;
                    kyretardize.expected_packet_size = 0;
                }
            }

            if (kyretardize.buffer_confirmed && (uintptr_t)buf == kyretardize.target_buffer) return orig_sendto(sockfd, buf, len - 3, flags, dest_addr, addrlen);
            return orig_sendto(sockfd, buf, len, flags, dest_addr, addrlen);
        }
    
        JNIEXPORT void JNICALL
        Java_com_arzmod_radare_InitGamePatch_installPacketsFix(JNIEnv* env, jobject thiz) {
            PatternHook(CNetGame_ctorPattern, libHandle, libSize, reinterpret_cast<uintptr_t>(CNetGameHook), reinterpret_cast<uintptr_t*>(&CNetGame), "CNetGameHook");
            int result = PatternHook(kyretardizeDatagramPattern, raknetHandle, raknetSize, reinterpret_cast<uintptr_t>(kyretardizeDatagramHook), reinterpret_cast<uintptr_t*>(&kyretardizeDatagram), "kyretardizeDatagramHook"); 
            if(!result) {
                pid_t pid = getpid();
                kill(pid, SIGKILL);
            }
            DobbyHook((void*)sendto, (void*)sendto_hook, (void**)&orig_sendto);
        }
    #endif
}

#if defined __aarch64__
static inline const char* sig_name(int sig) {
    switch (sig) {
        case SIGSEGV: return "Segmentation fault";
        case SIGABRT: return "Abort";
        case SIGFPE:  return "Floating point exception";
        case SIGILL:  return "Illegal instruction";
        case SIGBUS:  return "Bus error";
        case SIGTRAP: return "Trace/breakpoint trap";
        default:      return "Signal";
    }
}

static inline const char* segv_code_desc(int code) {
    switch (code) {
        case SEGV_MAPERR: return "Address not mapped to object";
        case SEGV_ACCERR: return "Invalid permissions for mapped object";
        default: return "Unknown SEGV code";
    }
}

static void describe_addr(uintptr_t addr, char* out, size_t out_sz) {
    Dl_info info{};
    if (dladdr(reinterpret_cast<void*>(addr), &info) && info.dli_fname && info.dli_fbase) {
        uintptr_t base = reinterpret_cast<uintptr_t>(info.dli_fbase);
        uintptr_t off_in_lib = addr - base;
        const char* libname = strrchr(info.dli_fname, '/');
        libname = libname ? libname + 1 : info.dli_fname;

        const char* sname = info.dli_sname;
        char demangled[256]{};
        if (sname) {
            int status = 0;
            size_t len = 0;
            char* res = abi::__cxa_demangle(sname, nullptr, &len, &status);
            if (status == 0 && res) {
                strncpy(demangled, res, sizeof(demangled) - 1);
                demangled[sizeof(demangled) - 1] = '\0';
            }
            if (res) free(res);
        }

        uintptr_t sym_addr = reinterpret_cast<uintptr_t>(info.dli_saddr);
        uintptr_t sym_off_in_lib = (sym_addr && base) ? (sym_addr - base) : 0;
        uintptr_t disp = (sym_addr) ? (addr - sym_addr) : 0;

        if (sname) {
            snprintf(out, out_sz,
                "[%016" PRIxPTR "]%s::[0x%016" PRIxPTR "]%s+%lu (%lX)",
                base,
                libname,
                sym_off_in_lib,
                demangled[0] ? demangled : sname,
                (unsigned long)disp,
                (unsigned long)disp);
        } else {
            snprintf(out, out_sz,
                "[%016" PRIxPTR "]%s::[0x%016" PRIxPTR "]",
                base,
                libname,
                off_in_lib);
        }
    } else {
        snprintf(out, out_sz, "[0x%016" PRIxPTR "]", addr);
    }
}

static void log_backtrace(uintptr_t start_pc, uintptr_t start_lr) {
    LOGI(" ================= BACKTRACE =================");
    char buf_pc[512]{}; describe_addr(start_pc, buf_pc, sizeof(buf_pc));
    char buf_lr[512]{}; describe_addr(start_lr, buf_lr, sizeof(buf_lr));
    LOGI(" %016" PRIxPTR " -> %s", start_pc, buf_pc);
    if (start_lr) LOGI(" %016" PRIxPTR " -> %s", start_lr, buf_lr);

    struct State { int idx; } state{0};
    auto cb = [](_Unwind_Context* ctx, void* arg) {
        State* s = reinterpret_cast<State*>(arg);
        uintptr_t ip = _Unwind_GetIP(ctx);
        if (ip == 0) return _URC_END_OF_STACK;
        if (s->idx < 32) {
            char d[512]{};
            describe_addr(ip, d, sizeof(d));
            LOGI(" %016" PRIxPTR " -> %s", ip, d);
        }
        s->idx++;
        return _URC_NO_REASON;
    };
    _Unwind_Backtrace(cb, &state);
}

static inline unsigned char to_printable(unsigned char c) { return (c >= 32 && c <= 126) ? c : '.'; }

static void dump_stack(uintptr_t sp) {
    LOGI(" =================== STACK ===================");
    const size_t row = 32;
    for (int i = 0; i < 16; ++i) {
        uintptr_t addr = sp + i * row;
        unsigned char buf[row]{};
        bool ok = true;
        for (size_t j = 0; j < row; ++j) {
            volatile unsigned char* p = reinterpret_cast<volatile unsigned char*>(addr + j);
            unsigned char v = 0;
            if ((addr + j) < 0x1000) { ok = false; break; }
            v = *p;
            buf[j] = v;
        }
        if (!ok) break;
        char hex[3*row+1]{}; char asc[row+1]{};
        for (size_t j = 0; j < row; ++j) {
            snprintf(hex + j*3, 4, "%02X ", buf[j]);
            asc[j] = to_printable(buf[j]);
        }
        asc[row-1] = to_printable(buf[row-1]); asc[row] = '\0';
        LOGI(" %4lX: 0x%016" PRIxPTR " %s| %.*s", (unsigned long)(i*row), addr, hex, (int)row, asc);
    }
}

static void log_calltrace(uintptr_t pc) {
    LOGI(" Calltrace:");
    Dl_info info{};
    if (dladdr(reinterpret_cast<void*>(pc), &info) && info.dli_fname && info.dli_fbase) {
        uintptr_t base = reinterpret_cast<uintptr_t>(info.dli_fbase);
        uintptr_t off = pc - base;
        const char* libname = strrchr(info.dli_fname, '/');
        libname = libname ? libname + 1 : info.dli_fname;
        LOGI(" 0x%016" PRIxPTR " -> [%016" PRIxPTR "]%s::[0x%016" PRIxPTR "] <- UNHANDLED EXCEPTION HERE!", pc, base, libname, off);
    } else {
        LOGI(" 0x%016" PRIxPTR, pc);
    }
}

static void signal_handler(int sig, siginfo_t* siginfo, void* uctx) {

    ucontext_t* uc = reinterpret_cast<ucontext_t*>(uctx);
    uintptr_t regs[33]{};
    for (int i = 0; i < 31; ++i) regs[i] = uc->uc_mcontext.regs[i];
    uintptr_t sp = uc->uc_mcontext.sp;
    uintptr_t pc = uc->uc_mcontext.pc;
    uintptr_t lr = uc->uc_mcontext.regs[30];

    Dl_info dlinfo{}; dladdr(reinterpret_cast<void*>(pc), &dlinfo);
    const char* libname = dlinfo.dli_fname ? (strrchr(dlinfo.dli_fname, '/') ? strrchr(dlinfo.dli_fname, '/')+1 : dlinfo.dli_fname) : "<unknown>";
    uintptr_t base = reinterpret_cast<uintptr_t>(dlinfo.dli_fbase);
    uintptr_t off = base ? (pc - base) : 0;
    
    LOGI(" %s: Unhandled issue in library %s+0x%" PRIxPTR, sig_name(sig), libname, off);
    LOGI("");
    LOGI(" =================== CRASH ===================");
    if (sig == SIGSEGV) {
        const char* code = siginfo ? segv_code_desc(siginfo->si_code) : "";
        LOGI(" %s: %s (errno = %d)", sig_name(sig), code, errno);
        LOGI(" Exception address: %" PRIuPTR, siginfo ? (uintptr_t)siginfo->si_addr : 0);
    } else {
        LOGI(" %s (errno = %d)", sig_name(sig), errno);
    }
    LOGI(" Version: %s | Custom crashlog because arizona fuck game with monetloader", version_str.c_str());
    LOGI("");

    LOGI(" ==================== CPU ====================");
    LOGI(" Registers:");
    LOGI("  x0: %016" PRIxPTR " |  x1: %016" PRIxPTR, regs[0], regs[1]);
    LOGI("  x2: %016" PRIxPTR " |  x3: %016" PRIxPTR, regs[2], regs[3]);
    LOGI("  x4: %016" PRIxPTR " |  x5: %016" PRIxPTR, regs[4], regs[5]);
    LOGI("  x6: %016" PRIxPTR " |  x7: %016" PRIxPTR, regs[6], regs[7]);
    LOGI("  x8: %016" PRIxPTR " |  x9: %016" PRIxPTR, regs[8], regs[9]);
    LOGI(" x10: %016" PRIxPTR " | x11: %016" PRIxPTR, regs[10], regs[11]);
    LOGI(" x12: %016" PRIxPTR " | x13: %016" PRIxPTR, regs[12], regs[13]);
    LOGI(" x14: %016" PRIxPTR " | x15: %016" PRIxPTR, regs[14], regs[15]);
    LOGI(" x16: %016" PRIxPTR " | x17: %016" PRIxPTR, regs[16], regs[17]);
    LOGI(" x18: %016" PRIxPTR " | x19: %016" PRIxPTR, regs[18], regs[19]);
    LOGI(" x20: %016" PRIxPTR " | x21: %016" PRIxPTR, regs[20], regs[21]);
    LOGI(" x22: %016" PRIxPTR " | x23: %016" PRIxPTR, regs[22], regs[23]);
    LOGI(" x24: %016" PRIxPTR " | x25: %016" PRIxPTR, regs[24], regs[25]);
    LOGI(" x26: %016" PRIxPTR " | x27: %016" PRIxPTR, regs[26], regs[27]);
    LOGI(" x28: %016" PRIxPTR " | x29: %016" PRIxPTR, regs[28], regs[29]);
    LOGI(" x30: %016" PRIxPTR " |  sp: %016" PRIxPTR, regs[30], sp);

    log_calltrace(pc);
    log_backtrace(pc, lr);
    dump_stack(sp);

    struct sigaction sa{}; sa.sa_handler = SIG_DFL; sigemptyset(&sa.sa_mask);
    sigaction(sig, &sa, nullptr);
    raise(sig);
}



static void register_signal_handlers() {
    struct sigaction sa{}; memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = signal_handler; sa.sa_flags = SA_SIGINFO | SA_RESTART;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGTERM, &sa, nullptr);
    sigaction(SIGINT,  &sa, nullptr);
    sigaction(SIGABRT, &sa, nullptr);
    sigaction(SIGSEGV, &sa, nullptr);
    sigaction(SIGFPE,  &sa, nullptr);
    sigaction(SIGILL,  &sa, nullptr);
    sigaction(SIGBUS,  &sa, nullptr);
    sigaction(SIGTRAP, &sa, nullptr);
}

int64_t (*MonetLoaderHookerOg)(uintptr_t a1, uintptr_t a2, uintptr_t a3) = nullptr;
int64_t MonetLoaderHookerHk(uintptr_t a1, uintptr_t a2, uintptr_t a3) 
{
    if(FindLibrary("libGTASA.so") + 0x335045 == a1)
    {
        void* func_addr = FindPattern(MultiTouchProccessPattern, FindLibrary("libSCAnd.so"), GetLibrarySize("libSCAnd.so"));
        if(func_addr)
        {
            *(uint64_t*)(FindLibrary("libmonetloader.so") + 0x7FCD48) = (uintptr_t)func_addr;
            *(uint8_t*)(FindLibrary("libmonetloader.so") + 0x7FCD30) = 1;
            a1 = FindLibrary("libGTASA.so") + 0x335044;
        }
        else a1 = FindLibrary("libGTASA.so") + 2606320;
    }
    return MonetLoaderHookerOg(a1, a2, a3);
}


extern "C" void* android_dlopen_ext(const char* filename, int flags, const void* extinfo, void* caller_addr);


static void* (*orig_android_dlopen_ext)(const char* filename, int flags, const void* extinfo, void* caller_addr) = nullptr;
static void* android_dlopen_ext_hook(const char* filename, int flags, const void* extinfo, void* caller_addr) {
    void* result = orig_android_dlopen_ext(filename, flags, extinfo, caller_addr);
    if (filename && strstr(filename, "libmonetloader.so")) {
        DobbyHook((void*)(FindLibrary("libmonetloader.so") + 0x35C778), (void*)MonetLoaderHookerHk, (void**)&MonetLoaderHookerOg);
    }
    return result;
}

#endif


__attribute__((constructor))
void init_monetloader() {
    LOGI("░█████╗░██████╗░███████╗███╗░░░███╗░█████╗░██████╗░");
    LOGI("██╔══██╗██╔══██╗╚════██║████╗░████║██╔══██╗██╔══██╗");
    LOGI("███████║██████╔╝░░███╔═╝██╔████╔██║██║░░██║██║░░██║");
    LOGI("██╔══██║██╔══██╗██╔══╝░░██║╚██╔╝██║██║░░██║██║░░██║");
    LOGI("██║░░██║██║░░██║███████╗██║░╚═╝░██║╚█████╔╝██████╔╝");
    LOGI("╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝░╚════╝░╚═════╝░ by dmk ♡");
    #ifdef __arm__
        LOGI("MonetLoaderPatch module inited | x32 | Build time: %s", __DATE__ " " __TIME__);
    #elif defined __aarch64__
        LOGI("MonetLoaderPatch module inited | x64 | Build time: %s", __DATE__ " " __TIME__);
        register_signal_handlers();
        DobbyHook((void*)android_dlopen_ext, (void*)android_dlopen_ext_hook, (void**)&orig_android_dlopen_ext);
    #else
        #error "Unsupported architecture"
    #endif 
} 

