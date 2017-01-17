/****************************************************************************/
/* Test for SLPFindSrvTypes                                                 */
/* Creation Date: Sun Aug 20 21:06:18 IST 2000                              */
/****************************************************************************/
#include <slp.h>
//#include <slp_debug.h>
#include "slp_debug.h"
#include <stdio.h>

SLPBoolean
MySLPSrvTypeCallback (SLPHandle hslp,
		      const char *pcSrvTypes,
		      SLPError errcode, void *cookie)
{
    switch(errcode) {
    case SLP_OK:
        printf ("Service Types     = %s\n", pcSrvTypes);
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
		printf("SLPFindSrvTypes\n  Finds a SLP service.\n Usage:\n   SLPFindSrvTypes\n     <naming authority>\n");
        return (0);
    } /* End If. */

    err = SLPOpen ("en", SLP_FALSE, &hslp);
    check_error_state(err,"Error opening slp handle.");

    err = SLPFindSrvTypes (
                           hslp, 
			   argv[1], /* naming authority */
                           0,       /* use configured scopes */
                           MySLPSrvTypeCallback,
                           &callbackerr);
    check_error_state(err, "Error getting service type with slp.");

        /* Now that we're done using slp, close the slp handle */
    SLPClose (hslp);

    return(0);
}
