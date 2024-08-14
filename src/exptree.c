#include "exptree.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

void delExpTree(ExpTree *root) {
  if (root->str != NULL)
    free(root->str);
  if (root->left != NULL)
    delExpTree(root->left);
  if (root->right != NULL)
    delExpTree(root->right);
  free(root);
}

int evalConstNumExp(ExpTree *root, Param *symtab) {
  switch (root->type) {
  case XT_SUB:
    return evalConstNumExp(root->left, symtab) -
           evalConstNumExp(root->right, symtab);
  case XT_ADD:
    return evalConstNumExp(root->left, symtab) +
           evalConstNumExp(root->right, symtab);
  case XT_DIV:
    return evalConstNumExp(root->left, symtab) /
           evalConstNumExp(root->right, symtab);
  case XT_MOD:
    return evalConstNumExp(root->left, symtab) %
           evalConstNumExp(root->right, symtab);
  case XT_MUL:
    return evalConstNumExp(root->left, symtab) *
           evalConstNumExp(root->right, symtab);
  case XT_NUM:
    return root->val;
  default:
    fprintf(stderr,
            "Error: unsupported ExpType %d "
            "in constant number expression\n",
            root->type);
    abort();
  }
}
