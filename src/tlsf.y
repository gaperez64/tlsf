/* Parser for a system of ODEs */

/* %define parse.error detailed */
/* To be compatible with Bison 3.0.4 */
%define parse.error verbose
%define api.prefix {odes}

%code top {
  #include "tlsfparse.h"
  #include "tlsf.lex.h"
  #include "tlsfspec.h"
  #include <stddef.h>
  #include <stdio.h>
}
%code {
  void yyerror(const char *);
  ODEList *finlist;
}

/* tokens that will be used */
%union {
  ODEList *list;
  ExpTree *tree;
  char *str;
}
%token SCOLON LPAR RPAR UNKNOWN
%token ADD SUB MUL DIV EXP EQUAL PRIME
%token <str> NUMBER IDENT
%type <list> odelist odedef
%type <tree> sumofprods prod factor term

%%

spec: odelist { finlist = $1; }
    ;

odelist: odedef          { $$ = $1; }
       | odelist odedef  { $$ = appOdeElem($1, $2); }
       ;

odedef: IDENT PRIME EQUAL sumofprods SCOLON  { $$ = newOdeList($1, $4); }
      ;

sumofprods: prod                 { $$ = $1; }
          | sumofprods ADD prod  { $$ = newExpOp(EXP_ADD_OP, $1, $3); }
          | sumofprods SUB prod  { $$ = newExpOp(EXP_SUB_OP, $1, $3); }
          ;

prod: factor           { $$ = $1; }
    | prod MUL factor  { $$ = newExpOp(EXP_MUL_OP, $1, $3); }
    | prod DIV factor  { $$ = newExpOp(EXP_DIV_OP, $1, $3); }
    ;

factor: term             { $$ = $1; }
      | SUB term         { $$ = newExpOp(EXP_NEG, $2, NULL); }
      | term EXP NUMBER  { ExpTree *n = newExpLeaf(EXP_NUM, $3); 
                           $$ = newExpOp(EXP_EXP_OP, $1, n); }
      ;

term: NUMBER                      { $$ = newExpLeaf(EXP_NUM, $1); }
    | IDENT                       { $$ = newExpLeaf(EXP_VAR, $1); }
    | IDENT LPAR sumofprods RPAR  { $$ = newExpTree(EXP_FUN, $1, $3, NULL); }
    | LPAR sumofprods RPAR        { $$ = $2; }
    ;

%%

void yyerror(const char *str) {
  fprintf(stderr, "[line %d] Error: %s\n", odeslineno, str);
}

int parseOdeString(const char *in, ODEList **ptlist) {
  setOdeInputString(in);
  int rv = yyparse();
  endOdeScan();
  *ptlist = finlist;
  return rv;
}
