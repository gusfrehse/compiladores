#ifndef SYMBOLS_TABLE_H
#define SYMBOLS_TABLE_H

enum symbols_types {
    SYMBOLS_TYPES_VARIABLE,
    SYMBOLS_TYPES_PARAMETER,
    SYMBOLS_TYPES_PROCEDURE,
    SYMBOLS_TYPES_FUNCTION
};

enum symbols_variables {
    SYMBOLS_VARIABLES_INTEGER,
    SYMBOLS_VARIABLES_BOOLEAN,
    SYMBOLS_VARIABLES_UNDEFINED
};

enum symbols_parameters_kind {
    SYMBOLS_PARAMETERS_COPY,
    SYMBOLS_PARAMETERS_REFERENCE
};

struct symbols_parameter {
        enum symbols_variables type;
        enum symbols_parameters_kind kind;
};

struct symbols_content {
    enum symbols_variables var_type;
    struct symbols_parameter param;
    struct {
        char label[20]; // rotulo de desvio
        char forwarded_label[20];
        int n_params;
        struct symbols_parameter params[128]; // informacoes de cada parametro
    } proc;
};

struct symbols_symbol {
    const char *name;
    enum symbols_types type;
    int lexical_level;
    int offset;
    struct symbols_content content;
};

struct symbols_table {
    struct symbols_symbol symbols[256];
    int top;
};

struct symbols_symbol symbols_table_create_symbol(
    const char *name,
    enum symbols_types type,
    int lexical_level,
    struct symbols_content content,
    int offset);

struct symbols_table *symbols_table_init();

void symbols_table_add(struct symbols_table *table, struct symbols_symbol sym);

struct symbols_symbol symbols_table_remove(struct symbols_table *table);

struct symbols_symbol *symbols_table_lookup(struct symbols_table *table,
                                            const char *name);

void symbols_table_pop_n(struct symbols_table *table, int n);

void symbols_table_add_type(struct symbols_table *table,
                            enum symbols_variables var_type,
                            int amount);

void symbols_table_print(struct symbols_table *table);

void symbols_table_remove_until(struct symbols_table *table, const char *name);

void symbols_table_set_offset(struct symbols_table *table, int n_params);

#endif /* !SYMBOLS_TABLE_H */
