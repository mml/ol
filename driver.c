#include <stdio.h>
#include <stdlib.h>
#include <err.h>
#include "lib/runtime.h"

void print_ol_value(int);

struct ol_array {
    int alloc;
    int count;
    int things[];
};

int main(int argc, char **argv) {
    void *mem = malloc(10240);
    if (NULL == mem) err(1, "malloc");
    int val = ol_entry(mem);

    print_ol_value(val);

    printf("\n");

    return 0;
}

void print_ol_value(int val) {
    int i;
    struct ol_array *a;

    if (FIXNUM_TAG == (val & FIXNUM_MASK))
        printf("%d", val >> FIXNUM_SHIFT);
    else if (BOOL_TAG == (val & BOOL_MASK))
        printf("%s", val >> BOOL_SHIFT ? "true" : "false");
    else if (NIL_REP == val)
        printf("nil");
    else if (ARRAY_TAG == (val & ARRAY_MASK)) {
        a = (struct ol_array *) (val^ARRAY_TAG);
        printf("[");

        // Spelling out join(",", ...)
        if (a->count >= 1)
            print_ol_value(a->things[0]);
        for (i = 1; i < a->count; i++) {
            printf(",");
            print_ol_value(a->things[i]);
        }
        printf("]");
    } else {
        printf("Unrecognized value 0x%04x\n", val);
        exit(1);
    }
}
