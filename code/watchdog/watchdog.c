/*
 * Watchdog timer for Ampro LB-P5x
 *
 * Compile with `gcc -O1 -o watchdog watchdog.c`
 * Run as root.
 */

#include <stdio.h>
#include <unistd.h>
#include <asm/io.h>

#define WDT_PORT 0x201

int main()
{
    // Get permissions for port. 
    if (ioperm(WDT_PORT, 1, 1)) 
    {
        perror("ioperm");
        exit(1);
    }
    while (1) {
        usleep(60000000); // 60 sec
        inb(WDT_PORT);
    }
    exit(0);
}
