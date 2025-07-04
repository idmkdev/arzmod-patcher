#include "utils/logging.h"
#include "utils/addresses.h"
#include "utils/armhook.h"
#include "main.h"
#include <unistd.h>
#include <fcntl.h>
#include <string>
#include <jni.h>

char libName[256] = {0};
uintptr_t libHandle = 0;

char raknetName[256] = {0};
uintptr_t raknetHandle = 0;

#define HOOK_LIBRARY "libsamp.so"
#define HOOK_RAKNET "libraknet.so"

__attribute__((constructor))
void init() {
    #ifdef __arm__
        libHandle = FindLibrary(HOOK_LIBRARY);
        if(libHandle == 0)
        {
            char prefix[256] = {0};
            strncpy(prefix, HOOK_LIBRARY, sizeof(prefix) - 1);
            char* dot = strrchr(prefix, '.');
            if(dot) *dot = '\0';
            LOGI("Not found %s, trying to find by prefix %s", HOOK_LIBRARY, prefix);
            LibraryInfo libInfo = FindLibraryByPrefix(prefix);
            if(libInfo.address == 0 || libInfo.name[0] == '\0')
            {
                Log("Not found %s or any library starting with %s", HOOK_LIBRARY, prefix);
                pid_t pid = getpid();
                kill(pid, SIGKILL);
            }
            LOGI("Found library by prefix at address: %x with name: %s", libInfo.address, libInfo.name);
            libHandle = libInfo.address;
            strncpy(libName, libInfo.name, sizeof(libName) - 1);
            InitHookStuff(libName);
        }
        else
        {
            strncpy(libName, HOOK_LIBRARY, sizeof(libName) - 1);
            InitHookStuff(libName);
        }

        LOGI("ARZMOD Native Init (samp_base: %x) | x%i | Build time: %s", libHandle, sizeof(void*) * 8, __DATE__ " " __TIME__);
    #elif defined __aarch64__
        strncpy(libName, HOOK_LIBRARY, sizeof(libName) - 1);
        strncpy(raknetName, HOOK_RAKNET, sizeof(raknetName) - 1);
        libHandle = FindLibrary(HOOK_LIBRARY);
        raknetHandle = FindLibrary(HOOK_RAKNET);
        LOGI("ARZMOD Native Init (samp_base: %lx | raknet_base: %lx) | x%lu | Build time: %s", libHandle, raknetHandle, sizeof(void*) * 8, __DATE__ " " __TIME__);
    #else
        #error This lib is supposed to work on ARM only!
    #endif
}


