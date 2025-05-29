#include <jni.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <utils/logging.h>
#include <utils/addresses.h>
#include <utils/armhook.h>
#include "main.h"
#include <string>

struct VersionStringData {
    char* saved_string = nullptr;
    char* saved_dest = nullptr;
    char* saved_version = nullptr;
    char* saved_commit = nullptr;
    bool is_patched = false;

    ~VersionStringData() {
        if(saved_string) free(saved_string);
        if(saved_version) free(saved_version);
        if(saved_commit) free(saved_commit);
    }
};

static VersionStringData version_data;

signed int (*InstallVersionString)(char* dest,int unk_1,int verlen,char* version, char* commit,int modifylen) = nullptr;
signed int InstallVersionStringHook(char* dest,int unk_1,int verlen,char* version, char* commit,int modifylen)
{
    version_data.saved_dest = dest;
    version_data.saved_version = version;
    version_data.saved_commit = commit;
    
    if(version_data.saved_string) {
        std::string str(version_data.saved_string);
        if(str.find("{version}") != std::string::npos) {
            str.replace(str.find("{version}"), 9, version);
        }
        if(str.find("{commit}") != std::string::npos) {
            str.replace(str.find("{commit}"), 8, commit);
        }
        strcpy(dest, str.c_str());
    } else {
        *dest = '\0';
    }
    // InstallVersionString(dest, unk_1, verlen, version, commit, modifylen);
    return 1;
}

extern "C" {
    JNIEXPORT void JNICALL
    Java_com_arzmod_radare_InitGamePatch_setVersionString(JNIEnv* env, jobject thiz, jstring string) {
        if(version_data.saved_string) {
            free(version_data.saved_string);
            version_data.saved_string = nullptr;
        }
        
        const char* str = env->GetStringUTFChars(string, nullptr);
        if(str) {
            version_data.saved_string = strdup(str);
            env->ReleaseStringUTFChars(string, str);
            
            if(version_data.saved_dest) {
                std::string mod_str(version_data.saved_string);
                if(mod_str.find("{version}") != std::string::npos) {
                    mod_str.replace(mod_str.find("{version}"), 9, version_data.saved_version);
                }
                if(mod_str.find("{commit}") != std::string::npos) {
                    mod_str.replace(mod_str.find("{commit}"), 8, version_data.saved_commit);
                }
                strcpy(version_data.saved_dest, mod_str.c_str());
                return;
            }
        }

        if(!version_data.is_patched)
        {
            int result = PatternHook("\x81\xB0\xD0\xB5\x02\xAF\x83\xB0\x08\x4C\x0A\x46\x07\xF1\x08\x01\xBB\x60\x7C\x44\x02\x91\x00\x91\x00\x21\x23\x46\xF0\xF2\xA6\xEA", libHandle, GetLibrarySize(libName), reinterpret_cast<uintptr_t>(InstallVersionStringHook), reinterpret_cast<uintptr_t*>(&InstallVersionString));
            if(result) {
                LOGI("Hooks installed successfully (InstallVersionStringHook), address: %x", result);
                version_data.is_patched = true;
            } else {
                LOGE("Can't find offset from pattern (InstallVersionStringHook)");
                version_data.is_patched = true;
            }
        }
    }
}


__attribute__((constructor))
void init_gamefixes() {
    LOGI("GameFixes module inited | Build time: %s", __DATE__ " " __TIME__);
} 