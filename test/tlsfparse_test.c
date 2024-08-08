#include "tlsfparse.h"
#include "tlsfspec.h"
#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TESTFILE1                                                              \
  "INFO { TITLE: \"AMBA AHB Arbiter\""                                         \
  "DESCRIPTION: \"Component: Decode\""                                         \
  "SEMANTICS: Mealy "                                                          \
  "TARGET: Mealy }"                                                            \
  "GLOBAL { DEFINITIONS { enum hburst ="                                       \
  "Single: 00 Burst4: 10 Incr: 01; } }"                                        \
  "MAIN { INPUTS { hburst HBURST; }"                                           \
  "OUTPUTS { SINGLE; BURST4; INCR; }"                                          \
  "ASSERT { HBURST == Single -> SINGLE;"                                       \
  "HBURST == Burst4 -> BURST4; HBURST == Incr -> INCR;"                        \
  "!(SINGLE && (BURST4 || INCR)) && !(BURST4 && INCR); } }"

#define TESTFILE2                                                              \
  ""                                                                           \
  "INFO { TITLE: \"AMBA AHB Arbiter\" DESCRIPTION: \"Component: Arbiter\" "    \
  "SEMANTICS:"                                                                 \
  "Mealy TARGET: Mealy } GLOBAL { PARAMETERS { n = 2; } DEFINITIONS {"         \
  "// mutual exclusion\n"                                                      \
  "mutual(b) = ||[i IN {0, 1 .. (SIZEOF b) - 1}] &&[j IN {0, 1 .. (SIZEOF b) " \
  "- 1}"                                                                       \
  "(-) {i}] !(b[i] && b[j]); } } MAIN { INPUTS { HBUSREQ[n]; ALLREADY; } "     \
  "OUTPUTS"                                                                    \
  " { HGRANT[n]; BUSREQ; DECIDE; } INITIALLY {"                                \
  "// the component is initially idle\n"                                       \
  "ALLREADY; }"                                                                \
  "ASSERT {"                                                                   \
  "// always exactely one master is granted\n"                                 \
  "mutual(HGRANT)\n"                                                           \
  "&& ||[0 <= i < n]\n"                                                        \
  "HGRANT[i];"                                                                 \
  "// if not ready, the grants stay unchanged\n"                               \
  "&&[0 <= i < n]"                                                             \
  "(!ALLREADY -> (X HGRANT[i] <-> HGRANT[i]));"                                \
  "// every request is eventually granted\n"                                   \
  "&&[0 <= i < n]"                                                             \
  "(HBUSREQ[i] -> F (!HBUSREQ[i] || HGRANT[i]));"                              \
  "// the BUSREQ signal mirrors the HBUSREQ[i]\n"                              \
  "// signal of the currently granted master i\n"                              \
  "&&[0 <= i < n]"                                                             \
  "(HGRANT[i] -> (BUSREQ <-> HBUSREQ[i]));"                                    \
  "// taking decisions requires to be idle\n"                                  \
  "!ALLREADY -> !DECIDE;"                                                      \
  "// granting another master triggers a decision\n"                           \
  "DECIDE <-> ||[0 <= i < n]"                                                  \
  "!(X HGRANT[i] <-> HGRANT[i]);"                                              \
  "// if there is no request, master 0 is granted\n"                           \
  "(&&[0 <= i < n] !HBUSREQ[i]) && DECIDE"                                     \
  "-> X HGRANT[0];"                                                            \
  "}"                                                                          \
  "ASSUME {"                                                                   \
  "// the component is not eventually disabled\n"                              \
  "G F ALLREADY ;"                                                             \
  "}"                                                                          \
  "}"

