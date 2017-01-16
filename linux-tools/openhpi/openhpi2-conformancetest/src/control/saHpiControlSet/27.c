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
 *      Use SAHPI_TLN_ALL_LINES and a DataLength of zero to
 *      clear the entire control.
 *      Expected return: SA_OK.
 * Line:        P97-22:P97-24
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * Verify that the text buffers contain the expected data.  With this
 * test, every text buffer must be empty.
 *
 *************************************************************************/

SaErrorT verifyTextBuffers(SaHpiSessionIdT sessionId,
			   SaHpiResourceIdT resourceId,
			   SaHpiCtrlRecT * ctrlRec, SaHpiBoolT * success)
{
	SaErrorT status;
	int lineNum;
	int maxLines = ctrlRec->TypeUnion.Text.MaxLines;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlStateT ctrlState;
	int maxBytes = getMaxBytes(ctrlRec);

	*success = SAHPI_TRUE;

	// Verify that all of the other lines are empty.

	for (lineNum = 1; lineNum <= maxLines && *success; lineNum++) {
		ctrlState.StateUnion.Text.Line = lineNum;
		status =
		    saHpiControlGet(sessionId, resourceId, ctrlNum, NULL,
				    &ctrlState);
		if (status != SA_OK) {
			e_print(saHpiControlGet, SA_OK, status);
			break;
		} else if (ctrlState.StateUnion.Text.Text.DataLength == maxBytes && 
				   isBlanks(&(ctrlState.StateUnion.Text.Text), 0, maxBytes)) {
			// okay; do nothing
		} else if (ctrlState.StateUnion.Text.Text.DataLength == 0) {
			// okay; do nothing
		} else {
			m_print("Text line %d is not blank!", lineNum);
			*success = SAHPI_FALSE;
		}
	}

	return status;
}

/*************************************************************************
 *
 * Test the clearing all of the text buffers using TLN_ALL_LINES.  
 * After filling up all of the text buffers, we will clear all of them
 * and then verify that the change did occur.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	ControlData controlData;
	SaHpiBoolT success;

	if (!ctrlRec->WriteOnly && isTextControl(ctrlRec)
	    && canSetControlState(ctrlRec)) {

		// Read the mode and all of the text buffers for later restoration.

		status =
		    readControlData(sessionId, resourceId, ctrlRec,
				    &controlData);
		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {

			// Fill up the text buffers so that we know we really have something.

			status =
			    setControlAllTextBuffers(sessionId, resourceId,
						     ctrlRec, BYTE_VALUE_1);
			if (status != SA_OK) {
				e_trace();
				retval = SAF_TEST_UNRESOLVED;
			} else {

				// Clear all of the text buffers.

				status =
				    setControlTextBuffer(sessionId, resourceId,
							 ctrlRec,
							 SAHPI_TLN_ALL_LINES, 0,
							 0);
				if (status != SA_OK) {
					e_trace();
					retval = SAF_TEST_FAIL;
				} else {

					// Verify that the text buffers contain what we expect.

					status =
					    verifyTextBuffers(sessionId,
							      resourceId,
							      ctrlRec,
							      &success);
					if (status != SA_OK) {
						retval = SAF_TEST_UNRESOLVED;
					} else if (success) {
						retval = SAF_TEST_PASS;
					} else {
						retval = SAF_TEST_FAIL;
					}
				}

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
