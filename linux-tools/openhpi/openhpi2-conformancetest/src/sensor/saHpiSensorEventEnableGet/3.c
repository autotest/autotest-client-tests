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
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorEventEnableGet
 * Description:  
 *   Call this function passing valid parameters.
 *   Expected return: SA_OK.
 * Line:        P87-16:P87-16
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Rdr(SaHpiSessionIdT session_id, SaHpiResourceIdT resource_id,
	     SaHpiRdrT rdr)
{
	SaHpiBoolT enable_old;
	SaErrorT val;
	SaHpiSensorNumT num;
	SaHpiEventStateT event;
	int ret = SAF_TEST_NOTSUPPORT;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {
		num = rdr.RdrTypeUnion.SensorRec.Num;
		event = rdr.RdrTypeUnion.SensorRec.Events;

		val = saHpiSensorEventEnableGet(session_id, resource_id, num,
						&enable_old);
		if (val != SA_OK) {
			e_print(saHpiSensorEventEnableGet, SA_OK, val);
			ret = SAF_TEST_FAIL;
		} else {
			ret = SAF_TEST_PASS;
		}
	}

	return ret;
}

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR)
		retval = do_resource(session, report, func);
	else			//Resource Does not support Sensors
		retval = SAF_TEST_NOTSUPPORT;

	return (retval);
}

/**********************************************************
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successfull
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(Test_Resource, Test_Rdr, NULL);

	return ret;
}
