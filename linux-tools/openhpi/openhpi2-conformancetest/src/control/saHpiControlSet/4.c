/*      -*- linux-c -*-
 *
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005 by Intel Corp.
 * Copyright (c) 2005, University of New Hampshire
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  This
 * file and program are licensed under a BSD style license.  See
 * the Copying file included with the OpenHPI distribution for
 * full licensing terms.
 *
 * Author(s):
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Ye Bo <bo.ye@intel.com>
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01                                  
 * Function:    saHpiControlSet
 * Description: 
 *      Get control information, then set it back without modification.
 *      Expected return: SA_OK.
 * Line:        P96-18:P96-18
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * If we can read the Control data and set it, then simply go ahead
 * and read it and then write it back as is.
 *
 * NOTE: The original code only did this test for a Text Control.
 *       Since I saw no reason for this, I am testing all control types.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlModeT ctrlMode;
	SaHpiCtrlStateT ctrlState;

	if (!ctrlRec->WriteOnly) {

		// For a text control, we must specify the line of text

		if (isTextControl(ctrlRec)) {
			ctrlState.StateUnion.Text.Line = 1;
		}

		status = saHpiControlGet(sessionId, resourceId, ctrlNum,
					 &ctrlMode, &ctrlState);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiControlGet, SA_OK, status);
		} else {

			status = saHpiControlSet(sessionId, resourceId, ctrlNum,
						 ctrlMode, &ctrlState);
			if (status == SA_OK) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				e_print(saHpiControlSet, SA_OK, status);
			}
		}
	}

	return retval;
}

/*************************************************************************
 *
 *  Process all Control RDRs.  The below macro expands to
 *  generate all of the generic code necessary to call the given
 *  function to process an RDR.
 *
 *************************************************************************/

processAllControlRdrs(processCtrlRdr)
