/****************************************************************************/
/* Test for SLPEscape                                                       */
/* Creation Date: Fri Jun  2 09:23:41 EDT 2000                              */
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
		printf("SLPEscape\n  This program tests the parsing of a service url.\n Usage:\n   SLPEscape <string>\n");
		return(1);
	} /* End If. */

	err = SLPEscape(argv[1], &output_string, SLP_TRUE); 
	check_error_state(err, "Error parsing Service Tag");

	printf("Input Tag = %s\n", argv[1]);
	printf("Escaped Tag = %s\n", output_string);

	return(0);
}
