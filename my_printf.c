#include <stdio.h>
#include <math.h>

extern int MyPrintf(const char* str, ...);

int main()
{

    MyPrintf("%f %f %d %d %d %d %d %d %d \n", 1.2, 1.2, 1, 1, 1, 1, 1, 1, 1);

     MyPrintf("Test\n %s - %s\n Это число во всех СС - %f \n "
              "(16) - %x \n (10) - %d \n (10) - %d \n (10) - %d \n Po procolu %c%%\n%f\n%s  %f\n"
             ,"penis", "abobus", 3.12, 1, 2, 3, -1, '#', 2.434, "hui", 12.2434);

     int count = MyPrintf("Hello %c!\nHex: %x\nDec:%k%k %d\nOct: %o\nBin: %b\nStr: %s\n%d %s %x %d%c%b\n\n",
        '!', 0xDEADBEEF, -123, 777, 255, "Ura Ura Ura!", -1, "love", 3802, 100, 'i', 126);


     MyPrintf("HELLO %d %d %d %d %d %d %d %d %d %d", 1, 2, 3, 4, 5, 6, 7, 8, -9, -10);

     count = MyPrintf("\nHello\n");

     printf("\n%d\n", count);

     count = printf("\nHello\n");

     printf("\n%d\n", count);

     MyPrintf("\n%f, %f, %f, %f\n", 1.2 , 1.2, 1.2, 1.2);
     MyPrintf("\n%f\n", 213.214);

    return 0;
}