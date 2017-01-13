/****************************************************************************/
/* Test for SLPDereg                                                        */
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

	/* return SLP_TRUE because we want to be called again */
	/* if more services were found                        */
	return SLP_TRUE;
}

int main(int argc, char* argv[]) 
{ 
	/*
	 * This test works by:
	 *	1.  Register a service.
	 *	2.  Query the service to make sure it is there.
	 *	3.  Remove the service.
	 *	4.  Query the service to ensure it is not there.
	 */
	SLPError	err; 
	SLPError	callbackerr; 
	SLPHandle	hslp; 
	char		reg_string[4096];
	char		dereg_string[4096];

	if ((argc != 3) && (argc != 5))
	{
		printf("SLPDereg\n  This test the SLP de-registration.\n Usage:\n   SLPDereg\n     <service name to register>\n     <service address>\n     <service to deregister>\n     <service deregistration address>\n   SLPDereg\n     <service to deregister>\n");
		return (0);
	} /* End If. */

	err = SLPOpen("en",SLP_FALSE,&hslp);
	check_error_state(err, "Error opening slp handle.");

	/* Register a service with SLP */
	if (argc == 5)
	{ 
		sprintf(reg_string,"%s://%s",argv[1], argv[2]);
		printf("Registering     = %s\n",reg_string);
		err = SLPReg( hslp, 
			reg_string,
			SLP_LIFETIME_MAXIMUM, 
			"", 
			"", 
			SLP_TRUE, 
			MySLPRegReport, 
			&callbackerr ); 
		check_error_state(err, "Error registering service with slp");
		printf("Srv. Registered = %s\n",reg_string);
	} /* End If. */


	/* Now make sure that the service is there. */
	printf("Querying        = %s\n",(argc == 5)?argv[3]:argv[1]);
	err = SLPFindSrvs (
			hslp, 
			(argc==5)?argv[3]:argv[1],
			"",		/* use configured scopes */
			"",		/* no attr filter        */
			MySLPSrvURLCallback,
			&callbackerr);
	check_error_state(err, "Error registering service with slp.");

	sleep(10);		/* give async call-back a chance to run and put out message. */

	/* Deregister the service. */
	if (argc == 5)
		sprintf(dereg_string,"%s://%s",argv[3], argv[4]);
	else
		sprintf(dereg_string,"%s://%s",argv[1], argv[2]);

	printf("Deregistering   = %s\n",dereg_string);
	err = SLPDereg(
		hslp,
		dereg_string, 
		MySLPRegReport,
		&callbackerr);
	check_error_state(err, "Error deregistering service with slp.");
	printf("Deregistered    = %s\n",dereg_string);

	/* Now that we're done using slp, close the slp handle */ 
	SLPClose(hslp); 

	return(0);
}
