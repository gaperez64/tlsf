#ifndef TLSFPARSE_H
#define TLSFPARSE_H

#include "tlsfspec.h"

int parseTLSFString(const char *, TLSFSpec *);
void resetTLSFSpec(TLSFSpec *);
void setTLSFInputString(const char *);
void endTLSFScan(void);

#endif
