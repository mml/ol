#include <stdio.h>
#define FIXNUM_MASK  0x03
#define FIXNUM_TAG   0x00
#define FIXNUM_SHIFT 2
#define BOOL_MASK    0xFE
#define BOOL_TAG     0x3E
#define NIL_VALUE    0x2F

int main(int argc, char **argv) {
    int val = ol_entry();

    if (FIXNUM_TAG == (val & FIXNUM_MASK))
        printf("%d\n", val >> FIXNUM_SHIFT);
    else if (BOOL_TAG == (val & BOOL_MASK))
        printf("%s\n", val & 0x01 ? "true" : "false");
    else if (NIL_VALUE == val)
        printf("nil\n");
    else {
        printf("Unrecognized value 0x%04x\n", val);
        return 1;
    }
    return 0;
}
