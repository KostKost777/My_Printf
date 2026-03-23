#include <stdio.h>

extern void MyPrintf(const char* str, ...);

int main()
{
    printf("Mega Test\n %s - %s\n Это число во всех СС - %d \n (16) - %x \n (8) - %o \n (10) - %d \n (2) - %b \n Po procolu %c%%\n\n"
             , "penis", "abobus", 12133, 12133, 12133, 12133, 12133, '#');
    MyPrintf("Mega Test\n %s - %s\n Это число во всех СС - %d \n (16) - %x \n (8) - %o \n (10) - %d \n (2) - %b \n Po procolu %c%%\n\n"
             , "penis", "abobus", 12133, 12133, 12133, 12133, 12133, '#');

    return 0;
}