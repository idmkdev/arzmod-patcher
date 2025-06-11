#pragma once

#include <cstdint>

extern char libName[256];
extern uintptr_t libHandle;

extern char raknetName[256];
extern uintptr_t raknetHandle;

#define HOOK_LIBRARY "libsamp.so"
#define HOOK_RAKNET "libraknet.so"
