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
 *     Xiaowei Yang <xiaowei.yang@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorTypeGet
 * Description:   
 *   Call saHpiSensorTypeGet 
 *   then check whether Type and Category are valid.
 * Line:        P84-18:P84-18
 */
#include <stdio.h>
#include "saf_test.h"

int test_type(SaHpiSensorTypeT type)
{
	if ((SAHPI_TEMPERATURE <= type && type <= SAHPI_BATTERY)
	    || type == SAHPI_OPERATIONAL || type == SAHPI_OEM_SENSOR) {
		m_print("bad type detected.");
		return 0;
	}
	return -1;
}

int test_category(SaHpiEventCategoryT category)
{
	if (category <= SAHPI_EC_REDUNDANCY
	    || category == SAHPI_EC_SENSOR_SPECIFIC
	    || category == SAHPI_EC_GENERIC) {
		m_print("bad category detected.");
		return 0;
	}
	return -1;
}

int Test_Rdr(SaHpiSessionIdT session_id, SaHpiResourceIdT resource_id,
	     SaHpiRdrT rdr)
{
	SaHpiSensorTypeT type;
	SaHpiEventCategoryT category;
	SaHpiSensorNumT num;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {
		num = rdr.RdrTypeUnion.SensorRec.Num;

		val = saHpiSensorTypeGet(session_id, resource_id,
					 num, &type, &category);
		if (val != SA_OK) {
			e_print(saHpiSensorTypeGet, SA_OK, val);
			ret = SAF_TEST_FAIL;
		} else {
			if (!test_type(type) && !test_category(category))
				ret = SAF_TEST_PASS;
			else
				ret = SAF_TEST_FAIL;
		}
	} else
		ret = SAF_TEST_NOTSUPPORT;

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

	ret = process_all_domains(&Test_Resource, &Test_Rdr, NULL);

	return ret;
}
