#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "symbols_table.h"

struct symbols_symbol
symbols_table_create_symbol(const char *name,
                            enum symbols_types type,
                            int lexical_level,
                            struct symbols_content content,
                            int offset)
{
    return (struct symbols_symbol){
        .name = strdup(name),
        .type = type,
        .lexical_level = lexical_level,
        .content = content,
        .offset = offset,
    };
}

struct symbols_table *
symbols_table_init(void)
{
    return calloc(1, sizeof(struct symbols_table));
}

void
symbols_table_add(struct symbols_table *table, struct symbols_symbol sym)
{
    table->symbols[table->top++] = sym;
}

struct symbols_symbol
symbols_table_remove(struct symbols_table *table)
{
    return table->symbols[--table->top];
}

void
symbols_table_add_type(struct symbols_table *table,
                       enum symbols_variables var_type,
                       int amount)
{
    for (int i = table->top - 1; i >= table->top - amount; --i)
        table->symbols[i].content.var_type = var_type;
}

struct symbols_symbol *
symbols_table_lookup(struct symbols_table *table, const char *name)
{
    for (int i = table->top - 1; i >= 0; --i)
        if (0 == strcmp(table->symbols[i].name, name))
            return &table->symbols[i];
    return NULL;
}

void
symbols_table_pop_n(struct symbols_table *table, int n)
{
    table->top -= n;
}

void
symbols_table_print(struct symbols_table *table)
{
    printf("numero de symbols %i\n", table->top - 1);
    for (int i = table->top - 1; i >= 0; i--) {
        if (table->symbols[i].type == SYMBOLS_TYPES_PROCEDURE
            || table->symbols[i].type == SYMBOLS_TYPES_FUNCTION)
        {
            printf("Simbolo %i: token = %s || nivel = %i || rotulo = %s ", i,
                   table->symbols[i].name, table->symbols[i].lexical_level,
                   table->symbols[i].content.proc.label);
            for (int j = 0; j < table->symbols[i].content.proc.n_params; j++) {
                printf("\tP%i[T: %i|PASS: %i] ", j,
                       table->symbols[i].content.proc.params[j].type,
                       table->symbols[i].content.proc.params[j].kind);
            }
            printf("\n");
        }
        else {
            printf("Simbolo %i: token = %s || nivel = %i || desloc = %i \n", i,
                   table->symbols[i].name, table->symbols[i].lexical_level,
                   table->symbols[i].offset);
        }
    }
}

void
symbols_table_remove_until(struct symbols_table *table, const char *name)
{
    printf("removendo func/proc %s\n", name);
    struct symbols_symbol *sym = NULL;
    int i;

    for (i = table->top - 1; i >= 0; i--) {
        if (0 == strcmp(table->symbols[i].name, name)
            && (table->symbols[i].type == SYMBOLS_TYPES_PROCEDURE
                || table->symbols[i].type == SYMBOLS_TYPES_FUNCTION))
        {
            sym = &table->symbols[i];
            --table->top;
            break;
        }

        symbols_table_print(table);
        --table->top;
    }

    for (--i; i >= 0; i--) {
        if (table->symbols[i].offset >= 0) break;

        --table->top;
        symbols_table_print(table);
    }
    symbols_table_add(table, *sym);
    symbols_table_print(table);
}

void
symbols_table_set_offset(struct symbols_table *table, int n_params)
{
    int offset = 0;
    for (int i = table->top - 1; i >= table->top - n_params; --i)
        table->symbols[i].offset = -4 + offset--;
}
