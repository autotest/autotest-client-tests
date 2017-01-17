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
 *      Test an Analog setting that is out of range. 
 *      Expected return: SA_ERR_HPI_INVALID_DATA. 
 * Line:        P96-24:P96-24
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * Set the value of an analog control.
 *
 *************************************************************************/

SaErrorT setAnalogState(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiCtrlRecT * ctrlRec, SaHpiInt32T value)
{
	SaErrorT status;
	SaHpiCtrlStateT ctrlState;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;

	setDefaultCtrlState(ctrlRec, &ctrlState);
	ctrlState.StateUnion.Analog = value;

	status = saHpiControlSet(sessionId, resourceId, ctrlNum,
				 SAHPI_CTRL_MODE_MANUAL, &ctrlState);

	return status;
}

/*************************************************************************
 *
 * Test setting an analog value out-of-range.  Try both the lower
 * and upper ranges.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;

	if (isAnalogControl(ctrlRec) && canSetControlState(ctrlRec)) {

		status = setAnalogState(sessionId, resourceId, ctrlRec,
					ctrlRec->TypeUnion.Analog.Max + 1);

		if (status != SA_ERR_HPI_INVALID_DATA) {
			retval = SAF_TEST_FAIL;
			e_print(saHpiControlSet, SA_ERR_HPI_INVALID_DATA,
				status);
		} else {
			status = setAnalogState(sessionId, resourceId, ctrlRec,
						ctrlRec->TypeUnion.Analog.Min -
						1);
			if (status != SA_ERR_HPI_INVALID_DATA) {
				retval = SAF_TEST_FAIL;
				e_print(saHpiControlSet,
					SA_ERR_HPI_INVALID_DATA, status);
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
