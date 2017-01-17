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
 *      Donald A. Barre <dbarre@unh.ed>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiControlSet
 * Description: 
 *      For a Text control with a DataType of SAHPI_TL_TYPE_UNICODE 
 *      or SAHPI_TL_TYPE_TEXT, change the Language to a value not
 *      specified in the RDR.
 *      Expected return: SA_ERR_HPI_INVALID_DATA.
 * Line:        P96-28:P96-29
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * If we have a Text Control that we can set and it's data type is
 * either UNICODE or TEXT, try changing the first line of text with a
 * language different from that specified in the RDR.
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

		if (isUnicodeDataType(ctrlRec) || isTextDataType(ctrlRec)) {

			setDefaultCtrlState(ctrlRec, &ctrlState);

			// Change the ctrl state to a different language.

			if (getLanguage(ctrlRec) == SAHPI_LANG_ZULU) {
				setLanguage(&ctrlState, SAHPI_LANG_CHINESE);
			} else {
				setLanguage(&ctrlState, SAHPI_LANG_ZULU);
			}

			status = saHpiControlSet(sessionId, resourceId, ctrlNum,
						 SAHPI_CTRL_MODE_MANUAL,
						 &ctrlState);

			if (status == SA_ERR_HPI_INVALID_DATA) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				e_print(saHpiControlSet,
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
