/* Parser for TLSF */

%define parse.error verbose
%define api.prefix {tlsf}

%code top {
  #include <stddef.h>
  #include <stdio.h>
  #include "tlsfparse.h"
  #include "tlsf.lex.h"
  #include "tlsfspec.h"

  #define APPEND(list, elem)                         \
    do {                                             \
      if ((list).len + 1 >= (list).max) {            \
        size_t newsize =                             \
          (list).max ? (list).max * 2 : 1;           \
        size_t bs = newsize * sizeof(*((list).lst)); \
        (list).lst = realloc(list.lst, bs);          \
        (list).max = newsize;                        \
      }                                              \
      (list).lst[(list).len] = elem;                 \
      (list).len += 1;                               \
    } while (0)

  #define TOARRAY(list, tgtlst, tgtlen) \
    do {                                \
      (tgtlst) = (list).lst;            \
      (tgtlen) = (list).len;            \
    } while (0)

  #define RESET(list)    \
    do {                 \
      (list).lst = NULL; \
      (list).len = 0;    \
      (list).max = 0;    \
    } while (0)
}

%code requires {
  #define LIST(name, elemtype) \
    typedef struct {           \
      elemtype *lst;           \
      size_t len;              \
      size_t max;              \
    } name

  LIST(StrLst, char *);
  LIST(BusEnumLst, BusEnum);
  LIST(EnumValLst, EnumVal);
}

%code {
  static TLSFSpec *spec;
  static BusEnumLst enmlst;

  void yyerror(const char *str) {
    fprintf(stderr, "[line %d] Error: %s\n", tlsflineno, str);
  }
  
  int parseTLSFString(const char *in, TLSFSpec *outspec) {
    setTLSFInputString(in);
    spec = outspec;
  
    /* init some values */
    RESET(enmlst);
    spec->benums = NULL;
    spec->initially = NULL;
    spec->preset = NULL;
    spec->require = NULL;
    spec->assrt = NULL;
    spec->assume = NULL;
    spec->guarantee = NULL;
    /* end init */
  
    int rv = yyparse();
    endTLSFScan();
    return rv;
  }
  
  void delTLSFSpec(TLSFSpec *spec) {
    /* Deleting info section */
    free(spec->title);
    free(spec->descr);
    if (spec->tags != NULL) {
      for (size_t i = 0; i < spec->ntags; i++)
        free(spec->tags[i]);
      free(spec->tags);
    }
    /* Deleting enum symbol table */
    if (spec->benums != NULL) {
      for (size_t i = 0; i < spec->nbenums; i++) {
        for (size_t j = 0; j < spec->benums[i].nvals; j++) {
          for (size_t k = 0; k < spec->benums[i].vals[j].nopts; k++)
            free(spec->benums[i].vals[j].opts[k]);
          free(spec->benums[i].vals[j].opts);
          free(spec->benums[i].vals[j].id);
        }
        free(spec->benums[i].vals);
        free(spec->benums[i].name);
      }
      free(spec->benums);
    }
    
    /* Deleting formulas */
    if (spec->initially != NULL)
      delExpTree(spec->initially);
    if (spec->preset != NULL)
      delExpTree(spec->preset);
    if (spec->require != NULL)
      delExpTree(spec->require);
    if (spec->assrt != NULL)
      delExpTree(spec->assrt);
    if (spec->assume != NULL)
      delExpTree(spec->assume);
    if (spec->guarantee != NULL)
      delExpTree(spec->guarantee);
  }
}

