/*
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005, Intel Corporation
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
 *     Wang Jing <jing.j.wang@intel.com>
 *      
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorEventEnableGet
 * Description:   
 *   Set event enable status then call this function to check
 *   if it takes effect.
 * Line:        P87-22:P87-23
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Rdr(SaHpiSessionIdT session_id, SaHpiResourceIdT resource_id,
	     SaHpiRdrT rdr)
{
	SaHpiBoolT enable, enable_old, enable_new;
	SaErrorT val;
	SaHpiSensorNumT num;
	SaHpiEventStateT event;
	int ret = SAF_TEST_UNKNOWN;

	/* Need to skip sensors which we can't set */
	if (rdr.RdrType == SAHPI_SENSOR_RDR &&
	    rdr.RdrTypeUnion.SensorRec.EventCtrl != SAHPI_SEC_READ_ONLY) {
		num = rdr.RdrTypeUnion.SensorRec.Num;
		event = rdr.RdrTypeUnion.SensorRec.Events;

		val = saHpiSensorEventEnableGet(session_id, resource_id, num,
						&enable_old);
		if (val != SA_OK) {
			e_print(saHpiSensorEventEnableGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out;
		}

		enable = SAHPI_TRUE;

		val = saHpiSensorEventEnableSet(session_id, resource_id, num,
						enable);
		if (val != SA_OK) {
			e_print(saHpiSensorEventEnableSet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out1;
		}

		val = saHpiSensorEventEnableGet(session_id, resource_id, num,
						&enable_new);
		if (val != SA_OK) {
			e_print(saHpiSensorEventEnableGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out1;
		}

		if (enable != enable_new) {
			e_print(saHpiSensorEventEnableGet,
				enable == enable_new, val);
			ret = SAF_TEST_FAIL;
			goto out1;
		}

		enable = SAHPI_FALSE;

		val = saHpiSensorEventEnableSet(session_id, resource_id, num,
						enable);
		if (val != SA_OK) {
			e_print(saHpiSensorEventEnableSet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out1;
		}

		val = saHpiSensorEventEnableGet(session_id, resource_id, num,
						&enable_new);
		if (val != SA_OK) {
			e_print(saHpiSensorEventEnableGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out1;
		}

		if (enable != enable_new) {
			e_print(saHpiSensorEventEnableGet,
				enable == enable_new, val);
			ret = SAF_TEST_FAIL;
		}

	      out1:
		val = saHpiSensorEventEnableSet(session_id, resource_id, num,
						enable_old);
		if (val != SA_OK) {
			e_print(saHpiSensorEventEnableSet, SA_OK, val);
		}
		if (ret == SAF_TEST_UNKNOWN)
			ret = SAF_TEST_PASS;
	} else
		ret = SAF_TEST_NOTSUPPORT;
      out:
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
