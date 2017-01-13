/****************************************************************************/
/* Test for SLPReg                                                          */
/* Creation Date: Wed May 24 14:26:50 EDT 2000                              */
/****************************************************************************/
#include <slp.h>
//#include <slp_debug.h>
#include "slp_debug.h"
#include <unistd.h>
#include <string.h>

void MySLPRegReport(SLPHandle hslp, SLPError errcode, void* cookie) 
{ 
	/* return the error code in the cookie */ 
	*(SLPError*)cookie = errcode; 

} 

SLPBoolean
MySLPSrvURLCallback (SLPHandle hslp,
		     const char *srvurl,
		     unsigned short lifetime, SLPError errcode, void *cookie)
{
	switch(errcode) {
		case SLP_OK:
			printf ("Service Found   = %s\n", srvurl);
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

int main(int argc, char* argv[]) 
{ 
	SLPError	err; 
	SLPError	callbackerr; 
	SLPHandle	hslp; 
	char		reg_string[4096];

	if ((argc < 2) || (argc > 4))
	{
		printf("SLPReg\n  This test the SLP registration.\n Usage:\n   SLPReg <service name to create> <service host address> <service to search>\n");
		return(0);
	}
	err = SLPOpen("en",SLP_FALSE,&hslp);
	check_error_state(err, "Error opening slp handle");
	sprintf(reg_string,"%s://%s",argv[1], argv[2]);

	/* Register a service with SLP */ 
	printf("Registering     = %s\n",reg_string);
	err = SLPReg( hslp, 
		reg_string,
		SLP_LIFETIME_MAXIMUM, 
		0, 
		"(public-key=......my_pgp_key.......)", 
		SLP_TRUE, 
		MySLPRegReport, 
		&callbackerr ); 
	check_error_state(err, "Error registering service with slp.");
	check_error_state(callbackerr, "Error registering service with slp.");

	sleep(10);		/* give async call-back a chance to run and put out message. */

	printf("Querying        = %s\n",argv[3]);
	/* Now make sure that the service is there. */
	err = SLPFindSrvs (
			hslp, 
			argv[3],
			0,		/* use configured scopes */
			0,		/* no attr filter        */
			MySLPSrvURLCallback,
			&callbackerr);

 	/* err may contain an error code that occured as the slp library    */
	/* _prepared_ to make the call.                                     */
	check_error_state(err, "Error registering service with slp.");
	check_error_state(callbackerr, "Error registering service with slp.");
	
	/* Now that we're done using slp, close the slp handle */ 
	SLPClose(hslp); 

	return(0);
}
