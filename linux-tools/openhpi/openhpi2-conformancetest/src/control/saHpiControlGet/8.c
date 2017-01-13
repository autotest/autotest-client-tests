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
 *        Carl McAdams <carlmc@us.ibm.com>
 *      Ye Bo <bo.ye@intel.com>
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01                                  
 * Function:    saHpiControlGet()
 * Description: 
 *      For Text controls, change the first line of text and
 *      then verify that the change did occur.
 * Line:        P94-33:P94-36
 */

#include <stdio.h>
#include "../include/control_test.h"

#define MAX_BYTES 10
#define MIN(x, y) ((x) < (y) ? (x) : (y))

/*************************************************************************
 *
 * Initialize the line of text for the Text control we are changing.
 *
 * We must be careful.  We don't want to put more characters in the
 * line than the line can hold.  Also, be aware that MaxChars for a line
 * is the number of characters, not the number of bytes.  For UNICODE,
 * it takes two bytes per character.  So, determine a number of bytes
 * that we can write to the line and then put some data into the buffer.
 *
 *************************************************************************/

void initTextData(SaHpiCtrlRecT * ctrlRec, SaHpiCtrlStateT * ctrlState)
{
	int index, numBytes;

	numBytes = MIN(getMaxBytes(ctrlRec), MAX_BYTES);

	setDefaultCtrlState(ctrlRec, ctrlState);
	ctrlState->StateUnion.Text.Line = 1;
	ctrlState->StateUnion.Text.Text.DataLength = numBytes;
	for (index = 0; index < numBytes; index++) {
		ctrlState->StateUnion.Text.Text.Data[index] = BYTE_VALUE_1;
	}
}

/*************************************************************************
 *
 * Compare the text lines of two states to verify if they are the
 * same or not.
 *
 *************************************************************************/

SaHpiBoolT isSameTextData(SaHpiCtrlStateT * state, SaHpiCtrlStateT * curState)
{
	int index;
	SaHpiBoolT same = SAHPI_TRUE;
	SaHpiTextBufferT *buf = &(state->StateUnion.Text.Text);
	SaHpiTextBufferT *curBuf = &(curState->StateUnion.Text.Text);

	if (curBuf->DataLength < buf->DataLength) {
		same = SAHPI_FALSE;
	} else {
		for (index = 0; index < buf->DataLength; index++) {
			if (buf->Data[index] != curBuf->Data[index]) {
				same = SAHPI_FALSE;
				break;
			}
		}

		if (same
		    && !isBlanks(curBuf, buf->DataLength, curBuf->DataLength)) {
			same = SAHPI_FALSE;
		}
	}

	return same;
}

/*************************************************************************
 *
 * If this is a Text control that we can set, then change the text for
 * the first line and then read the state to verify that the change of
 * the text line occured.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlModeT oldCtrlMode;
	SaHpiCtrlStateT oldCtrlState;
	SaHpiCtrlStateT newCtrlState;
	SaHpiCtrlModeT ctrlMode;
	SaHpiCtrlStateT ctrlState;

	if (!ctrlRec->WriteOnly && isTextControl(ctrlRec)
	    && canSetControlState(ctrlRec)) {

		// Save the original Control State.

		oldCtrlState.StateUnion.Text.Line = 1;
		status = saHpiControlGet(sessionId, resourceId, ctrlNum,
					 &oldCtrlMode, &oldCtrlState);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiControlGet, SA_OK, status);
		} else {

			// Change the first line of text.

			initTextData(ctrlRec, &newCtrlState);
			status = saHpiControlSet(sessionId, resourceId, ctrlNum,
						 SAHPI_CTRL_MODE_MANUAL,
						 &newCtrlState);
			if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiControlSet, SA_OK, status);
			} else {

				// Read back the first line of text and make sure it is
				// the same as what we set it to.

				ctrlState.StateUnion.Text.Line = 1;
				status =
				    saHpiControlGet(sessionId, resourceId,
						    ctrlNum, &ctrlMode,
						    &ctrlState);
				if (status != SA_OK) {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiControlGet, SA_OK, status);
				} else
				    if (isSameTextData
					(&newCtrlState, &ctrlState)) {
					retval = SAF_TEST_PASS;
				} else {
					retval = SAF_TEST_FAIL;
					m_print("Text data is not equivalent!");
				}

				// Restore Control state.

				setControl(sessionId, resourceId, ctrlNum,
					   oldCtrlMode, &oldCtrlState);
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
