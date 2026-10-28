/* mini SDK (see ../../README.md): message sending. Always cast to the method's prototype. */
#ifndef PNS_OBJC_MESSAGE_H
#define PNS_OBJC_MESSAGE_H

#include <objc/runtime.h>

void objc_msgSend(void);
#if defined(__x86_64__) || defined(_M_X64)
void objc_msgSend_stret(void);              /* structures returned in memory (not on arm64) */
#endif

#endif
