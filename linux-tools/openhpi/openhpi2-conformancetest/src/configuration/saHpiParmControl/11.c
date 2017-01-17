/*
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
 *      Lauren DeMarco <lkdm@cisunix.unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiParmControl
 * Description:
 *   Call saHpiParmControl passing valid parameters with action=SAHPI_RESTORE_PARM
 *   Expected return:  call returns SA_OK
 *
 * Line:        P153-19:P153-23
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
		  callback2_t func)
{
	SaHpiResourceIdT resource_id = rpt_entry.ResourceId;
	SaHpiParmActionT action = SAHPI_RESTORE_PARM;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	// Check to see if parameter control is supported
	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_CONFIGURATION) {
		// Call saHpiParmControl with valid parameters
		val = saHpiParmControl(session_id, resource_id, action);

		if (val != SA_OK)	// The function works abnormally
		{
			e_print(saHpiParmControl, SA_OK, val);
			ret = SAF_TEST_FAIL;
		} else		// The function works the way it should
			ret = SAF_TEST_PASS;
	} else
		// Resource Does not support parameter control
		ret = SAF_TEST_NOTSUPPORT;

	return ret;
}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(Test_Resource, NULL, NULL);

	return ret;
}
