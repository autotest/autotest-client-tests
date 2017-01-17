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
 *      For a Text control, write less than a full line of text.
 *      The remaining spaces will be cleared.
 *      Expected return: SA_OK.
 * Line:        P97-12:P97-13
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * Test that a Text Control will clear spaces beyond those written to
 * a line.  If we a have Text Control that we can change, first set a
 * "long" string.  Then set a "shorter" string.  After retrieving the 
 * text, it should correspond to the "shorter" string.   Test every
 * line in the text control.
 *
 * NOTE: Using 4 bytes for long string and 2 bytes for the short string.
 *       Must use an even number of bytes in case the DataType is UNICODE.
 *
 *************************************************************************/

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_PASS;
	int lineNum;
	int maxLines = ctrlRec->TypeUnion.Text.MaxLines;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	int maxBytes = getMaxBytes(ctrlRec);
	SaHpiCtrlStateT ctrlState;

	for (lineNum = 1; lineNum <= maxLines && retval == SAF_TEST_PASS;
	     lineNum++) {

		// Write the initial "long" string in the first line.

		status =
		    setControlTextBuffer(sessionId, resourceId, ctrlRec,
					 lineNum, 4, BYTE_VALUE_1);
		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {

			// Write a "shorter" string with a different character.

			status =
			    setControlTextBuffer(sessionId, resourceId, ctrlRec,
						 lineNum, 2, BYTE_VALUE_2);
			if (status != SA_OK) {
				e_trace();
				retval = SAF_TEST_UNRESOLVED;
			} else {

				// Retrieve the latest text buffer and verify that it
				// corresponds to the "shorter" string.

				ctrlState.StateUnion.Text.Line = lineNum;
				status =
				    saHpiControlGet(sessionId, resourceId,
						    ctrlNum, NULL, &ctrlState);
				if (status != SA_OK) {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiControlGet, SA_OK, status);
				} else
				    if (!matchesTextBuffer
					(&(ctrlState.StateUnion.Text.Text),
					 maxBytes, BYTE_VALUE_2, 2)) {
					retval = SAF_TEST_FAIL;
					m_print("Text Buffer does not match!");
				}
			}
		}
	}

	return retval;
}

/*************************************************************************
 *
 * Test that a Text Control will clear spaces beyond those written to
 * a line. 
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	int maxBytes;
	ControlData controlData;

	maxBytes = getMaxBytes(ctrlRec);
	if (!ctrlRec->WriteOnly && isTextControl(ctrlRec)
	    && canSetControlState(ctrlRec) && maxBytes >= 4) {

		// Save the original mode and state data so that it can be restored.

		status =
		    readControlData(sessionId, resourceId, ctrlRec,
				    &controlData);

		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiControlGet, SA_OK, status);
		} else {
			retval = run_test(sessionId, resourceId, ctrlRec);

			// Restore the original mode and state data.
			restoreControlData(sessionId, resourceId, ctrlNum,
					   &controlData);
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
