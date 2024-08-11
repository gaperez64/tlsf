#ifndef EXPTREE_H
#define EXPTREE_H

typedef enum ExpType {
  XT_AP,
} ExpType;

/* Essentially a binary tree with node type */
typedef struct ExpTree {
  void *data;
  ExpType type;
  struct ExpTree *left;
  struct ExpTree *right;
} ExpTree;

void delExpTree(ExpTree *);

#endif
