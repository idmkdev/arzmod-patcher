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
#include "addresses.h"
#include "logging.h"

std::string GetFunctionPattern(void* func_addr, size_t size) {
    if (!func_addr || size == 0) {
        return "";
    }
    
    unsigned char* bytes = (unsigned char*)func_addr;
    std::string pattern;
    pattern.reserve(size * 2);
    
    for(size_t i = 0; i < size; i++) {
        char hex[3];
        snprintf(hex, sizeof(hex), "%02X", bytes[i]);
        pattern += hex;
    }
    
    return pattern;
}

uintptr_t FindLibrary(const char* library)
{
    char filename[0xFF] = {0},
    buffer[2048] = {0};
    FILE *fp = 0;
    uintptr_t address = 0;

    sprintf( filename, "/proc/%d/maps", getpid() );

    fp = fopen( filename, "rt" );
    if(fp == 0)
    {
        LOGE("ERROR: can't open file %s", filename);
        goto done;
    }

    while(fgets(buffer, sizeof(buffer), fp))
    {
        if( strstr( buffer, library ) )
        {
            address = (uintptr_t)strtoul( buffer, 0, 16 );
            break;
        }
    }

    done:

    if(fp)
      fclose(fp);

    return address;
}

size_t GetLibrarySize(const char* lib_name) {
    char filename[0xFF] = {0};
    char buffer[2048] = {0};
    FILE *fp = nullptr;
    size_t lib_size = 0;
    
    #if defined(__aarch64__)
        uintptr_t min_addr = 0xFFFFFFFFFFFFFFFF;
    #else
        uintptr_t min_addr = 0xFFFFFFFF;
    #endif
    uintptr_t max_addr = 0;

    sprintf(filename, "/proc/%d/maps", getpid());
    
    fp = fopen(filename, "rt");
    if (fp == nullptr) {
        LOGE("ERROR: can't open file %s", filename);
        return 0;
    }

    while (fgets(buffer, sizeof(buffer), fp)) {
        if (strstr(buffer, lib_name)) {
            uintptr_t start_addr, end_addr;
            #if defined(__aarch64__)
                if (sscanf(buffer, "%lx-%lx", &start_addr, &end_addr) == 2) {
            #else
                if (sscanf(buffer, "%x-%x", (unsigned int*)&start_addr, (unsigned int*)&end_addr) == 2) {
            #endif
                if (start_addr < min_addr) min_addr = start_addr;
                if (end_addr > max_addr) max_addr = end_addr;
            } else {
                LOGE("Failed to parse addresses from: %s", buffer);
            }
        }
    }

    fclose(fp);

    #if defined(__aarch64__)
        if (min_addr != 0xFFFFFFFFFFFFFFFF && max_addr != 0) {
    #else
        if (min_addr != 0xFFFFFFFF && max_addr != 0) {
    #endif
        lib_size = max_addr - min_addr;
    } else {
        LOGE("ERROR: library size not found for %s", lib_name);
    }

    return lib_size;
}

LibraryInfo FindLibraryByPrefix(const char* library_prefix)
{
    LibraryInfo result;
    result.address = 0;
    memset(result.name, 0, sizeof(result.name));
    
    char filename[0xFF] = {0};
    char buffer[2048] = {0};
    FILE *fp = 0;
    size_t prefix_len = strlen(library_prefix);

    sprintf(filename, "/proc/%d/maps", getpid());

    fp = fopen(filename, "rt");
    if(fp == 0)
    {
        LOGE("ERROR: can't open file %s", filename);
        goto done;
    }

    while(fgets(buffer, sizeof(buffer), fp))
    {
        char* lib_name = strrchr(buffer, '/');
        if(lib_name)
        {
            lib_name++;
            if(strncmp(lib_name, library_prefix, prefix_len) == 0)
            {
                result.address = (uintptr_t)strtoul(buffer, 0, 16);
                
                char* end = lib_name;
                while (*end && *end >= 32 && *end != ' ') {
                    end++;
                }
                
                if (end > lib_name) {
                    size_t name_len = end - lib_name;
                    strncpy(result.name, lib_name, name_len);
                    result.name[name_len] = '\0';
                } else {
                    LOGE("Invalid library name");
                }
                break;
            }
        }
    }

    done:
    if(fp)
        fclose(fp);

    return result;
}