#define TESTFILE3                                                              \
  ""                                                                           \
  "INFO {"                                                                     \
  "TITLE: \"AMBA AHB Arbiter\""                                                \
  "DESCRIPTION: \"Component: Encode\""                                         \
  "SEMANTICS: Mealy "                                                          \
  "TARGET: Mealy "                                                             \
  "}"                                                                          \
  "GLOBAL {"                                                                   \
  "PARAMETERS {"                                                               \
  "n = 2;"                                                                     \
  "}"                                                                          \
  "DEFINITIONS {"                                                              \
  "// mutual exclusion\n"                                                      \
  "mutual(b) ="                                                                \
  "||[i IN {0, 1 .. (SIZEOF b) - 1}]"                                          \
  "&&[j IN {0, 1 .. (SIZEOF b) - 1} (\\) {i}]"                                 \
  "!(b[i] && b[j]);\n"                                                         \
  "// checks whether a bus encodes the numerical\n"                            \
  "// value v in binary\n"                                                     \
  "value(bus,v) = value'(bus,v,0, SIZEOF bus);"                                \
  "value'(bus,v,i,j) =\n"                                                      \
  "j <= 0 : true\n\n"                                                          \
  "bit(v,i) == 1 \n"                                                           \
  ": value'(bus,v,i+1,j/2)\n"                                                  \
  "&& bus[i]\n"                                                                \
  "otherwise\n"                                                                \
  ":\n"                                                                        \
  "value'(bus,v,i+1,j/2)\n"                                                    \
  "&& !bus[i]\n"                                                               \
  ";"                                                                          \
  "// returns the i-th bit of the numerical\n"                                 \
  "// value v\n"                                                               \
  "bit(v,i) ="                                                                 \
  "i <= 0 : v % 2 "                                                            \
  "otherwise : bit(v/2,i-1);"                                                  \
  "// discrete logarithm\n"                                                    \
  "log2(x) ="                                                                  \
  "x <= 1 : 1 "                                                                \
  "otherwise : 1 + log2(x/2);"                                                 \
  "}"                                                                          \
  "}"                                                                          \
  "MAIN {"                                                                     \
  "INPUTS {"                                                                   \
  "HREADY;"                                                                    \
  "HGRANT[n];"                                                                 \
  "}"                                                                          \
  "OUTPUTS {"                                                                  \
  "// the output is encoded in binary\n"                                       \
  "HMASTER[log2(n-1)];"                                                        \
  "}"                                                                          \
  "REQUIRE {"                                                                  \
  "// a every time exactely one grant is high\n"                               \
  "mutual(HGRANT) && ||[0 <= i < n] HGRANT[i];"                                \
  "}"                                                                          \
  "ASSERT {"                                                                   \
  "// output the binary encoding of i, whenever\n"                             \
  "// i is granted and HREADY is high\n"                                       \
  "&&[0 <= i < n] (HREADY ->"                                                  \
  "(X value(HMASTER,i) <-> HGRANT[i]));"                                       \
  "// when HREADY is low, the value is copied\n"                               \
  "!HREADY -> &&[0 <= i < log2(n-1)]"                                          \
  "(X HMASTER[i] <-> HMASTER[i]);"                                             \
  "}"                                                                          \
  "}"

#define TESTFILE4                                                              \
  ""                                                                           \
  "INFO {"                                                                     \
  "TITLE: \"AMBA AHB Arbiter\""                                                \
  "DESCRIPTION: \"Component: Shift\""                                          \
  "SEMANTICS: Mealy "                                                          \
  "TARGET: Mealy "                                                             \
  "}"                                                                          \
  "MAIN {"                                                                     \
  "INPUTS { HREADY; LOCKED; }"                                                 \
  "OUTPUTS { HMASTLOCK; }"                                                     \
  "ASSERT {"                                                                   \
  "// if HREADY is high, the component copies LOCKED to HMASTLOCK, shifted "   \
  "by one time step\n"                                                         \
  "HREADY -> (X HMASTLOCK <-> LOCKED);"                                        \
  "// if HREADY is low, the old value of HMASTLOCK is copied\n"                \
  "!HREADY -> (X HMASTLOCK <-> HMASTLOCK);"                                    \
  "}"                                                                          \
  "}"

