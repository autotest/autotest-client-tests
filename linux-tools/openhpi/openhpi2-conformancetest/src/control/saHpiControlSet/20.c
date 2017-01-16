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
 *      For a Digital control, set the digital value to 
 *      SAHPI_CTRL_STATE_PULSE_OFF for a digital control which 
 *      is already OFF. 
 *      Expected return: SA_ERR_HPI_INVALID_REQUEST. 
 * Line:        P97-2:P97-3
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * For a Digital Control that we can set and for which it is OFF, set
 * its value to PULSE_OFF which should result in an error.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlModeT ctrlMode;
	SaHpiCtrlStateT ctrlState;

	if (!ctrlRec->WriteOnly && isDigitalControl(ctrlRec)
	    && canSetControlState(ctrlRec)) {

		status = saHpiControlGet(sessionId, resourceId, ctrlNum,
					 &ctrlMode, &ctrlState);

		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiControlGet, SA_OK, status);
		} else if (ctrlState.StateUnion.Digital == SAHPI_CTRL_STATE_OFF) {

			setDefaultCtrlState(ctrlRec, &ctrlState);
			ctrlState.StateUnion.Digital =
			    SAHPI_CTRL_STATE_PULSE_OFF;

			status = saHpiControlSet(sessionId, resourceId, ctrlNum,
						 SAHPI_CTRL_MODE_MANUAL,
						 &ctrlState);

			if (status == SA_ERR_HPI_INVALID_REQUEST) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				e_print(saHpiControlSet,
					SA_ERR_HPI_INVALID_REQUEST, status);
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
