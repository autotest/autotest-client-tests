/* 
 * (C) Copyright University of New Hampshire 2005
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  This
 * file and program are licensed under a BSD style license.  See
 * the Copying file included with the OpenHPI distribution for
 * full licensing terms.
 *
 * Author(s):
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01                                  
 * Function:    saHpiControlSet
 * Description:
 *      For a Text control, write more text than will fit on one
 *      line and verify that the text wraps to the next line.
 *      Expected return: SA_OK.
 * Line:        P97-14:P97-15
 */

#include <stdio.h>
#include "../include/control_test.h"

#define MIN(x,y) ((x) < (y) ? (x) : (y))

/*************************************************************************
 *
 * Return the max data length for a text buffer that can be sent
 * to a Text control.  
 *
 * Note that UNICODE is a special case since it requires 2 bytes per
 * character.  Also, note that SAHPI_MAX_TEXT_BUFFER_LENGTH is 255.
 * Since the length of a UNICODE text string must be even, we must
 * must subtract one and use 254 bytes.
 *
 *************************************************************************/

int getMaxDataLength(SaHpiCtrlRecT * ctrlRec)
{
	int maxDataLength = SAHPI_MAX_TEXT_BUFFER_LENGTH;
	if (isUnicodeDataType(ctrlRec)) {
		maxDataLength--;
	}

	return maxDataLength;
}

/*************************************************************************
 *
 * To do this test, there must be at least two lines and we must be
 * able to write enough to a single line to cause the text to wrap
 * to the following line.
 *
 *************************************************************************/

SaHpiBoolT canWrap(SaHpiCtrlRecT * ctrlRec)
{
	return (ctrlRec->TypeUnion.Text.MaxLines >= 2) &&
	    (getMaxBytes(ctrlRec) <= getMaxDataLength(ctrlRec));
}

/*************************************************************************
 *
 * Read a text line and verify that it equals a set of bytes.
 *
 *************************************************************************/

int verifyLine(SaHpiSessionIdT sessionId,
	       SaHpiResourceIdT resourceId,
	       SaHpiCtrlRecT * ctrlRec,
	       SaHpiTxtLineNumT lineNum,
	       SaHpiUint8T length, SaHpiUint8T byteValue)
{
	SaErrorT status;
	int retval;
	SaHpiCtrlStateT ctrlState;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	int maxBytes = getMaxBytes(ctrlRec);

	ctrlState.StateUnion.Text.Line = lineNum;
	status =
	    saHpiControlGet(sessionId, resourceId, ctrlNum, NULL, &ctrlState);

	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		m_print("Call to saHpiControlGet did not return SA_OK!");
		e_print(saHpiControlGet, SA_OK, status);
	} else
	    if (!matchesTextBuffer
		(&(ctrlState.StateUnion.Text.Text), maxBytes, byteValue,
		 length)) {
		retval = SAF_TEST_FAIL;
		m_print("Text Buffers do not match!");
	} else {
		retval = SAF_TEST_PASS;
	}

	return retval;
}

/*************************************************************************
 *
 * For a Text control, try writing more text than can fit on one line
 * and verify that the text wraps to the next line.
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
	int numBytes;
	int numBytes_1;
	int numBytes_2;

	if (!ctrlRec->WriteOnly && isTextControl(ctrlRec)
	    && canSetControlState(ctrlRec) && canWrap(ctrlRec)) {

		// Save the original mode and state data so that it can be restored.

		status =
		    readControlData(sessionId, resourceId, ctrlRec,
				    &controlData);

		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {

			// Write a text string into the first line that will overflow into the second line,
			// but which will not fill up the second line.
			// We don't want to overflow into the third line since there might not be one.  
			// Therefore, we may have to limit how much we write.  Also, we might not be able
			// to put enough into one buffer to fill both lines.  So, we must compute how many
			// bytes are actually written to the first and second lines.

			int oneAndHalfLines = getMaxBytes(ctrlRec) * 1.5;
			if (oneAndHalfLines % 2 != 0) {
				oneAndHalfLines--;
			}

			numBytes =
			    MIN(oneAndHalfLines, getMaxDataLength(ctrlRec));
			numBytes_1 = getMaxBytes(ctrlRec);
			numBytes_2 = numBytes - numBytes_1;

			status =
			    setControlTextBuffer(sessionId, resourceId, ctrlRec,
						 1, numBytes, BYTE_VALUE_1);
			if (status != SA_OK) {
				e_trace();
				retval = SAF_TEST_UNRESOLVED;
			} else {

				// Verify that the first and second lines have the data that is expected.

				retval =
				    verifyLine(sessionId, resourceId, ctrlRec,
					       1, numBytes_1, BYTE_VALUE_1);
				if (retval == SAF_TEST_PASS) {
					retval =
					    verifyLine(sessionId, resourceId,
						       ctrlRec, 2, numBytes_2,
						       BYTE_VALUE_1);
				}
				// Restore the original mode and state data.

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
