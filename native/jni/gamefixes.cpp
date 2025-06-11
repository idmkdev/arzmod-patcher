#include <jni.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <utils/logging.h>
#include <utils/addresses.h>
#include <utils/armhook.h>
#include "main.h"
#include <string>
#include "offsets.h"

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

struct ChatRendererData {
    bool is_patched = false;
    bool is_set = false;
    float pos_x = 0.0f;
    float pos_y = 0.0f;
};

static VersionStringData version_data;
static ChatRendererData chat_data;

void (*InstallVersionString)(int param_1,int param_2,int param_3) = nullptr;
void InstallVersionStringHook(int param_1,int param_2,int param_3)
{
    version_data.saved_dest = (char*)(param_1 + 0x53);
    InstallVersionString(param_1, param_2, param_3);
    
    char version[32] = {0};
    char commit[32] = {0};
    
    sscanf(version_data.saved_dest, "Ver: %[^,], Native: %[^-]", version, commit);
    
    if (version_data.saved_version) free(version_data.saved_version);
    version_data.saved_version = strdup(version);
    
    if (version_data.saved_commit) free(version_data.saved_commit);
    version_data.saved_commit = strdup(commit);

    if(version_data.saved_string) {
        std::string str(version_data.saved_string);
        if(str.find("{version}") != std::string::npos) {
            str.replace(str.find("{version}"), 9, version_data.saved_version);
        }
        if(str.find("{commit}") != std::string::npos) {
            str.replace(str.find("{commit}"), 8, version_data.saved_commit);
        }
        strcpy(version_data.saved_dest, str.c_str());
    } else {
        *version_data.saved_dest = '\0';
    }
}

void (*ChatRenderer)(int param_1, int param_2) = nullptr;
void ChatRendererHook(int param_1, int param_2)
{    
    if (chat_data.is_set) {
        *(float*)(param_1 + 12) = chat_data.pos_x;
        *(float*)(param_1 + 16) = chat_data.pos_y;
        
        *(float*)(param_1 + 44) = chat_data.pos_x;
        *(float*)(param_1 + 48) = chat_data.pos_y;
    }
    
    return ChatRenderer(param_1, param_2);
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
                if(version_data.saved_version && mod_str.find("{version}") != std::string::npos) {
                    mod_str.replace(mod_str.find("{version}"), 9, version_data.saved_version);
                }
                if(version_data.saved_commit && mod_str.find("{commit}") != std::string::npos) {
                    mod_str.replace(mod_str.find("{commit}"), 8, version_data.saved_commit);
                }
                strcpy(version_data.saved_dest, mod_str.c_str());
                return;
            }
        }

        if(!version_data.is_patched)
        {
            int result = PatternHook(INSTALL_VERSION_STRING_PATTERN, libHandle, GetLibrarySize(libName), reinterpret_cast<uintptr_t>(InstallVersionStringHook), reinterpret_cast<uintptr_t*>(&InstallVersionString), "InstallVersionStringHook");
            if(result) {
                version_data.is_patched = true;
            } else {
                version_data.is_patched = true;
            }
        }
    }

    JNIEXPORT void JNICALL
    Java_com_arzmod_radare_InitGamePatch_setChatPosition(JNIEnv* env, jobject thiz, jfloat pos_x, jfloat pos_y) {
        chat_data.pos_x = pos_x;
        chat_data.pos_y = pos_y;
        chat_data.is_set = true;

        if(!chat_data.is_patched) {
            int result = PatternHook(CHAT_RENDER_PATTERN, libHandle, GetLibrarySize(libName), reinterpret_cast<uintptr_t>(ChatRendererHook), reinterpret_cast<uintptr_t*>(&ChatRenderer), "ChatRendererHook");
            if(result) {
                chat_data.is_patched = true;
            } else {
                chat_data.is_patched = true;
            }
        }
    }
}


__attribute__((constructor))
void init_gamefixes() {
    #ifdef __arm__
        LOGI("GameFixes module inited | x32 | Build time: %s", __DATE__ " " __TIME__);
    #elif defined __aarch64__
        LOGI("GameFixes module inited | x64 | Build time: %s", __DATE__ " " __TIME__);
    #else
        #error "Unsupported architecture"
    #endif
} 