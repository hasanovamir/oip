#include "softprintf.h"
#include <stdio.h>

int main(          void           ) {

    int a = 52;

    

    printf              ("a=%% b=%p c=%f d = %f\n", &a, -1.488, 52.999);
    SoftPrintfTrampoline("a=%% b=%p c=%f d = %f\n", &a, -1.488, 52.999);
    SoftPrintfTrampoline("a=%% b=%p c=%f d = %f %f %f %f %f %f %d %d %d %d %d %f %f %f %f\n", &a, -1.488, 52.999,
                                                         52.999, 52.999,
                                                         52.999, 52.999,
                                                         52.999, 123123,
                                                         123123, 123,
                                                         123,12312,
                                                         52.999, 52.999,
                                                         52.999, 14.88);
    SoftPrintfTrampoline("%ÿ");
    // printf("%ÿ");
    return 0;
}