#define TESTFILE5                                                              \
  ""                                                                           \
  "INFO {"                                                                     \
  "TITLE: \"AMBA AHB Arbiter\""                                                \
  "DESCRIPTION: \"Component: TSingle\""                                        \
  "SEMANTICS: Mealy "                                                          \
  "TARGET: Mealy "                                                             \
  "}"                                                                          \
  "MAIN {"                                                                     \
  "INPUTS { SINGLE; HREADY; LOCKED; DECIDE; }"                                 \
  "OUTPUTS { READY3; }"                                                        \
  "INITIALLY {"                                                                \
  "// initially no decision is taken\n"                                        \
  "!DECIDE;"                                                                   \
  "}"                                                                          \
  "PRESET {"                                                                   \
  "// at startup, the component is ready\n"                                    \
  "READY3;"                                                                    \
  "}"                                                                          \
  "REQUIRE {"                                                                  \
  "// decisions are only taken if the component is ready\n"                    \
  "!READY3 -> X !DECIDE;"                                                      \
  "}"                                                                          \
  "ASSERT {"                                                                   \
  "// for each single, locked transmission, the bus is locked for one time "   \
  "step\n"                                                                     \
  "DECIDE ->"                                                                  \
  "X[2] (((SINGLE && LOCKED) -> (!READY3 U (HREADY && !READY3 && X READY3))) " \
  "&&"                                                                         \
  "(!(SINGLE && LOCKED) -> READY3));"                                          \
  "// the component stays ready as long as there is no decision\n"             \
  "READY3 && X !DECIDE -> X READY3;"                                           \
  "// if there is a decision the component blocks the bus for at least two "   \
  "time steps\n"                                                               \
  "READY3 && X DECIDE -> G[1:2] ! READY3;"                                     \
  "}"                                                                          \
  "ASSUME {"                                                                   \
  "// a slave cannot block the bus\n"                                          \
  "G F HREADY;"                                                                \
  "}"                                                                          \
  "}"

#define TESTFILE6                                                              \
  ""                                                                           \
  "INFO {"                                                                     \
  "TITLE: \"AMBA AHB Arbiter\""                                                \
  "DESCRIPTION: \"Component: TIncr\""                                          \
  "SEMANTICS: Moore ,Strict "                                                  \
  "TARGET: Moore "                                                             \
  "} "                                                                         \
  "MAIN { "                                                                    \
  "INPUTS { INCR; HREADY; LOCKED; DECIDE; BUSREQ; } "                          \
  "OUTPUTS { READY1; } "                                                       \
  "INITIALLY { !DECIDE; } "                                                    \
  "PRESET { READY1; } "                                                        \
  "REQUIRE { "                                                                 \
  "// decisions are only taken if the component is ready\n"                    \
  "!READY1 -> X !DECIDE; "                                                     \
  "} "                                                                         \
  "ASSERT { "                                                                  \
  "// for each incremental, locked transmission, the bus is locked as long "   \
  "as requested\n"                                                             \
  "DECIDE -> "                                                                 \
  "X[2] (((INCR && LOCKED) -> (!READY1 W (HREADY && !BUSREQ))) && "            \
  "(!(INCR && LOCKED) -> READY1)); "                                           \
  "// the component stays ready as long as there is no decision\n"             \
  "READY && X !DECIDE -> X READY1; "                                           \
  "// if there is a decision the component blocks the bus for at least two "   \
  "time steps\n"                                                               \
  "READY1 && X DECIDE -> G[1:2] ! READY1; "                                    \
  "} "                                                                         \
  "ASSUME { "                                                                  \
  "// slaves and masters cannot block the bus\n"                               \
  "G F HREADY && G F !BUSREQ; "                                                \
  "} "                                                                         \
  "} "

