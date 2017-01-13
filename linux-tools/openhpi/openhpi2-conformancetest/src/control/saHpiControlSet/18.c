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
 *      For a Text Control, set the text buffer with characters that are not
 *      allowed according to the DataType.
 *      Expected return: SA_ERR_HPI_INVALID_PARAMS. 
 * Line:        P96-36:P96-37
 */

#include <stdio.h>
#include "../include/control_test.h"

#define CARRIAGE_RETURN 0x0D

/*************************************************************************
 *
 * For a Text Control that we can set and which uses ASCII6, BCDPLUS, or
 * UNICODE try writing a text character that is not allowed.  The other 
 * data types allow any character.  For UNICODE, note that we are setting
 * only one byte which is invalid since UNICODE requires an even number
 * of bytes.
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

	if (isTextControl(ctrlRec) && canSetControlState(ctrlRec)) {

		if (isAscii6DataType(ctrlRec) || isBcdPlusDataType(ctrlRec)
		    || isUnicodeDataType(ctrlRec)) {

			setDefaultCtrlState(ctrlRec, &ctrlState);

			ctrlState.StateUnion.Text.Text.DataLength = 1;
			ctrlState.StateUnion.Text.Text.Data[0] =
			    CARRIAGE_RETURN;

			status = saHpiControlSet(sessionId, resourceId, ctrlNum,
						 SAHPI_CTRL_MODE_MANUAL,
						 &ctrlState);

			if (status == SA_ERR_HPI_INVALID_PARAMS) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				e_print(saHpiControlSet,
					SA_ERR_HPI_INVALID_PARAMS, status);
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
