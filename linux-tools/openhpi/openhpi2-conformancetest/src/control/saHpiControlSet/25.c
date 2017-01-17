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
 *      For a Text control, write a zero-length string which
 *      should clear the line.
 *      Expected return: SA_OK.
 * Line:        P97-13:P97-13
 */

#include <stdio.h>
#include "../include/control_test.h"

#define NUM_BYTES 4

/*************************************************************************
 *
 * Test that a Text Control will clear the entire line.  If we a have 
 * Text Control that we can change, first set a string to make sure there
 * is some data.  Then set an empty string which will clear the line.  
 * Verify that it has been cleared by reading the text buffer.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlStateT ctrlState;
	SaHpiCtrlModeT origCtrlMode;
	SaHpiCtrlStateT origCtrlState;
	int maxBytes = getMaxBytes(ctrlRec);

	if (!ctrlRec->WriteOnly && isTextControl(ctrlRec)
	    && canSetControlState(ctrlRec) && maxBytes >= NUM_BYTES) {

		// Save the original mode and state data so that it can be restored.

		origCtrlState.StateUnion.Text.Line = 1;
		status = saHpiControlGet(sessionId, resourceId, ctrlNum,
					 &origCtrlMode, &origCtrlState);

		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiControlGet, SA_OK, status);
		} else {

			// Write the initial string to make sure we have something here.

			status =
			    setControlTextBuffer(sessionId, resourceId, ctrlRec,
						 1, NUM_BYTES, BYTE_VALUE_1);
			if (status != SA_OK) {
				e_trace();
				retval = SAF_TEST_UNRESOLVED;
			} else {

				// Write a zero-length empty string.

				status =
				    setControlTextBuffer(sessionId, resourceId,
							 ctrlRec, 1, 0, 0);
				if (status != SA_OK) {
					e_trace();
					retval = SAF_TEST_UNRESOLVED;
				} else {

					// Retrieve the latest text buffer and verify that it
					// corresponds to the empty string.

					ctrlState.StateUnion.Text.Line = 1;
					status =
					    saHpiControlGet(sessionId,
							    resourceId, ctrlNum,
							    NULL, &ctrlState);
					if (status != SA_OK) {
						retval = SAF_TEST_UNRESOLVED;
						m_print
						    ("Call to saHpiControlGet did not return SA_OK!");
						e_print(saHpiControlGet, SA_OK,
							status);
					} else if (ctrlState.StateUnion.Text.
						   Text.DataLength == 0) {
						retval = SAF_TEST_PASS;
					} else if (ctrlState.StateUnion.Text.
						   Text.DataLength == maxBytes
						   &&
						   isBlanks(&
							    (ctrlState.
							     StateUnion.Text.
							     Text), 0,
							    maxBytes)) {
						retval = SAF_TEST_PASS;
					} else {
						retval = SAF_TEST_FAIL;
						m_print
						    ("Data does not contain blanks!");
					}
				}

				// Restore the original mode and state data.

				setControl(sessionId, resourceId, ctrlNum,
					   origCtrlMode, &origCtrlState);
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
