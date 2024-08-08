#ifndef TLSFSPEC_H
#define TLSFSPEC_H

#include "exptree.h"

typedef enum SemType {
  /* actual types */
  ST_MEALY = 512,
  ST_MOORE = 1024,
  /* flags */
  ST_STRICT = 1,
  ST_FINITE = 2,
} SemType;

typedef struct TLSFSpec {
  char *title;
  char *descr;
  SemType semnt;
  SemType targt;
  char **tags;
  struct ExpTree *initially;
  struct ExpTree *preset;
  struct ExpTree *require;
  struct ExpTree *assrt;
  struct ExpTree *assume;
  struct ExpTree *guarantee;
} TLSFSpec;

#endif
