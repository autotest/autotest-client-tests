/****************************************************************************/
/* Test for SLPFindSrvs                                                     */
/* Creation Date: Wed May 24 14:26:50 EDT 2000                              */
/****************************************************************************/
#include <slp.h>
//#include <slp_debug.h>
#include "slp_debug.h"
#include <stdio.h>

SLPBoolean
MySLPSrvURLCallback (SLPHandle hslp,
		     const char *srvurl,
		     unsigned short lifetime, SLPError errcode, void *cookie)
{
	switch(errcode) {
		case SLP_OK:
			printf ("Service URL     = %s\n", srvurl);
			printf ("Service Timeout = %i\n", lifetime);
			*(SLPError *) cookie = SLP_OK;
			break;
		case SLP_LAST_CALL:
			break;
		default:
			*(SLPError *) cookie = errcode;
			break;
	} /* End switch. */

	return SLP_TRUE;
}

int
main (int argc, char *argv[])
{
	SLPError err;
	SLPError callbackerr;
	SLPHandle hslp;

	if (argc != 2)
	{
		printf("SLPFindSrvs\n  Finds a SLP service.\n Usage:\n   SLPFindSrvs\n     <service type>\n");
		return (0);
	} /* End If. */

	err = SLPOpen ("en", SLP_FALSE, &hslp);
	check_error_state(err,"Error opening slp handle.");

	err = SLPFindSrvs (
			hslp, 
			argv[1],
			0,		/* use configured scopes */
			0,		/* no attr filter        */
			MySLPSrvURLCallback,
			&callbackerr);
	check_error_state(err, "Error registering service with slp.");

	/* Now that we're done using slp, close the slp handle */
	SLPClose (hslp);

	return(0);
}
