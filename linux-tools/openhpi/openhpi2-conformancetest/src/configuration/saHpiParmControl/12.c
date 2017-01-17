/*
 * Copyright (c) 2005, University of New Hampshire
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307 USA.
 *
 * Author(s):
 *      Lauren DeMarco <lkdm@cisunix.unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiParmControl
 * Description:
 *   Call saHpiParmControl with Action=SAHPI_RESTORE_PARM. Use 
 *      saHpiAutoExtractTimeoutGet() to get the auto-extract timeout value.
 *      Use saHpiAutoExtractTimeoutSet() to change the value.
 *      Call saHpiParmControl with Action=SAHPI_RESTORE_PARM. Get
 *      the new values of the auto-extract timeout value. Compare
 *      the old value and the new value to make sure that 
 *      saHpiParmControl with Action=SAHPI_RESTORE_PARM works.
 *   Expected return:  call returns SA_OK
 *
 * Line:        P153-19:P153-21
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session, SaHpiRptEntryT rpt_entry,
		  callback2_t func)
{
	SaHpiResourceIdT resourceid = rpt_entry.ResourceId;
	SaErrorT status;
	int ret = SAF_TEST_UNKNOWN;

	SaHpiTimeoutT originalTimeout;
	SaHpiTimeoutT newTimeout;

	// -------- Check to see if parameter control is supported ---------

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_CONFIGURATION) {

		// --------------- Restore the saved values ---------------- 

		status =
		    saHpiParmControl(session, resourceid, SAHPI_RESTORE_PARM);

		if (status != SA_OK)	// The function works abnormally
		{
			e_print(saHpiParmControl, SA_OK, status);
			ret = SAF_TEST_FAIL;
			return ret;
		}
		// ------------- Check to see if hotswap is supported -------------

		if (rpt_entry.
		    ResourceCapabilities & SAHPI_CAPABILITY_MANAGED_HOTSWAP) {

			// ----------- Get the AutoExtract timeout value ----------

			status =
			    saHpiAutoExtractTimeoutGet(session, resourceid,
						       &originalTimeout);

			if (status != SA_OK)	// The function works abnormally
			{
				e_print(saHpiAutoExtractTimeoutGet,
					SA_OK, status);
				ret = SAF_TEST_UNRESOLVED;
				return ret;
			}
			// ----------- Set the AutoExtract timeout value ------------

			if (originalTimeout != 60)
				status =
				    saHpiAutoExtractTimeoutSet(session,
							       resourceid, 60);
			else
				status =
				    saHpiAutoExtractTimeoutSet(session,
							       resourceid, 65);

			if (status != SA_OK)	// The function works abnormally
			{
				e_print(saHpiAutoExtractTimeoutSet,
					SA_OK, status);
				ret = SAF_TEST_UNRESOLVED;
				return ret;
			}
			// ------ Call saHpiParmControl to restore the parameters ------

			status =
			    saHpiParmControl(session, resourceid,
					     SAHPI_RESTORE_PARM);

			if (status != SA_OK)	// The function works abnormally
			{
				e_print(saHpiParmControl, SA_OK, status);
				ret = SAF_TEST_FAIL;
				return ret;
			}
			// ------------ Get the AutoExtract timeout value -----------

			status =
			    saHpiAutoExtractTimeoutGet(session, resourceid,
						       &newTimeout);

			if (status != SA_OK)	// The function works abnormally
			{
				e_print(saHpiAutoExtractTimeoutGet,
					SA_OK, status);
				ret = SAF_TEST_UNRESOLVED;
				return ret;
			}
			// ------- Compare the old value to the new value -------

			if (newTimeout != originalTimeout) {
				printf
				    ("* * * ERROR: newTimeout value does not equal originalTimeout value * * *\n");
				ret = SAF_TEST_FAIL;
				return ret;
			} else
				ret = SAF_TEST_PASS;
		} else {
			// Not a hot swap supported resource
			ret = SAF_TEST_NOTSUPPORT;
			printf("\n\n* * * Hot swap not supported * * *\n\n");
			return ret;
		}
	} else {
		// Resource Does not support parameter control
		ret = SAF_TEST_NOTSUPPORT;
		printf("\n\n* * * Configuration not supported * * *\n\n");
		return ret;
	}
	return ret;
}

/************************************************************************
 * Main Function
 *    takes no arguments
 *
 *    returns: SAF_TEST_PASS when successful
 *             SAF_TEST_FAIL when an unexpected error occurs
 ***********************************************************************/
int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(Test_Resource, NULL, NULL);

	return ret;
}
