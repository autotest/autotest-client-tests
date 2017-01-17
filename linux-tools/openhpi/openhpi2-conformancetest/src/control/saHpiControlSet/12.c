/*
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005, Intel Corporation
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
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Xiaowei Yang <xiaowei.yang@intel.com>
 *      Ye Bo <bo.ye@intel.com>
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiControlSet
 * Description:  
 *      Call saHpiControlSet setting the Data Length and Line so
 *      that it overflows the remaining Text control space.
 *      Expected return: SA_ERR_HPI_INVALID_DATA. 
 * Line:        P96-25:P96-26
 */

#include <stdio.h>
#include "../include/control_test.h"

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
 * Return true if the control text buffer can be overflowed; otherwise false.
 *
 *************************************************************************/

SaHpiBoolT canOverflow(SaHpiCtrlRecT * ctrlRec)
{
	return (getMaxBytes(ctrlRec) < getMaxDataLength(ctrlRec));
}

/*************************************************************************
 *
 * If we have a Text Control and we can change it's state and we can
 * overflow the control's text buffer, then let's try to overflow that buffer. 
 *
 * To overflow the buffer, we must write to the last line, i.e. "MaxLines",
 * in the control and write more bytes than the line can hold.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int i;
	int numBytes;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlStateT ctrlState;

	if (isTextControl(ctrlRec) && canSetControlState(ctrlRec)
	    && canOverflow(ctrlRec)) {

		numBytes = getMaxDataLength(ctrlRec);

		setDefaultCtrlState(ctrlRec, &ctrlState);
		ctrlState.StateUnion.Text.Line =
		    ctrlRec->TypeUnion.Text.MaxLines;
		ctrlState.StateUnion.Text.Text.DataLength = numBytes;

		for (i = 0; i < numBytes; i++) {
			ctrlState.StateUnion.Text.Text.Data[i] = BYTE_VALUE_1;
		}

		status = saHpiControlSet(sessionId, resourceId, ctrlNum,
					 SAHPI_CTRL_MODE_MANUAL, &ctrlState);

		if (status == SA_ERR_HPI_INVALID_DATA) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiControlSet, SA_ERR_HPI_INVALID_DATA,
				status);
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
