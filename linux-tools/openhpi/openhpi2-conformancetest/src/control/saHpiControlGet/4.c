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
 * Function:    saHpiControlGet
 * Description: 
 *      Call saHpiControlGet passing in a bad control number.
 *      Expected return: SA_ERR_HPI_NOT_PRESENT.
 * Line:        P94-27:P94-27
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * Test an invalid control number.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval;
	SaHpiCtrlModeT ctrlMode;
	SaHpiCtrlStateT ctrlState;

	status = saHpiControlGet(sessionId, resourceId,
				 INVALID_RDR_NUM, &ctrlMode, &ctrlState);

	if (status == SA_ERR_HPI_NOT_PRESENT) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiControlGet, SA_ERR_HPI_NOT_PRESENT, status);
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
