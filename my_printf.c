#include <stdio.h>

extern int MyPrintf(const char* str, ...);

int main()
{
    printf("\n\n");
    MyPrintf("Test\n %s - %s\n Это число во всех СС - %d \n "
             "(16) - %x \n (8) - %o \n (10) - %d \n (2) - %b \n Po procolu %c%%\n"
            ,"penis", "abobus", -12, -12, 12133, 12133, -12133, '#');

    int count = MyPrintf("Hello %c!\nHex: %x\nDec:%k%k %d\nOct: %o\nBin: %b\nStr: %s\n%d %s %x %d%c%b\n\n",
       '!', 0xDEADBEEF, -123, 777, 255, "Ura Ura Ura!", -1, "love", 3802, 100, 'i', 126);


    MyPrintf("HELLO %d %d %d %d %d %d %d %d %d %d", 1, 2, 3, 4, 5, 6, 7, 8, -9, -10);

        count = MyPrintf("\nHello\n");

       printf("\n%d\n", count);

        count = printf("\nHello\n");

       printf("\n%d\n", count);

    return 0;
}