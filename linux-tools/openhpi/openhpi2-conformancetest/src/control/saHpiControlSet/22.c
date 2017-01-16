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
 *      Set the mode to SAHPI_CTRL_MODE_AUTO and use an invalid CtrlState. 
 *      The state input should be ignored.
 *      Expected return: SA_OK.
 * Line:        P97-6:P97-7
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * Test setting the mode to AUTO with an invalid CtrlState.  This is
 * supposed to be okay since the implementation is required to ignore
 * the CtrlState.
 *
 *************************************************************************/

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlStateT ctrlState;

	setDefaultCtrlState(ctrlRec, &ctrlState);
	ctrlState.Type = BAD_CTRL_TYPE;
	status = saHpiControlSet(sessionId, resourceId, ctrlNum,
				 SAHPI_CTRL_MODE_AUTO, &ctrlState);

	if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiControlSet, SA_OK, status);
	}

	return retval;
}

/*************************************************************************
 *
 * Test whether or not the CtrlState is properly ignored when the mode
 * is set to AUTO.  To understand the below code, consider the following
 * conditions.
 *
 * 1) If the mode is by default in AUTO mode and read-only, we can
 *    simply run the test since we won't be changing the mode or 
 *    changing state data.
 *
 * 2) If the mode is not read-only, then we don't know what the current
 *    mode is.  We must first read it.  If we are in AUTO mode, then
 *    it is essentially the same as case (1) above.  But if we are in
 *    MANUAL mode, we need to save the control state data so that we
 *    can restore it after the test.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiCtrlModeT ctrlMode;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	ControlData controlData;

	if (getDefaultMode(ctrlRec) == SAHPI_CTRL_MODE_AUTO
	    && isReadOnlyMode(ctrlRec)) {

		retval = run_test(sessionId, resourceId, ctrlRec);

	} else if (!isReadOnlyMode(ctrlRec) && !ctrlRec->WriteOnly) {

		status = saHpiControlGet(sessionId, resourceId, ctrlNum,
					 &ctrlMode, NULL);
		if (ctrlMode == SAHPI_CTRL_MODE_AUTO) {
			retval = run_test(sessionId, resourceId, ctrlRec);
		} else {
			status =
			    readControlData(sessionId, resourceId, ctrlRec,
					    &controlData);
			if (status != SA_OK) {
				e_trace();
				retval = SAF_TEST_UNRESOLVED;
			} else {
				retval =
				    run_test(sessionId, resourceId, ctrlRec);
				restoreControlData(sessionId, resourceId,
						   ctrlNum, &controlData);
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
