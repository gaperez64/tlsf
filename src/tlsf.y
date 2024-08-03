/* Parser for TLSF */

/* %define parse.error detailed */
/* To be compatible with Bison 3.0.4 */
%define parse.error verbose
%define api.prefix {tlsf}

%code top {
  #include <stddef.h>
  #include <stdio.h>
  #include "tlsfparse.h"
  #include "tlsf.lex.h"
  #include "tlsfspec.h"
}
%code {
  void yyerror(const char *);
  TLSFSpec *spec;
}

/* tokens that will be used */
%union {
  ExpTree *tree;
  char *str;
  int num;
}
%token LCURLY TITLE COLON STRLIT DESCRIPTION MAIN
%token SEMANTICS TARGET TAGS RCURLY MEALY COMMA DIV
%token STRICT FINITE MOORE INPUTS OUTPUTS INFO MAX
%token SCOLON INITIALLY PRESET REQUIRE ASSERT MID EXISTS
%token ASSUME GUARANTEE RELEASE UNTIL WKUNTIL SIZE FORALL
%token GLOBAL PARAMETERS DEFINITIONS EQUAL ENUM MOD ADD
%token IMPLIES EQUIV OR AND NOT NEXT EVENTUALLY MIN MUL
%token ALWAYS LSQBRACE RSQBRACE TRUE FALSE SIZEOF SUM
%token MINUS ELLIPSIS UNION INTER SDIFF ASSIGN PLUS PROD
%token ELEM EQUAL NEQUAL LE LEQ GE GEQ OTHERWISE TIMES
%token <str> IDENT MASK
%token <num> NUMBER

%%

spec: info main
    | info global main
    ;

global: GLOBAL LCURLY
        parameters
        definitions
        RCURLY
      ;

parameters: PARAMETERS LCURLY
            parlist
            RCURLY
          ;

parlist: parlist IDENT EQUALS numexp SCOLON
       | ;

numexp: numexp5;

numexp5: numexp4
       | CAP LSQBRACE opidxlist RSQBRACE numexp5
       | CUP LSQBRACE opidxlist RSQBRACE numexp5
       ;

numexp4: numexp3
       | numexp4 MINUS numexp3
       | numexp4 PLUS numexp3
       | numexp4 ADD numexp3
       ;

numexp3: numexp2
       | numexp2 DIV numexp3
       | numexp2 MOD numexp3
       ;

numexp2: numexp1
       | numexp2 TIMES numexp1
       | numexp2 MUL numexp1
       ;

numexp1: numbase
       | SUM LSQBRACE opidxlist RSQBRACE numexp1
       | PLUS LSQBRACE opidxlist RSQBRACE numexp1
       | PROD LSQBRACE opidxlist RSQBRACE numexp1
       | TIMES LSQBRACE opidxlist RSQBRACE numexp1
       | SIZE setexp
       | MID setexp MID
       | MAX setexp
       | MIN setexp
       | SIZEOF IDENT
       ;

numbase: IDENT | NUMBER | LPAR numexp RPAR;

definitions: DEFINITIONS LCURLY
             deflist
             RCURLY
           ;

deflist: deflist IDENT EQUALS genexp SCOLON
       | deflist fundecl SCOLON
       | deflist enumdecl SCOLON
       | ;

enumdecl: ENUM IDENT EQUALS enumvals;

enumvals: IDENT COLON masklist
        | enumvals IDENT COLON masklist
        ;

masklist: MASK
        | masklist COMMA MASK
        ;

fundecl: IDENT LPAR idlist RPAR EQUALS gdexplist
       ;

idlist: idlist COMMA IDENT
      | IDENT
      ;

gdexplist: gdexplist COMMA genexp
         | gdexplist COMMA boolexp COLON genexp
         | gdexplist COMMA pattexp COLON genexp
         | genexp
         | boolexp COLON genexp
         | pattexp COLON genexp
         ;

pattexp: OTHERWISE
       | ltlexp PTMATCH ltlexp
       ;

opidxlist: setidxlist | rangeidxlist;

setidxlist: setidxlist COMMA IDENT ELEM setexp
          | IDENT ELEM setexp
          ;

rangeidxlist: rangeidxlist COMMA NUMBER compidx IDENT compidx NUMBER
            | NUMBER compidx IDENT compidx NUMBER
            ;

compidx: LEQ | LE;

genexp: ltlexp | numexp | setexp | boolexp;

setexp: setexp8;

setexp8: setexp7
       | setexp8 UNION setexp7
       ;

setexp7: setexp6
       | setexp7 INTER setexp6
       ;

setexp6: setbase
       | setbase SDIFF setexp6
       ;

setbase: IDENT
       | LCURLY genlist RCURLY
       | LCURLY numexp COMMA numexp ELLIPSIS numexp RCURLY
       | LPAR setexp RPAR
       ;

boolexp: boolexp14;

boolexp14: boolexp13
         | boolexp13 IMPLIES boolexp14
         | boolexp13 EQUIV boolexp14
         ;

