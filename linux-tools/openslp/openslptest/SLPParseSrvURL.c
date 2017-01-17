/****************************************************************************/
/* Test for SLPOpen                                                         */
/* Creation Date: Wed May 24 14:26:50 EDT 2000                              */
/****************************************************************************/
#include <stdio.h>
#include <slp.h>
//#include <slp_debug.h>
#include "slp_debug.h"
#include <string.h>

int
main (int argc, char *argv[])
{
	SLPError	err;
	SLPSrvURL	*parsedurl;

	if (argc != 2)
	{
		printf("SLPParseSrvURL\n  This program tests the parsing of a service url.\n Usage:\n   SLPParseSrvURL <serivce url>\n");
		return(1);
	} /* End If. */

	err = SLPParseSrvURL(argv[1], &parsedurl); 
	check_error_state(err, "Error parsing SrvURL");

	printf("Service Type = %s\n", parsedurl->s_pcSrvType);
	printf("Host Identification = %s\n", parsedurl->s_pcHost);
	printf("Port Number = %d\n", parsedurl->s_iPort);
	printf("Family = %s\n", ((strlen(parsedurl->s_pcNetFamily)==0)?"IP":"Other"));
	printf("URL Remainder = %s\n", parsedurl->s_pcSrvPart);

	return(0);
}
