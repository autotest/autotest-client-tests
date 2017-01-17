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
 *      Call saHpiControlGet on a resource which does not support Controls.
 *      Expected return: SA_ERR_HPI_CAPABILITY.
 * Line:        P94-23:P94-24
 */

#include <stdio.h>
#include "../include/control_test.h"

/***************************************************************
 *
 * Test a resource that does not suppport controls.
 *
 ***************************************************************/

int Test_Resource(SaHpiSessionIdT sessionId,
		  SaHpiRptEntryT report, callback2_t func)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiCtrlModeT ctrlMode;
	SaHpiCtrlStateT ctrlState;

	if (!hasControlCapability(&report)) {

		status = saHpiControlGet(sessionId, report.ResourceId,
					 0, &ctrlMode, &ctrlState);

		if (status == SA_ERR_HPI_CAPABILITY) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiControlGet, SA_ERR_HPI_CAPABILITY, status);
		}
	}

	return retval;
}

/***************************************************************
 *
 * Main Program
 *
 ***************************************************************/

int main(int argc, char **argv)
{
	return process_all_domains(Test_Resource, NULL, NULL);
}
