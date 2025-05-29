#pragma once

#include <jni.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>

signed int (*InstallVersionString)(int param_1,int param_2,int param_3,int param_4) = nullptr;
signed int InstallVersionStringHook(int param_1,int param_2,int param_3,int param_4);