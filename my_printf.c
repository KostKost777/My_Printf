#include <stdio.h>

extern void MyPrintf(const char* str, ...);

int main()
{

    printf("Input %x\n\n", 537804);
    MyPrintf("You %s is %x \n", "number", 537804);

    return 0;
}