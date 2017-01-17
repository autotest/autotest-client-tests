/****************************************************************************/
/* Test for SLPOpen                                                         */
/* Creation Date: Wed May 24 14:26:50 EDT 2000                              */
/****************************************************************************/
#include <stdio.h>
#include <slp.h>
//#include <slp_debug.h>
#include "slp_debug.h"

int
main (int argc, char *argv[])
{
	SLPError err;
	SLPHandle hslp;
	
	err = SLPOpen ("en", SLP_FALSE, &hslp);
	check_error_state(err,"Error opening slp handle");

	/* Now that we're done using slp, close the slp handle */
	SLPClose (hslp);
	
	return(0);
}
