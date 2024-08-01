/* Scanner for a system of ODEs */

%{
#include "tlsfspec.h"
#include "tlsfparse.h"
#include "tlsf.tab.h"

void yyerror(char const *);
%}

%option yylineno
%option noyywrap
%option noinput
%option nounput
%option prefix="tlsf"

%x C_COMMENT

%%

"/*"            { BEGIN(C_COMMENT); }
<C_COMMENT>"*/" { BEGIN(INITIAL); }
<C_COMMENT>.    { /* do nothing */ }
"//".*          { /* ignore single line comments */ }


"+" { return ADD; }
"-" { return SUB; }
"*" { return MUL; }
"/" { return DIV; }
"%" { return MOD; }
"=" { return EQUAL; }
";" { return SCOLON; }
"," { return COMMA; }
"(" { return LPAR; }
"{" { return LCURLY; }
"[" { return LSQBRACE; }
")" { return RPAR; }
"}" { return RCURLY; }
"]" { return RSQBRACE; }
"|" { return MID; }
"MIN"    { return MIN; }
"MAX"    { return MAX; }
"SIZEOF" { return SIZEOF; }
"(+)"    { return UNION; }
"(*)"    { return INTER; }
"(\)"    { return SDIFF; }

"INFO"        { return INFO; }
"TITLE"       { return TITLE; }
"DESCRIPTION" { return DESCRIPTION; }
"SEMANTICS"   { return SEMANTICS; }
"TARGET"      { return TARGET; }
"TAGS"        { return TAGS; }
"MAIN"        { return MAIN; }
"INPUTS"      { return INPUTS; }
"OUTPUTS"     { return OUTPUTS; }
"INITIALLY"   { return INITIALLY; }
"PRESET"      { return PRESET; }
"REQUIRE"     { return REQUIRE; }
"ASSERT"      { return ASSERT; }
"INVARIANTS"  { return ASSERT; }
"ASSUME"      { return ASSUME; }
"ASSUMPTIONS" { return ASSUME; }
"GUARANTEE"   { return GUARANTEE; }
"GUARANTEES"  { return GUARANTEES; }
"GLOBAL"      { return GLOBAL; }
"PARAMETERS"  { return PARAMETERS; }
"DEFINITIONS" { return DEFINITIONS; }

"Mealy"        { return MEALY; }
"Mealy,Strict" { return STMEALY; }
"Mealy,Finite" { return FMEALY; }
"Moore"        { return MOORE; }
"Moore,Strict" { return STMOORE; }
"Moore,Finite" { return FMOORE; }

"X"    { return WKNEXT; }
"X[!]" { return STNEXT; }
"G"    { return ALWAYS; }
"F"    { return EVENTUALLY; }
"U"    { return UNTIL; }
"W"    { return WKUNTIL; }

[0-9](\.[0-9]*)?          { tlsflval.str = strdup(yytext); return NUMBER; }
[@_a-zA-Z][@'_a-zA-Z0-9]* { tlsflval.str = strdup(yytext); return IDENT; }

[ \t\n] { /* ignore white spaces */ }
.       { fprintf(stderr, "Unexpected symbol: %c\n", *yytext); return UNKNOWN; }

%%

void setTLSFInputString(const char *in) {
  yy_scan_string(in);
}

void endTLSFScan(void) {
  yy_delete_buffer(YY_CURRENT_BUFFER);
}
