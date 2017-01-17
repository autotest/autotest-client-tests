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
 * Function:    saHpiControlGet()
 * Description:
 *      Verify that the text buffers don't exceed the length
 *      as specified by MaxChars and that the number of text
 *      buffer lines doesn't exceed MaxLines.
 * Line:        P95-7:P95-8
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * If this a Text control that we can read, then verify that the text
 * data in the control corresponds to the "MaxLines" and the "MaxChars"
 * as specified in the RDR.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	int line;
	int maxBytes;
	int maxLines;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlModeT ctrlMode;
	SaHpiCtrlStateT ctrlState;

	if (!ctrlRec->WriteOnly && isTextControl(ctrlRec)) {

		maxBytes = getMaxBytes(ctrlRec);
		maxLines = ctrlRec->TypeUnion.Text.MaxLines;

		// We should be able to read every text line.  If we can't, this
		// is obviously an error.  Also, the length of each line cannot 
		// be greater than the maximum number of allowed bytes.

		retval = SAF_TEST_UNKNOWN;
		for (line = 1; line <= maxLines; line++) {

			ctrlState.StateUnion.Text.Line = line;
			status = saHpiControlGet(sessionId, resourceId, ctrlNum,
						 &ctrlMode, &ctrlState);

			if (status != SA_OK) {
				retval = SAF_TEST_FAIL;
				e_print(saHpiControlGet, SA_OK, status);
				break;
			} else if (ctrlState.StateUnion.Text.Text.DataLength >
				   maxBytes) {
				retval = SAF_TEST_FAIL;
				m_print("Line %d has too many bytes [%d]!",
					line,
					ctrlState.StateUnion.Text.Text.
					DataLength);
				break;
			}
		}

		// If we haven't encountered any errors, try reading a line beyond
		// the "MaxLines" limit.  This should result in an error.

		if (retval == SAF_TEST_UNKNOWN) {
			ctrlState.StateUnion.Text.Line = maxLines + 1;
			status = saHpiControlGet(sessionId, resourceId, ctrlNum,
						 &ctrlMode, &ctrlState);
			if (status == SA_ERR_HPI_INVALID_DATA) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				e_print(saHpiControlGet,
					SA_ERR_HPI_INVALID_DATA, status);
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
