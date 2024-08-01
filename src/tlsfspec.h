#ifndef TLSFSPEC_H
#define TLSFSPEC_H

#include "exptree.h"

typedef struct TLSFSpec {
  struct ExpTree *initially;
  struct ExpTree *preset;
  struct ExpTree *require;
  struct ExpTree *assrt;
  struct ExpTree *assume;
  struct ExpTree *guarantee;
} TLSFSpec;

#endif
