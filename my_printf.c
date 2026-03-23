#include <stdio.h>

extern void MyPrintf(const char* str, ...);

int main()
{
    printf("MY   bin is: %x\n", 2342424324);
    MyPrintf("Your bin is: %x%%%\n", 2342424324);

    return 0;
}