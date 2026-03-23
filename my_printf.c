#include <stdio.h>

extern void MyPrintf(const char* str, ...);

int main()
{

    printf("Input %o\n\n", 3225325);
    MyPrintf("You %s is %o \n", "number", 3225325);

    return 0;
}