#include "tlsfparse.h"
#include "tlsfspec.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TESTFILE1 "INFO { TITLE: \"AMBA AHB Arbiter\""\
  "DESCRIPTION: \"Component: Decode\""\
  "SEMANTICS: Mealy "\
  "TARGET: Mealy }"\
  "GLOBAL { DEFINITIONS { enum hburst ="\
  "Single: 00 Burst4: 10 Incr: 01; } }"\
  "MAIN { INPUTS { hburst HBURST; }"\
  "OUTPUTS { SINGLE; BURST4; INCR; }"\
  "ASSERT { HBURST == Single -> SINGLE;"\
  "HBURST == Burst4 -> BURST4; HBURST == Incr -> INCR;"\
  "!(SINGLE && (BURST4 || INCR)) && !(BURST4 && INCR); } }"

#define TESTFILE2 ""\
  "INFO { TITLE: \"AMBA AHB Arbiter\" DESCRIPTION: \"Component: Arbiter\" SEMANTICS:"\
  "Mealy TARGET: Mealy } GLOBAL { PARAMETERS { n = 2; } DEFINITIONS {"\
  "// mutual exclusion\n"\
  "mutual(b) = ||[i IN {0, 1 .. (SIZEOF b) - 1}] &&[j IN {0, 1 .. (SIZEOF b) - 1}"\
  "(-) {i}] !(b[i] && b[j]); } } MAIN { INPUTS { HBUSREQ[n]; ALLREADY; } OUTPUTS"\
  " { HGRANT[n]; BUSREQ; DECIDE; } INITIALLY {"\
  "// the component is initially idle\n"\
  "ALLREADY; }"\
  "ASSERT {"\
  "// always exactely one master is granted\n"\
  "mutual(HGRANT)\n"\
  "&& ||[0 <= i < n]\n"\
  "HGRANT[i];"\
  "// if not ready, the grants stay unchanged\n"\
  "&&[0 <= i < n]"\
  "(!ALLREADY -> (X HGRANT[i] <-> HGRANT[i]));"\
  "// every request is eventually granted\n"\
  "&&[0 <= i < n]"\
  "(HBUSREQ[i] -> F (!HBUSREQ[i] || HGRANT[i]));"\
  "// the BUSREQ signal mirrors the HBUSREQ[i]\n"\
  "// signal of the currently granted master i\n"\
  "&&[0 <= i < n]"\
  "(HGRANT[i] -> (BUSREQ <-> HBUSREQ[i]));"\
  "// taking decisions requires to be idle\n"\
  "!ALLREADY -> !DECIDE;"\
  "// granting another master triggers a decision\n"\
  "DECIDE <-> ||[0 <= i < n]"\
  "!(X HGRANT[i] <-> HGRANT[i]);"\
  "// if there is no request, master 0 is granted\n"\
  "(&&[0 <= i < n] !HBUSREQ[i]) && DECIDE"\
  "-> X HGRANT[0];"\
  "}"\
  "ASSUME {"\
  "// the component is not eventually disabled\n"\
  "G F ALLREADY ;"\
  "}"\
  "}"

#define TESTFILE3 ""\
  "INFO {"\
  "TITLE: \"AMBA AHB Arbiter\""\
  "DESCRIPTION: \"Component: Encode\""\
  "SEMANTICS: Mealy "\
  "TARGET: Mealy "\
  "}"\
  "GLOBAL {"\
  "PARAMETERS {"\
  "n = 2;"\
  "}"\
  "DEFINITIONS {"\
  "// mutual exclusion\n"\
  "mutual(b) ="\
  "||[i IN {0, 1 .. (SIZEOF b) - 1}]"\
  "&&[j IN {0, 1 .. (SIZEOF b) - 1} (\\) {i}]"\
  "!(b[i] && b[j]);\n"\
  "// checks whether a bus encodes the numerical\n"\
  "// value v in binary\n"\
  "value(bus,v) = value'(bus,v,0, SIZEOF bus);"\
  "value'(bus,v,i,j) =\n"\
  "j <= 0 : true\n\n"\
  "bit(v,i) == 1 \n"\
  ": value'(bus,v,i+1,j/2)\n"\
  "&& bus[i]\n"\
  "otherwise\n"\
  ":\n"\
  "value'(bus,v,i+1,j/2)\n"\
  "&& !bus[i]\n"\
  ";"\
  "// returns the i-th bit of the numerical\n"\
  "// value v\n"\
  "bit(v,i) ="\
  "i <= 0 : v % 2 "\
  "otherwise : bit(v/2,i-1);"\
  "// discrete logarithm\n"\
  "log2(x) ="\
  "x <= 1 : 1 "\
  "otherwise : 1 + log2(x/2);"\
  "}"\
  "}"\
  "MAIN {"\
  "INPUTS {"\
  "HREADY;"\
  "HGRANT[n];"\
  "}"\
  "OUTPUTS {"\
  "// the output is encoded in binary\n"\
  "HMASTER[log2(n-1)];"\
  "}"\
  "REQUIRE {"\
  "// a every time exactely one grant is high\n"\
  "mutual(HGRANT) && ||[0 <= i < n] HGRANT[i];"\
  "}"\
  "ASSERT {"\
  "// output the binary encoding of i, whenever\n"\
  "// i is granted and HREADY is high\n"\
  "&&[0 <= i < n] (HREADY ->"\
  "(X value(HMASTER,i) <-> HGRANT[i]));"\
  "// when HREADY is low, the value is copied\n"\
  "!HREADY -> &&[0 <= i < log2(n-1)]"\
  "(X HMASTER[i] <-> HMASTER[i]);"\
  "}"\
  "}"

int parse(const char str[]) {
  TLSFSpec spec;
  return parseTLSFString(str, &spec);
}

int main(int argc, char *argv[]) {
  /* to avoid silly warnings about unused parameters */
  (void)argc;
  (void)argv;

  if (atoi(argv[1]) == 1)
    assert(parse(TESTFILE1) == 0);
  if (atoi(argv[1]) == 2)
    assert(parse(TESTFILE2) == 0);
  if (atoi(argv[1]) == 3)
    assert(parse(TESTFILE3) == 0);

  return 0;
}
