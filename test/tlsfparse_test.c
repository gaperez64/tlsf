#include "tlsfparse.h"
#include "tlsfspec.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
  /* to avoid silly warnings about unused parameters */
  (void)argc;
  (void)argv;

  const char str[] = 
  "INFO { TITLE: \"AMBA AHB Arbiter\" DESCRIPTION: \"Component: Decode\""
  "SEMANTICS: Mealy TARGET: Mealy } GLOBAL { DEFINITIONS { enum hburst ="
  "Single: 00 Burst4: 10 Incr: 01 } } MAIN { INPUTS { hburst HBURST; }"
  "OUTPUTS { SINGLE; BURST4; INCR; } ASSERT { HBURST == Single -> SINGLE;"
  "HBURST == Burst4 -> BURST4; HBURST == Incr -> INCR; !(SINGLE &&"
  "(BURST4 || INCR)) && !(BURST4 && INCR); } }";
  TLSFSpec spec;
  int res = parseTLSFString(str, &list);
  assert(res == 0);

  return 0;
}
