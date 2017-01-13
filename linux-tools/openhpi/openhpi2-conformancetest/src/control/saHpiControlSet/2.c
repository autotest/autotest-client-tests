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
 *      Call saHpiControlSet passing in a bad Session Id.
 *      Expected return: SA_ERR_HPI_INVALID_SESSION.
 * Line:        P29-47:P29-49
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * Test an invalid session id.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval;
	SaHpiSessionIdT bad_session_id = INVALID_SESSION_ID;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;

	// rule out the 1::4000000000 chance that this is a valid id

	if (bad_session_id == sessionId) {
		bad_session_id++;
	}

	status = saHpiControlSet(bad_session_id, resourceId, ctrlNum,
				 SAHPI_CTRL_MODE_AUTO, NULL);

	if (status == SA_ERR_HPI_INVALID_SESSION) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiControlSet, SA_ERR_HPI_INVALID_SESSION, status);
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
