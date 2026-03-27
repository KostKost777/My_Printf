#include <stdio.h>
#include <math.h>

extern int MyPrintf(const char* str, ...);

int main()
{
    MyPrintf("%b  %o  %x\n", 211, 21313123, 213132);

    MyPrintf("%f %f %d %d %d %d %d %d %d \n", NAN, INFINITY , 1, 1, 1, 1, 1, 1, 1);

     MyPrintf("Test\n %s - %s\n Это число во всех СС - %f \n "
              "(16) - %x \n (10) - %d \n (10) - %d \n (10) - %d \n Po procolu %c%%\n%f\n%s  %f\n\n"
              "%d %s %x %d%c%b\n"
             ,"pencil", "abobus", 3.12, 1, 2, 3, -1, '#', 2.434, "aaa", 12.2434,
              -1, "love", 3802, 100, 33, 126);

    MyPrintf("%d %s %x %d%c%b\n", -1, "love", 3802, 100, 33, 126);

     MyPrintf("HELLO %d %d %d %d %d %d %d %d %d %d", 1, 2, 3, 4, 5, 6, 7, 8, -9, -10);

     int count = MyPrintf("\nHello\n");

     printf("\n%d\n", count);

     count = printf("\nHello\n");

     printf("\n%d\n", count);

     MyPrintf("\n%f, %f, %f, %f\n", 1.2 , 1.2, 1.2, 1.2);
     MyPrintf("\n%f\n", 213.214);

    return 0;
}