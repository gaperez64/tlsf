/* Scanner for TLSF */

%{
#include <stdlib.h>
#include "tlsfspec.h"
#include "tlsfparse.h"
#include "tlsf.tab.h"

void yyerror(char const *);

char string_buf[100];
char *string_buf_ptr;
%}

%option yylineno
%option noyywrap
%option noinput
%option nounput
%option prefix="tlsf"

%x C_COMMENT C_STRLIT

%%

"/*"             { BEGIN(C_COMMENT); }
<C_COMMENT>"*/"  { BEGIN(INITIAL); }
<C_COMMENT>.     { /* do nothing */ }
"//".*           { /* ignore single-line comments */ }
\"               { string_buf_ptr = string_buf;
                   BEGIN(C_STRLIT); }
<C_STRLIT>([^\"]|\n) { *string_buf_ptr++ = yytext[1]; } 
<C_STRLIT>\"         { BEGIN(INITIAL);
                       *string_buf_ptr = '\0';
                       tlsflval.str = strdup(string_buf);
                       return STRLIT; }

"+" { return PLUS; }
"-" { return MINUS; }
"*" { return TIMES; }
"/" { return DIV; }
"%" { return MOD; }
"=" { return ASSIGN; }
":" { return COLON; }
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
"(-)"    { return SDIFF; }
"(\\)"   { return SDIFF; }
"SUM"    { return SUM; }
"PROD"   { return PROD; }
"SIZE"   { return SIZE; }
"MUL"    { return MUL; }
"DIV"    { return DIV; }
"MOD"    { return MOD; }
"PLUS"   { return ADD; }
"MINUS"  { return MINUS; }
"CAP"    { return INTER; }
"CUP"    { return UNION; }
"=="     { return EQUAL; }
"EQ"     { return EQUAL; }
"!="     { return NEQUAL; }
"/="     { return NEQUAL; }
"NEQ"    { return NEQUAL; }
"<"      { return LE; }
"LE"     { return LE; }
"<="     { return LEQ; }
"LEQ"    { return LEQ; }
">"      { return GE; }
"GE"     { return GE; }
">="     { return GEQ; }
"GEQ"    { return GEQ; }

"SETMINUS" { return SDIFF; }
"IN"       { return ELEM; }
"<-"       { return ELEM; }
"ELEM"     { return ELEM; }
"!"        { return BANG; }
"NOT"      { return NOT; }
"X"        { return NEXT; }
"G"        { return ALWAYS; }
"F"        { return EVENTUALLY; }
"&&"       { return AND; }
"AND"      { return AND; }
"FORALL"   { return FORALL; }
"||"       { return OR; }
"OR"       { return OR; }
"EXISTS"   { return EXISTS; }
"->"       { return IMPLIES; }
"IMPLIES"  { return IMPLIES; }
"<->"      { return EQUIV; }
"EQUIV"    { return EQUIV; }
"U"        { return UNTIL; }
"W"        { return WKUNTIL; }
"R"        { return RELEASE; }
"~"        { return PTMATCH; }
".."       { return ELLIPSIS; }
"otherwise" { return OTHERWISE; }

"true"     { return TRUE; }
"false"    { return FALSE; }

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
"GUARANTEES"  { return GUARANTEE; }
"GLOBAL"      { return GLOBAL; }
"PARAMETERS"  { return PARAMETERS; }
"DEFINITIONS" { return DEFINITIONS; }
"enum"        { return ENUM; }

"Mealy"  { return MEALY; }
"Strict" { return STRICT; }
"Finite" { return FINITE; }
"Moore"  { return MOORE; }


[0-9][0-9]*               { tlsflval.str = strdup(yytext); return NUMBER; }
[@_a-zA-Z][@'_a-zA-Z0-9]* { tlsflval.str = strdup(yytext); return IDENT; }
[01*][01*]*               { tlsflval.str = strdup(yytext); return MASK; }

[ \t\n] { /* ignore white spaces */ }
.       { fprintf(stderr, "[line %d] Unexpected symbol: %c\n",tlsflineno, *yytext);
          return UNKNOWN; }

%%

void setTLSFInputString(const char *in) {
  yy_scan_string(in);
}

void endTLSFScan(void) {
  yy_delete_buffer(YY_CURRENT_BUFFER);
}
