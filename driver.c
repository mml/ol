#include <stdio.h>
#include "runtime.h"

int main(int argc, char **argv) {
    int val = ol_entry();

    if (FIXNUM_TAG == (val & FIXNUM_MASK))
        printf("%d\n", val >> FIXNUM_SHIFT);
    else if (BOOL_TAG == (val & BOOL_MASK))
        printf("%s\n", val >> BOOL_SHIFT ? "true" : "false");
    else if (NIL_REP == val)
        printf("nil\n");
    else {
        printf("Unrecognized value 0x%04x\n", val);
        return 1;
    }
    return 0;
}