#define TESTFILE7                                                              \
  ""                                                                           \
  "INFO {\n"                                                                   \
  "TITLE: \"AMBA AHB Arbiter\"\n"                                              \
  "DESCRIPTION: \"Component: TBurst4\"\n"                                      \
  "SEMANTICS: Mealy , Finite\n"                                                \
  "TARGET: Mealy\n"                                                            \
  "}\n"                                                                        \
  "MAIN {\n"                                                                   \
  "INPUTS { BURST4; HREADY; LOCKED; DECIDE; }\n"                               \
  "OUTPUTS { READY2; }\n"                                                      \
  "INITIALLY { !DECIDE; }\n"                                                   \
  "PRESET { READY2; }\n"                                                       \
  "REQUIRE {\n"                                                                \
  "// decisions are only taken if the component is ready\n"                    \
  "!READY2 -> X !DECIDE;\n"                                                    \
  "}\n"                                                                        \
  "ASSERT {\n"                                                                 \
  "// for each burst4, locked transmission, the bus is locked for four time "  \
  "steps\n"                                                                    \
  "DECIDE ->\n"                                                                \
  "X[2] (((BURST4 && LOCKED) -> (!READY2 U (HREADY && !READY2 && X (!READY2 "  \
  "U (HREADY &&\n"                                                             \
  "!READY2 && X (!READY2 U (HREADY && !READY2 && X (!READY2 U (HREADY &&\n"    \
  "!READY2 && XREADY2))))))))) && (!(BURST4 && LOCKED) -> READY2));\n"         \
  "// the component stays ready as long as there is no decision\n"             \
  "READY2 && X !DECIDE -> X READY2;\n"                                         \
  "// if there is a decision the component blocks the bus for at least two "   \
  "time steps\n"                                                               \
  "READY2 && X DECIDE -> G[1:2] ! READY2;\n"                                   \
  "}\n"                                                                        \
  "ASSUME {\n"                                                                 \
  "// a slave block the bus\n"                                                 \
  "G F HREADY;\n"                                                              \
  "}\n"                                                                        \
  "}\n"

#define TESTFILE8                                                              \
  ""                                                                           \
  "INFO {"                                                                     \
  "TITLE: \"AMBA AHB Arbiter\"\n"                                              \
  "DESCRIPTION: \"Component: Lock\"\n"                                         \
  "SEMANTICS: Mealy\n"                                                         \
  "TARGET: Mealy\n"                                                            \
  "}\n"                                                                        \
  "GLOBAL {\n"                                                                 \
  "PARAMETERS {\n"                                                             \
  "n = 2;\n"                                                                   \
  "}\n"                                                                        \
  "DEFINITIONS {\n"                                                            \
  "// mutual exclusion\n"                                                      \
  "mutual(b) =\n"                                                              \
  "||[i IN {0, 1 .. (SIZEOF b) - 1}]\n"                                        \
  "&&[j IN {0, 1 .. (SIZEOF b) - 1} (\\) {i}]\n"                               \
  "!(b[i] && b[j]);\n"                                                         \
  "// checks whether a bus encodes the numerical value v in binary\n"          \
  "value(bus,v) = value'(bus,v,0, SIZEOF bus);\n"                              \
  "value'(bus,v,i,j) =\n"                                                      \
  "j <= 0 : true\n"                                                            \
  "bit(v,i) == 1 : value'(bus,v,i+1,j/2)\n"                                    \
  "&& bus[i]\n"                                                                \
  "otherwise : value'(bus,v,i+1,j/2)\n"                                        \
  "&& !bus[i];\n"                                                              \
  "// returns the i-th bit of the numerical value v\n"                         \
  "bit(v,i) =\n"                                                               \
  "i <= 0 : v % 2\n"                                                           \
  "otherwise : bit(v/2,i-1);\n"                                                \
  "}\n"                                                                        \
  "}\n"                                                                        \
  "MAIN {\n"                                                                   \
  "INPUTS {\n"                                                                 \
  "DECIDE;\n"                                                                  \
  "HGRANT[n];\n"                                                               \
  "HLOCK[n];\n"                                                                \
  "}\n"                                                                        \
  "OUTPUTS {\n"                                                                \
  "LOCKED;\n"                                                                  \
  "}\n"                                                                        \
  "REQUIRE {\n"                                                                \
  "// a every time exactely one grant is high\n"                               \
  "mutual(HGRANT) && ||[0 <= i < n] HGRANT[i];\n"                              \
  "}\n"                                                                        \
  "ASSERT {\n"                                                                 \
  "// whenever a decicion is taken, the LOCKED signal is updated to\n"         \
  "// the HLOCK value of the granted master\n"                                 \
  "&&[0 <= i < n] (DECIDE && X HGRANT[i] -> (X LOCKED <-> X HLOCK[i]));\n"     \
  "// otherwise, the value is copied\n"                                        \
  "!DECIDE -> (X LOCKED <-> LOCKED);\n"                                        \
  "}}\n"

