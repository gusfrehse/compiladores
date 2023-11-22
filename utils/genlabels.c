#include <stdio.h>
#include <stdlib.h>

#include "genlabels.h"

struct genlabels_table *
genlabels_table_init()
{
    return calloc(1, sizeof(struct genlabels_table));
}

struct genlabels_label
genlabels_label_generate(struct genlabels_table *table)
{
    sprintf(table->labels[table->top].label, "R%02i", table->n_labels);
    ++table->n_labels;
    return table->labels[table->top++];
}

struct genlabels_label
genlabels_label_get(struct genlabels_table *table)
{
    return table->labels[--table->top];
}

void
genlabels_table_pop_n(struct genlabels_table *table, int n)
{
    table->top -= n;
}

void
genlabels_print(struct genlabels_table *table)
{
    printf("simbolos: ");
    for (int i = 0; i < table->top; i++)
        printf("'%s'; ", table->labels[i].label);

    printf("\n");
}