#include <stdio.h>

extern void MyPrintf(const char* str, ...);

int main()
{
    printf("Input %d\n\n", 123123);
    MyPrintf("%d %d %d %d %d %d %d\n", 1, 2, 3, 4, 5123, 6123, 7213);

    return 0;
}