int parse(const char str[]) {
  TLSFSpec spec;
  return parseTLSFString(str, &spec);
}

bool checkInfo(const char str[], const char title[], const char descr[],
               SemType semnt, SemType targt) {
  TLSFSpec spec;
  parseTLSFString(str, &spec);
  bool ret = true;
  ret &= strcmp(spec.title, title) == 0;
  ret &= strcmp(spec.descr, descr) == 0;
  ret &= spec.semnt == semnt;
  ret &= spec.targt == targt;
  return ret;
}

int main(int argc, char *argv[]) {
  /* to avoid silly warnings about unused parameters */
  (void)argc;
  (void)argv;

  switch (atoi(argv[1])) {
  /* plain (syntactic) parsing tests */
  case 1:
    assert(parse(TESTFILE1) == 0);
    break;
  case 2:
    assert(parse(TESTFILE2) == 0);
    break;
  case 3:
    assert(parse(TESTFILE3) == 0);
    break;
  case 4:
    assert(parse(TESTFILE4) == 0);
    break;
  case 5:
    assert(parse(TESTFILE5) == 0);
    break;
  case 6:
    assert(parse(TESTFILE6) == 0);
    break;
  case 7:
    assert(parse(TESTFILE7) == 0);
    break;
  case 8:
    assert(parse(TESTFILE8) == 0);
    break;
  /* check against the information in the tlsf */
  case 9:
    assert(checkInfo(TESTFILE1, "AMBA AHB Arbiter", "Component: Decode",
                     ST_MEALY, ST_MEALY));
    break;
  case 10:
    assert(checkInfo(TESTFILE2, "AMBA AHB Arbiter", "Component: Arbiter",
                     ST_MEALY, ST_MEALY));
    break;
  case 11:
    assert(checkInfo(TESTFILE3, "AMBA AHB Arbiter", "Component: Encode",
                     ST_MEALY, ST_MEALY));
    break;
  case 12:
    assert(checkInfo(TESTFILE4, "AMBA AHB Arbiter", "Component: Shift",
                     ST_MEALY, ST_MEALY));
    break;
  case 13:
    assert(checkInfo(TESTFILE5, "AMBA AHB Arbiter", "Component: TSingle",
                     ST_MEALY, ST_MEALY));
    break;
  case 14:
    assert(checkInfo(TESTFILE6, "AMBA AHB Arbiter", "Component: TIncr",
                     ST_MOORE | ST_STRICT, ST_MOORE));
    break;
  case 15:
    assert(checkInfo(TESTFILE7, "AMBA AHB Arbiter", "Component: TBurst4",
                     ST_MEALY | ST_FINITE, ST_MEALY));
    break;
  case 16:
    assert(checkInfo(TESTFILE8, "AMBA AHB Arbiter", "Component: Lock", ST_MEALY,
                     ST_MEALY));
    break;
  default:
    assert(true);
  }

  return 0;
}
