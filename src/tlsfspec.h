#ifndef TLSFSPEC_H
#define TLSFSPEC_H

#include "exptree.h"
#include <stddef.h>

typedef enum SemType {
  /* actual types */
  ST_MEALY = 512,
  ST_MOORE = 1024,
  /* flags */
  ST_STRICT = 1,
  ST_FINITE = 2,
} SemType;

typedef struct EnumVal {
  size_t nopts;
  char *id;
  char **opts;
} EnumVal;

typedef struct BusEnum {
  char *name;
  size_t nvals;
  EnumVal *vals;
} BusEnum;

typedef struct TLSFSpec {
  char *title;
  char *descr;
  SemType semnt;
  SemType targt;
  size_t ntags;
  char **tags;
  size_t nbenums;
  BusEnum *benums;
  struct ExpTree *initially;
  struct ExpTree *preset;
  struct ExpTree *require;
  struct ExpTree *assrt;
  struct ExpTree *assume;
  struct ExpTree *guarantee;
} TLSFSpec;

#endif
