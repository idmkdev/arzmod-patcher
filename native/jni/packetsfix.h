#pragma once

#include <jni.h>
#include <android/log.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>
#include <stdio.h>

extern unsigned char sampEncrTable[256];
extern unsigned char encrBuffer[4092];

void kyretardizeDatagram(unsigned char *buf, int len, int port, int unk);
signed int SocketLayer__SendTo_Hook(int socket, int sockfd, int buffer, int length, int ip_addr, unsigned int port); 