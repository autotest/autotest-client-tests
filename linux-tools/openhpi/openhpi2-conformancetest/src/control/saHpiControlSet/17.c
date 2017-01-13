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
 *      Set the StreamLength greater than SAHPI_CTRL_MAX_STREAM_LENGTH.
 *      Expected return: SA_ERR_HPI_INVALID_PARAMS. 
 * Line:        P96-35:P96-35
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * For a Stream Control that can be set, test a stream length that is
 * one bigger than the maximum allowed length.
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

	if (isStreamControl(ctrlRec) && canSetControlState(ctrlRec)) {

		// Set the default Stream control state and then
		// change the length to one bigger than a legal size.

		setDefaultCtrlState(ctrlRec, &ctrlState);
		ctrlState.StateUnion.Stream.StreamLength =
		    SAHPI_CTRL_MAX_STREAM_LENGTH + 1;

		status = saHpiControlSet(sessionId, resourceId, ctrlNum,
					 SAHPI_CTRL_MODE_MANUAL, &ctrlState);

		if (status == SA_ERR_HPI_INVALID_PARAMS) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiControlSet, SA_ERR_HPI_INVALID_PARAMS,
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
