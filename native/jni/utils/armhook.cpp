#include <iostream>
#include <jni.h>
#include <android/log.h>
#include <dlfcn.h>
#include <cstring>
#include <sys/mman.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h> 
#include <sys/mman.h>
#include <cstdarg>
#include <exception>
#include "logging.h"
#include "armhook.h"

#define HOOK_PROC "\x01\xB4\x01\xB4\x01\x48\x01\x90\x01\xBD\x00\xBF\x00\x00\x00\x00"

uintptr_t mmap_start 	= 0;
uintptr_t mmap_end		= 0;
uintptr_t memlib_start	= 0;
uintptr_t memlib_end	= 0;



void UnFuck(uintptr_t ptr)
{
    #ifdef __aarch64__
        size_t pageSize = sysconf(_SC_PAGESIZE);
        mprotect((void*)(ptr & ~(pageSize - 1)), pageSize, PROT_READ | PROT_WRITE | PROT_EXEC);
    #elif __arm__
        size_t pageSize = sysconf(_SC_PAGESIZE);
        mprotect((void*)(ptr & ~(pageSize - 1)), pageSize, PROT_READ | PROT_WRITE | PROT_EXEC);
    #else
        #error "Unsupported architecture"
    #endif
}
void NOP(uintptr_t addr, unsigned int count)
{
    UnFuck(addr);

    for(uintptr_t ptr = addr; ptr != (addr+(count*2)); ptr += 2)
    {
        *(char*)ptr = 0x00;
        *(char*)(ptr+1) = 0x46;
    }

    #ifdef __aarch64__
        __builtin___clear_cache((char*)addr, (char*)(addr + count*2));
    #elif __arm__
        cacheflush(addr, (uintptr_t)(addr + count*2), 0);
    #else
        #error "Unsupported architecture"
    #endif
}

void WriteMemory(uintptr_t dest, uintptr_t src, size_t size)
{
    UnFuck(dest);
    memcpy((void*)dest, (void*)src, size);
    #ifdef __aarch64__
        __builtin___clear_cache((char*)dest, (char*)(dest + size));
        __builtin___clear_cache((char*)src, (char*)(src + size));
    #elif __arm__
        cacheflush(dest, dest + size, 0);
        cacheflush(src, src + size, 0);
    #else
        #error "Unsupported architecture"
    #endif
}

void ReadMemory(uintptr_t dest, uintptr_t src, size_t size)
{
    UnFuck(dest);
    UnFuck(src);
    memcpy((void*)dest, (void*)src, size);
    #ifdef __aarch64__
        __builtin___clear_cache((char*)dest, (char*)(dest + size));
        __builtin___clear_cache((char*)src, (char*)(src + size));
    #elif __arm__
        cacheflush(dest, dest + size, 0);
        cacheflush(src, src + size, 0);
    #else
        #error "Unsupported architecture"
    #endif
}

void InitHookStuff(const char* lib_name)
{
    uintptr_t libHandle = FindLibrary(lib_name);
    if(libHandle == 0)
	{
		LOGE("ERROR: %s address not found!", lib_name);
		return;
	}
    size_t size = GetLibrarySize(lib_name);
    if (size == 0) {
        LOGE("Library size is zero");
        return;
    }
	memlib_start = libHandle;
	memlib_end = memlib_start + size;

	mmap_start = (uintptr_t)mmap(0, PAGE_SIZE, PROT_WRITE | PROT_READ | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	mprotect((void*)(mmap_start & 0xFFFFF000), PAGE_SIZE, PROT_READ | PROT_EXEC | PROT_WRITE);
	mmap_end = (mmap_start + PAGE_SIZE);
}

void JMPCode(uintptr_t func, uintptr_t addr)
{
    uint32_t code = (((addr - func - 4) >> 12) & 0x7FF) | 0xF000 | ((((addr - func - 4) >> 1) & 0x7FF) | 0xB800) << 16;
    WriteMemory(func, (uintptr_t)&code, 4);
}

void WriteHookProc(uintptr_t addr, uintptr_t func)
{
    char code[16];
    memcpy(code, HOOK_PROC, 16);
    *(uint32_t*)&code[12] = (func | 1);
    WriteMemory(addr, (uintptr_t)code, 16);
}

void SetUpHook(uintptr_t addr, uintptr_t func, uintptr_t *orig)
{
    if(memlib_end < (memlib_start + 0x10) || mmap_end < (mmap_start + 0x20))
    {
        LOGE("space limit reached");
        std::terminate();
    }

    ReadMemory(mmap_start, addr, 4);
    WriteHookProc(mmap_start+4, addr+4);
    *orig = mmap_start+1;
    mmap_start += 32;

    JMPCode(addr, memlib_start);
    WriteHookProc(memlib_start, func);
    memlib_start += 16;
}

void InstallMethodHook(uintptr_t addr, uintptr_t func)
{
    UnFuck(addr);
    *(uintptr_t*)addr = func;
}
