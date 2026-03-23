#include <stdio.h>

extern void MyPrintf(const char* str, ...);

int main()
{
    printf("MY   bin is: %b\n", 2342424324);
    MyPrintf("Your bin is: %b\n", 2342424324);

    return 0;
}