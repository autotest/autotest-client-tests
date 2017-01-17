/****************************************************************************/
/* Test for SLPUnescape                                                     */
/* Creation Date: Mon Jun  5 13:51:26 EDT 2000                              */
/****************************************************************************/
#include <stdio.h>
#include <slp.h>
//#include <slp_debug.h>
#include "slp_debug.h"

int
main (int argc, char *argv[])
{
	SLPError	err;
	char		*output_string;

	if (argc != 2)
	{
		printf("SLPUnescape\n  This program tests the un-parsing of a service url.\n Usage:\n   SLPEscape <string>\n");
		return(1);
	} /* End If. */

	err = SLPUnescape(argv[1], &output_string, SLP_TRUE); 
	check_error_state(err, "Error parsing Service Tag");

	printf("Input Tag = %s\n", argv[1]);
	printf("Output Tag = ");
	puts(output_string);

	return(0);
}
