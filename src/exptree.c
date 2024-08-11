#include "exptree.h"
#include <stddef.h>
#include <stdlib.h>

void delExpTree(ExpTree *root) {
  if (root->data != NULL)
    free(root->data);
  if (root->left != NULL)
    delExpTree(root->left);
  if (root->right != NULL)
    delExpTree(root->right);
  free(root);
}
