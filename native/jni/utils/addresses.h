#pragma once

#include <cstdint>
#include <string>

struct LibraryInfo {
    uintptr_t address;
    char name[256];
};

template <size_t N>
void* FindPattern(const char(&pattern)[N], uintptr_t start, size_t length) {
    const char* memory = static_cast<const char*>((void*)start);  
    size_t pattern_len = N - 1; 

    for (size_t i = 0; i <= length - pattern_len; i++) {
        bool found = true;
        for (size_t j = 0; j < pattern_len; j++) {
            if (pattern[j] != memory[i + j]) {
                found = false;
                break;
            }
        }
        if (found) {
            return const_cast<void*>(reinterpret_cast<const void*>(memory + i));
        }
    }

    return nullptr; 
}

size_t GetLibrarySize(const char* lib_name);
uintptr_t FindLibrary(const char* library);
LibraryInfo FindLibraryByPrefix(const char* library_prefix);

std::string GetFunctionPattern(void* func_addr, size_t size);