/* tokens that will be used */
%union {
  ExpTree *tree;
  char *str;
  int num;
  SemType sem;
  StrLst strlst;
  EnumValLst evllst;
}
%token LCURLY TITLE COLON DESCRIPTION MAIN LPAR RPAR
%token SEMANTICS TARGET TAGS RCURLY MEALY COMMA DIV BANG
%token STRICT FINITE MOORE INPUTS OUTPUTS INFO MAX PTMATCH
%token SCOLON INITIALLY PRESET REQUIRE ASSERT MID EXISTS
%token ASSUME GUARANTEE RELEASE UNTIL WKUNTIL SIZE FORALL
%token GLOBAL PARAMETERS DEFINITIONS EQUAL ENUM MOD ADD
%token IMPLIES EQUIV OR AND NOT NEXT EVENTUALLY MIN MUL
%token ALWAYS LSQBRACE RSQBRACE TRUE FALSE SIZEOF SUM
%token MINUS ELLIPSIS UNION INTER SDIFF ASSIGN PLUS PROD
%token ELEM NEQUAL LE LEQ GE GEQ OTHERWISE TIMES CAP CUP
%token UNKNOWN
%token <str> IDENT MASK STRLIT NUMBER
%type <sem> target semantics
%type <strlst> tags masklist opttags
%type <evllst> enumvals

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
          | ;

parlist: parlist IDENT ASSIGN exp SCOLON
       | ;

definitions: DEFINITIONS LCURLY
             deflist
             RCURLY
           { TOARRAY(enmlst, spec->benums, spec->nbenums); }
           | ;

deflist: deflist IDENT ASSIGN exp SCOLON
       | deflist fundecl SCOLON
       | deflist enumdecl SCOLON
       | ;

enumdecl: ENUM IDENT ASSIGN enumvals    { BusEnum be;
                                          be.name = $2;
                                          TOARRAY($4, be.vals, be.nvals);
                                          APPEND(enmlst, be); }
        ;

enumvals: IDENT COLON masklist          { EnumVal ev; 
                                          ev.id = $1;
                                          TOARRAY($3, ev.opts, ev.nopts);
                                          RESET($$);
                                          APPEND($$, ev); }
        | enumvals IDENT COLON masklist { EnumVal ev;
                                          ev.id = $2;
                                          TOARRAY($4, ev.opts, ev.nopts);
                                          $$ = $1;
                                          APPEND($$, ev); }
        ;

masklist: MASK                  { RESET($$); APPEND($$, $1); }
        | NUMBER                { RESET($$); APPEND($$, $1); }
        | masklist COMMA MASK   { $$ = $1; APPEND($$, $3); }
        | masklist COMMA NUMBER { $$ = $1; APPEND($$, $3); }
        ;

fundecl: IDENT LPAR idlist RPAR ASSIGN gdexps
       ;

idlist: idlist COMMA IDENT
      | IDENT
      ;

gdexps: gdexps exp
      | gdexps exp COLON exp
      | gdexps pattexp COLON exp
      | exp
      | exp COLON exp
      | pattexp COLON exp
      ;

pattexp: OTHERWISE
       | exp PTMATCH exp
       ;

opidxlist: setidxlist | rangeidxlist;

setidxlist: setidxlist COMMA IDENT ELEM exp8
          | IDENT ELEM exp8
          ;

rangeidxlist: rangeidxlist COMMA exp4 compidx IDENT compidx exp4
            | exp4 compidx IDENT compidx exp4
            ;

compidx: LEQ | LE;

explist: exp COMMA explist
       | exp;

info: INFO LCURLY 
      TITLE COLON STRLIT         
      DESCRIPTION COLON STRLIT   
      SEMANTICS COLON semantics  
      TARGET COLON target        
      opttags                    
      RCURLY
    { spec->title = $5;
      spec->descr = $8;
      spec->semnt = $11;
      spec->targt = $14;
      TOARRAY($15, spec->tags, spec->ntags); }
    ;

opttags: TAGS COLON tags { $$ = $3; }
       |                 { RESET($$); }
       ;

semantics: target              { $$ = $1; }
         | target COMMA STRICT { $$ = $1 | ST_STRICT; }
         | target COMMA FINITE { $$ = $1 | ST_FINITE; }
         ;

target: MEALY { $$ = ST_MEALY; }
      | MOORE { $$ = ST_MOORE; }
      ;

tags: tags COMMA STRLIT { $$ = $1; APPEND($$, $3); }
    | STRLIT            { RESET($$); APPEND($$, $1); }
    ;

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
        | boolsigs IDENT LSQBRACE exp RSQBRACE SCOLON
        | boolsigs IDENT IDENT SCOLON
        | ;

