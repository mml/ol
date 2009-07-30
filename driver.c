#include <stdio.h>
#include <stdlib.h>
#include <err.h>
#include "runtime.h"

void print_scheme_value(int);

struct scheme_array {
    int alloc;
    int count;
    int *things;
};

int main(int argc, char **argv) {
    void *mem = malloc(10240);
    if (NULL == mem) err(1, "malloc");
    int val = ol_entry(mem);

    print_scheme_value(val);

    return 0;
}

void print_scheme_value(int val) {
    int i;
    struct scheme_array *a;

    if (FIXNUM_TAG == (val & FIXNUM_MASK))
        printf("%d\n", val >> FIXNUM_SHIFT);
    else if (BOOL_TAG == (val & BOOL_MASK))
        printf("%s\n", val >> BOOL_SHIFT ? "true" : "false");
    else if (NIL_REP == val)
        printf("nil\n");
    else if (ARRAY_TAG == (val & ARRAY_MASK)) {
        a = (struct scheme_array *) (val^ARRAY_MASK);
        printf("[");
        for (i = 0; i < a->count; i++)
            print_scheme_value(a->things[i]);
        printf("]");
    } else {
        printf("Unrecognized value 0x%04x\n", val);
        exit(1);
    }
}
