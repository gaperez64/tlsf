#include "tlsfspec.h"
#include <stddef.h>
#include <string.h>

BusEnum *findEnum(char *name, BusEnum *benum, size_t nbenum) {
  for (size_t i = 0; i < nbenum; i++)
    if (strcmp(name, benum[i].name) == 0)
      return benum + i;
  return NULL;
}