initially: INITIALLY LCURLY expseq RCURLY | ;

preset: PRESET LCURLY expseq RCURLY | ;

require: REQUIRE LCURLY expseq RCURLY | ;

assert: ASSERT LCURLY expseq RCURLY | ;

assume: ASSUME LCURLY expseq RCURLY | ;

guarantee: GUARANTEE LCURLY expseq RCURLY | ;

expseq: expseq exp SCOLON
      | ;

bangnum: BANG exp4
       | exp4 BANG
       ;

bangrange: BANG exp4 COLON exp4
         | exp4 COLON exp4 BANG
         ;

exp: exp17;

exp17: exp16
     | exp17 RELEASE exp16
     ;

exp16: exp15
     | exp15 UNTIL exp16
     ;

exp15: exp14
     | exp14 WKUNTIL exp15
     ;

exp14: exp13
     | exp13 IMPLIES exp14 
     | exp13 EQUIV exp14
     ;

exp13: exp12
     | exp13 OR exp12
     ;

exp12: exp11
     | exp12 AND exp11
     ;

exp11: exp10
     | NOT exp11
     | BANG exp11
     | NEXT exp11
     | NEXT LSQBRACE exp4 RSQBRACE exp11
     | NEXT LSQBRACE BANG RSQBRACE exp11
     | NEXT LSQBRACE bangnum RSQBRACE exp11
     | EVENTUALLY exp11
     | EVENTUALLY LSQBRACE exp4 COLON exp RSQBRACE exp11
     | EVENTUALLY LSQBRACE bangrange RSQBRACE exp11
     | ALWAYS exp11
     | ALWAYS LSQBRACE exp4 COLON exp RSQBRACE exp11
     | ALWAYS LSQBRACE bangrange RSQBRACE exp11
     | AND LSQBRACE opidxlist RSQBRACE exp11
     | OR LSQBRACE opidxlist RSQBRACE exp11
     | EXISTS LSQBRACE opidxlist RSQBRACE exp11
     | FORALL LSQBRACE opidxlist RSQBRACE exp11
     ;

exp10: exp9
      | exp10 ELEM exp8
      ;

exp9: exp8
     | exp9 EQUAL exp8
     | exp9 NEQUAL exp8
     | exp9 GE exp8
     | exp9 GEQ exp8
     | exp9 LE exp8
     | exp9 LEQ exp8
     ;

exp8: exp7
    | exp8 UNION exp7
    ;

exp7: exp6
    | exp7 INTER exp6
    ;

exp6: exp5
    | exp5 SDIFF exp6
    ;

exp5: exp4
    | CAP LSQBRACE opidxlist RSQBRACE exp5
    | CUP LSQBRACE opidxlist RSQBRACE exp5
    ;

exp4: exp3
    | exp4 MINUS exp3
    | exp4 PLUS exp3
    | exp4 ADD exp3
    ;

exp3: exp2
    | exp2 DIV exp3
    | exp2 MOD exp3
    ;

exp2: exp1
    | exp2 TIMES exp1
    | exp2 MUL exp1
    ;

exp1: expbase
    | SUM LSQBRACE opidxlist RSQBRACE exp1
    | PLUS LSQBRACE opidxlist RSQBRACE exp1
    | PROD LSQBRACE opidxlist RSQBRACE exp1
    | TIMES LSQBRACE opidxlist RSQBRACE exp1
    | SIZE exp8
    | MID exp8 MID
    | MAX exp8
    | MIN exp8
    | SIZEOF IDENT
    ;

expbase: IDENT LSQBRACE exp4 RSQBRACE
       | IDENT LPAR explist RPAR
       | LPAR exp RPAR
       | TRUE
       | FALSE
       | IDENT
       | NUMBER
       | LCURLY RCURLY
       | LCURLY explist RCURLY
       | LCURLY exp COMMA exp ELLIPSIS exp RCURLY
       ;

%%
