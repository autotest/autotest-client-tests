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
 *      For Text controls, fill the text buffers for each line.
 *      Verify that the change occured by reading the text lines.
 *      Expected return: SA_OK.
 * Line:        P97-10:P97-11
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * If we have a Text Control, try completely filling each text buffer
 * for each line.  If successful, try reading all of this text data back
 * and verify that is indeed what we set it to.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	int lineNum;
	int maxLines;
	int maxBytes;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlModeT ctrlMode;
	SaHpiCtrlStateT ctrlState;
	ControlData controlData;

	if (!ctrlRec->WriteOnly && isTextControl(ctrlRec)
	    && canSetControlState(ctrlRec)) {

		status =
		    readControlData(sessionId, resourceId, ctrlRec,
				    &controlData);
		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {

			// Change the return value if anything goes wrong.

			retval = SAF_TEST_PASS;

			maxLines = ctrlRec->TypeUnion.Text.MaxLines;
			maxBytes = getMaxBytes(ctrlRec);

			// Initialize the ctrl state information that is the same
			// for each invocation of saHpiControlSet().

			status =
			    setControlAllTextBuffers(sessionId, resourceId,
						     ctrlRec, BYTE_VALUE_1);
			if (status != SA_OK) {
				e_trace();
				retval = SAF_TEST_FAIL;
			} else {

				// If we succesfully change each line of text, then read the
				// text data to verify that the change really did occur.

				for (lineNum = 1; lineNum <= maxLines;
				     lineNum++) {

					ctrlState.StateUnion.Text.Line =
					    lineNum;
					status =
					    saHpiControlGet(sessionId,
							    resourceId, ctrlNum,
							    &ctrlMode,
							    &ctrlState);
					if (status != SA_OK) {
						retval = SAF_TEST_UNRESOLVED;
						e_print(saHpiControlGet, SA_OK,
							status);
						break;
					} else
					    if (!matchesTextBuffer
						(&ctrlState.StateUnion.Text.
						 Text, maxBytes, BYTE_VALUE_1,
						 maxBytes)) {
						retval = SAF_TEST_FAIL;
						m_print
						    ("Text Buffers do not match!");
						break;
					}
				}
			}

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
