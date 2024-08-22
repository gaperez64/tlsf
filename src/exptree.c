#include "exptree.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void delExpTree(ExpTree *root) {
  if (root->str != NULL)
    free(root->str);
  if (root->left != NULL)
    delExpTree(root->left);
  if (root->right != NULL)
    delExpTree(root->right);
  free(root);
}

int findParam(char *id, Param *symtab, size_t numsym) {
  for (size_t i = 0; i < numsym; i++)
    if (strcmp(id, symtab[i].id) == 0)
      return symtab[i].val;
  /* All parameters should have a natural value, so -1 is a BAD flag */
  return -1;
}

int evalConstNumExp(ExpTree *root, Param *symtab, size_t numsym) {
  switch (root->type) {
  case XT_ID:
    return findParam(root->str, symtab, numsym);
  case XT_SUB:
    return evalConstNumExp(root->left, symtab, numsym) -
           evalConstNumExp(root->right, symtab, numsym);
  case XT_ADD:
    return evalConstNumExp(root->left, symtab, numsym) +
           evalConstNumExp(root->right, symtab, numsym);
  case XT_DIV:
    return evalConstNumExp(root->left, symtab, numsym) /
           evalConstNumExp(root->right, symtab, numsym);
  case XT_MOD:
    return evalConstNumExp(root->left, symtab, numsym) %
           evalConstNumExp(root->right, symtab, numsym);
  case XT_MUL:
    return evalConstNumExp(root->left, symtab, numsym) *
           evalConstNumExp(root->right, symtab, numsym);
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