boolexp13: boolexp12
         | boolexp13 OR boolexp12
         ;

boolexp12: boolexp11
         | boolexp12 AND boolexp11;
         ;

boolexp11: boolexp10
         | NOT boolexp11
         | AND LSQBRACE opidxlist RSQBRACE boolexp11
         | OR LSQBRACE opidxlist RSQBRACE boolexp11
         | EXISTS LSQBRACE opidxlist RSQBRACE boolexp11
         | FORALL LSQBRACE opidxlist RSQBRACE boolexp11
         ;

boolexp10: boolexp9
         | genexp ELEM setexp
         ;

boolexp9: boolbase
        | numexp EQUAL boolbase
        | numexp NEQUAL numexp
        | numexp GE numexp
        | numexp GEQ numexp
        | numexp LE numexp
        | numexp LEQ numexp
        ;

boolbase: TRUE
        | FALSE
        | IDENT
        | LPAR boolexp RPAR
        ;

genlist: genlistplus | ;

genlistplus: genlistplus COMMA genexp
           | genexp;

info: INFO LCURLY 
      TITLE COLON STRLIT
      DESCRIPTION COLON STRLIT
      SEMANTICS COLON semantics
      TARGET COLON target
      TAGS COLON tags
      RCURLY
    ;

semantics: MEALY
         | MEALY COMMA STRICT
         | MEALY OMMA FINITE
         | MOORE
         | MOORE COMMA STRICT
         | MOORE COMMA FINITE
         ;

target: MEALY
      | MOORE
      ;

tags: tags COMMA STRLIT
    | ;

main: MAIN LCURLY
      INPUTS LCURLY boolsigs RCURLY
      OUTPUTS LCURLY boolsigs RCURLY
      initially
      preset
      require
      assert
      assume
      guarantee
      RCURLY
    ;

boolsigs: boolsigs IDENT SCOLON
        | boolsigs IDENT LSQBRACE numexp RSQBRACE SCOLON
        | boolsigs IDENT IDENT SCOLON
        | ;

initially: INITIALLY LCURLY ltlexp RCURLY | ;

preset: PRESET LCURLY ltlexp RCURLY | ;

require: REQUIRE LCURLY ltlexp RCURLY | ;

assert: ASSERT LCURLY ltlexp RCURLY | ;

assume: ASSUME LCURLY ltlexp RCURLY | ;

guarantee: GUARANTEE LCURLY ltlexp RCURLY | ;

ltlexp: ltlexp17;

ltlexp17: ltlexp16
        | ltlexp17 RELEASE ltlexp16
        ;

ltlexp16: ltlexp15
        | ltlexp15 UNTIL ltlexp16
        ;

ltlexp15: ltlexp14
        | ltlexp14 WKUNTIL ltlexp15
        ;

ltlexp14: ltlexp13
        | ltlexp13 IMPLIES ltlexp14
        | ltlexp13 EQUIV ltlexp14
        ;

ltlexp13: ltlexp12
        | ltlexp13 OR ltlexp12
        ;

ltlexp12: ltlexp11
        | ltlexp12 AND ltlexp11;
        ;

ltlexp11: ltlbase
        | NOT ltlexp11
        | NEXT ltlexp11
        | NEXT LSQBRACE numexp RSQBRACE ltlexp11
        | NEXT LSQBRACE BANG RSQBRACE ltlexp11
        | NEXT LSQBRACE bangnum RSQBRACE ltlexp11
        | EVENTUALLY ltlexp11
        | EVENTUALLY LSQBRACE numexp COLON numexp RSQBRACE ltlexp11
        | EVENTUALLY LSQBRACE bangrange RSQBRACE ltlexp11
        | ALWAYS ltlexp11
        | ALWAYS LSQBRACE numexp COLON numexp RSQBRACE ltlexp11
        | ALWAYS LSQBRACE bangrange RSQBRACE ltlexp11
        | AND LSQBRACE opidxlist RSQBRACE ltlexp11
        | OR LSQBRACE opidxlist RSQBRACE ltlexp11
        | EXISTS LSQBRACE opidxlist RSQBRACE ltlexp11
        | FORALL LSQBRACE opidxlist RSQBRACE ltlexp11
        ;

bangnum: BANG numexp
       | numexp BANG
       ;

bangrange: BANG numexp COLON numexp
         | numexp COLON numexp BANG
         ;

ltlbase: boolexp
       | IDENT LSQBRACE numexp RSQBRACE
       | IDENT EQUAL IDENT
       | IDENT NEQUAL IDENT
       | LPAR ltlexp RPAR
       ;

%%

void yyerror(const char *str) {
  fprintf(stderr, "[line %d] Error: %s\n", tlsflineno, str);
}

int parseOdeString(const char *in, TLSFSpec *outspec) {
  setTLSFInputString(in);
  int rv = yyparse();
  endTLSFScan();
  spec = outspec;
  return rv;
}
