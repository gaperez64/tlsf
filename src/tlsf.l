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

%x Q_COMMENT Q_STRLIT

%%

"/*"             { BEGIN(Q_COMMENT); }
<Q_COMMENT>"*/"  { BEGIN(INITIAL); }
<Q_COMMENT>.     { /* do nothing */ }
"//".*           { /* ignore single line comments */ }
\"               { string_buf_ptr = string_buf;
                   BEGIN(Q_STRLIT); }
<Q_STRLIT>[^\"]  { *string_buf_ptr++ = yytext[0]; } 
<Q_STRLIT>\"     { BEGIN(INITIAL);
                   *string_buf_ptr = '\0';
                   tlsflval.str = strdup(string_buf);
                   return STRLIT; }

"+" { return PLUS; }
"-" { return MINUS; }
"*" { return MUL; }
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

"+[" { return PLUS_LSQBRACE; }
"*[" { return MUL_LSQBRACE; }
"SUM[" { return PLUS_LSQBRACE; }
"PROD[" { return MUL_LSQBRACE; }

"MIN"    { return MIN; }
"MAX"    { return MAX; }
"SIZEOF" { return SIZEOF; }
"(+)"    { return UNION; }
"(*)"    { return INTER; }
"(-)"    { return SDIFF; }
"(\\)"   { return SDIFF; }
"SIZE"   { return SIZE; }
"MUL"    { return MUL; }
"DIV"    { return DIV; }
"MOD"    { return MOD; }
"PLUS"   { return PLUS; }
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

"(*)[" { return UNION_LSQBRACE; }
"(+)[" { return INTER_LSQBRACE; }
"CUP[" { return UNION_LSQBRACE; }
"CAP[" { return INTER_LSQBRACE; }

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
"||"       { return OR; }
"OR"       { return OR; }
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

"&&[" { return FORALL; }
"||[" { return EXISTS; }
"FORALL[" { return FORALL; }
"EXISTS[" { return EXISTS; }
"AND[" { return FORALL; }
"OR["  { return EXISTS; }

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
