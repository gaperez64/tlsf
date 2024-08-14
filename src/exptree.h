#ifndef EXPTREE_H
#define EXPTREE_H

typedef enum ExpType {
  XT_ID,
  XT_SUB,
  XT_ADD,
  XT_DIV,
  XT_MOD,
  XT_MUL,
  XT_LEN,
  XT_MAX,
  XT_MIN,
  XT_SIZEOF,
  XT_SUM,    /* over indexed expression */
  XT_PROD,   /* over indexed expression */
  XT_FUN,
  XT_NUM,
  XT_LST,    /* for linked list */
} ExpType;

typedef struct Param {
  char *id;
  int val;
} Param;

/* Essentially a binary tree with node type */
typedef struct ExpTree {
  ExpType type;
  char *str;
  int val;
  struct ExpTree *left;
  struct ExpTree *right;
} ExpTree;

int evalConstNumExp(ExpTree *, Param *);
void delExpTree(ExpTree *);

#endif
