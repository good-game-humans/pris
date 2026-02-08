/*
 * Pets the Watchdog one time.  (For Ampro LB-P5x.)
 *
 * Compile with `gcc -O1 -o watchdog-1x watchdog-1x.c`
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
    inb(WDT_PORT);
    exit(0);
}
