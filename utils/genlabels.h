#ifndef GENLABELS_H
#define GENLABELS_H

struct genlabels_label {
    char label[16];
};

struct genlabels_table {
    struct genlabels_label labels[256];
    int n_labels;
    int top;
};

struct genlabels_table *genlabels_table_init();

struct genlabels_label genlabels_label_generate(
    struct genlabels_table *labels);

struct genlabels_label genlabels_label_get(struct genlabels_table *table);

void genlabels_table_pop_n(struct genlabels_table *table, int n);

void genlabels_print(struct genlabels_table *table);

#endif /* !GENLABELS_H */
