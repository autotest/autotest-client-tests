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
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *     Ye Bo <bo.ye@intel.com>
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiControlGet
 * Description:   
 *       Use valid parameters.
 *       Expected return: SA_OK.
 * Line:        P94-20:P94-20
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * Test with a set of valid parameters.  Verify that the returned
 * control mode and control state type are valid.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiCtrlStateT ctrlState;
	SaHpiCtrlModeT ctrlMode;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;

	if (!ctrlRec->WriteOnly) {

		status = saHpiControlGet(sessionId, resourceId, ctrlNum,
					 &ctrlMode, &ctrlState);

		if (status != SA_OK) {
			retval = SAF_TEST_FAIL;
			e_print(saHpiControlGet, SA_OK, status);
		} else {
			if (!isValidCtrlMode(ctrlMode)) {
				retval = SAF_TEST_FAIL;
				m_print("Invalid Control Mode [0x%x]!",
					ctrlMode);
			} else if (!isValidCtrlType(ctrlState.Type)) {
				retval = SAF_TEST_FAIL;
				m_print("Invalid Contrl Type [0x%x]!",
					ctrlState.Type);
			} else {
				retval = SAF_TEST_PASS;
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
