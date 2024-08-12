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

%token LCURLY TITLE DESCRIPTION MAIN RPAR
%token SEMANTICS TARGET TAGS RCURLY MEALY COMMA
%token STRICT FINITE MOORE INPUTS OUTPUTS INFO MAX
%token SCOLON INITIALLY PRESET REQUIRE ASSERT MID
%token ASSUME GUARANTEE GLOBAL PARAMETERS DEFINITIONS
%token LSQBRACE RSQBRACE TRUE FALSE ENUM
%token ELLIPSIS ASSIGN OTHERWISE UNKNOWN
%token <str> IDENT MASK STRLIT NUMBER

%right LPAR GREEDYFUN
%right SIZE MIN MAX SIZEOF PLUS_LSQBRACE MUL_LSQBRACE UNARY1
%left MUL
%right DIV MOD
%left PLUS MINUS 
%right INTER_LSQBRACE UNION_LSQBRACE UNARY5
%right SDIFF
%left INTER
%left UNION
%left EQUAL NEQUAL LE LEQ GE GEQ
%left ELEM
%right BANG NOT NEXT EVENTUALLY ALWAYS FORALL EXISTS UNARY11
%left AND
%left OR
%right IMPLIES EQUIV
%right WKUNTIL
%right UNTIL
%left RELEASE
%left PTMATCH
%left COLON

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
       | IDENT LPAR idlist RPAR ASSIGN exp
       ;

idlist: idlist COMMA IDENT
      | IDENT
      ;

gdexps: gdexps boolexp COLON exp
      | gdexps pattexp COLON exp
      | boolexp COLON exp
      | pattexp COLON exp
      ;

pattexp: OTHERWISE
       | exp PTMATCH exp
       ;

opidxlist: setidxlist | rangeidxlist;

setidxlist: setidxlist COMMA IDENT ELEM setexp
          | IDENT ELEM setexp
          ;

rangeidxlist: rangeidxlist COMMA numexp compidx IDENT compidx numexp
            | numexp compidx IDENT compidx numexp
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
        | boolsigs IDENT LSQBRACE numexp RSQBRACE SCOLON
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

bangnum: BANG numexp
       | numexp BANG
       ;

bangrange: BANG numexp COLON numexp
         | numexp COLON numexp BANG
         ;

exp: tlexp;

tlexp: boolexp
     | tlexp RELEASE tlexp
     | tlexp UNTIL tlexp
     | tlexp WKUNTIL tlexp
     | tlexp IMPLIES tlexp
     | tlexp EQUIV tlexp
     | tlexp OR tlexp
     | tlexp AND tlexp
     | NOT tlexp
     | BANG tlexp
     | NEXT tlexp
     | NEXT LSQBRACE numexp RSQBRACE tlexp %prec UNARY11
     | NEXT LSQBRACE BANG RSQBRACE tlexp %prec UNARY11
     | NEXT LSQBRACE bangnum RSQBRACE tlexp %prec UNARY11
     | EVENTUALLY tlexp
     | EVENTUALLY LSQBRACE numexp COLON numexp RSQBRACE tlexp %prec UNARY11
     | EVENTUALLY LSQBRACE bangrange RSQBRACE tlexp %prec UNARY11
     | ALWAYS tlexp
     | ALWAYS LSQBRACE numexp COLON numexp RSQBRACE tlexp %prec UNARY11
     | ALWAYS LSQBRACE bangrange RSQBRACE tlexp %prec UNARY11
     | EXISTS opidxlist RSQBRACE tlexp %prec UNARY11
     | FORALL opidxlist RSQBRACE tlexp %prec UNARY11
     ;

boolexp: numexp
       | boolexp ELEM setexp
       | numexp EQUAL numexp
       | numexp NEQUAL numexp
       | numexp GE numexp
       | numexp GEQ numexp
       | numexp LE numexp
       | numexp LEQ numexp
       ;

setexp: numexp %prec UNARY1
      | setexp UNION setexp
      | setexp INTER setexp
      | setexp SDIFF setexp
      | INTER_LSQBRACE opidxlist RSQBRACE setexp %prec UNARY5
      | UNION_LSQBRACE opidxlist RSQBRACE setexp %prec UNARY5
      ;

numexp: baseexp
      | numexp MINUS numexp
      | numexp PLUS numexp
      | numexp DIV numexp
      | numexp MOD numexp
      | numexp MUL numexp
      | PLUS_LSQBRACE opidxlist RSQBRACE numexp %prec UNARY1
      | MUL_LSQBRACE opidxlist RSQBRACE numexp %prec UNARY1
      | SIZE setexp
      | MID setexp MID
      | MAX setexp
      | MIN setexp
      | SIZEOF IDENT
      ;

baseexp: IDENT LSQBRACE numexp RSQBRACE
       | IDENT LPAR explist RPAR
       | LPAR exp RPAR
       | TRUE
       | FALSE
       | IDENT %prec GREEDYFUN
       | NUMBER
       | LCURLY RCURLY
       | LCURLY explist RCURLY
       | LCURLY exp COMMA exp ELLIPSIS exp RCURLY
       ;
%%
