#pragma once

#include "utils/addresses.h"
#include "dobby/include/dobby.h"
size_t GetLibrarySize(const char* lib_name);
uintptr_t FindLibrary(const char* library);
void UnFuck(uintptr_t ptr);
void NOP(uintptr_t addr, unsigned int count);
void WriteMemory(uintptr_t dest, uintptr_t src, size_t size);
void ReadMemory(uintptr_t dest, uintptr_t src, size_t size);

void SetUpHook(uintptr_t addr, uintptr_t func, uintptr_t *orig);
void InstallMethodHook(uintptr_t addr, uintptr_t func);
void CodeInject(uintptr_t addr, uintptr_t func, int rgstr);
void InitHookStuff(const char* lib_name);

#ifdef __arm__
    #define bit 32
#elif defined __aarch64__
    #define bit 64
#else
    #error "Unsupported architecture"
#endif

template <size_t N>
int PatternHook(const char(&pattern)[N], uintptr_t start, size_t length, uintptr_t func, uintptr_t *orig, const char* tag = nullptr, bool isDobbyUsed = false)
{
    void* func_addr = FindPattern(pattern, start, length);
    if(func_addr) {
        if(isDobbyUsed) {
            DobbyHook(reinterpret_cast<void*>(func_addr), reinterpret_cast<void*>(func), reinterpret_cast<void**>(orig));
        } else {
            SetUpHook(reinterpret_cast<uintptr_t>(func_addr), func, orig);
        }
        if(tag) {
            #ifdef __arm__
                LOGI("[%d] Hooks installed successfully (%s), address: %x (static %x)", bit, tag, (uintptr_t)func_addr, (uintptr_t)func_addr - (uintptr_t)start);
            #elif defined __aarch64__
                LOGI("[%d] Hooks installed successfully (%s), address: %lx (static %lx)", bit, tag, (uintptr_t)func_addr, (uintptr_t)func_addr - (uintptr_t)start);
            #endif
        }
        return (uintptr_t)func_addr;
    }
    else {
        if(tag) {
            LOGE("[%d] Can't find offset from pattern %s (%s)", bit, pattern, tag);
        }
        return 0;
    }
    return (uintptr_t)func_addr;
}