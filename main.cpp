#include "softprintf.h"
#include <stdio.h>

int main(void) {

    int a = 52;

    

    printf ("a=%% b=%p c=%d\n", &a, 1488);
    SoftPrintfTrampoline("a=%% b=%p c=%f\n", &a, -1.488);
    return 0;
}