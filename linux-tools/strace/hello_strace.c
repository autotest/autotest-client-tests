/* This is a test input file that prints a string. This will be used to test
 * the -e option for strace.
 */

#include <stdio.h>		/* for declaration of printf() */
#include <stdlib.h>		/* for declaration of exit() */

int
main()
{
    printf("OS Rocks\n");
    exit(0);
}
