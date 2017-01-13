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
 * Function:    saHpiSensorEnableGet
 * Description:   
 *   Attempt to toggle the sensor enable status to true and false
 *   and verify that the status changed using saHpiSensorEnableGet.
 * Line:        P85-22:P85-23
 */

#include <stdio.h>
#include <string.h>
#include "saf_test.h"

/*********************************************************************
 * WARNING: This test is exactly the same as saHpiSensorEnableGet/3.c.
 * If this test changes, that test must also be updated.
 * *******************************************************************/

/*********************************************************************
 * Determine if two boolean values are the same or not.  This
 * function is needed because a TRUE value is anything other than
 * zero.  In other words, if one boolean value is 2 and the other
 * is 3, then they are the same since the are both TRUE.  In other
 * words, we can't to a simple comparison.
 * *******************************************************************/

SaHpiBoolT isSame(SaHpiBoolT b1, SaHpiBoolT b2)
{
	if (b1 == SAHPI_FALSE && b2 == SAHPI_FALSE) {
		return SAHPI_TRUE;
	} else if (b1 != SAHPI_FALSE && b2 != SAHPI_FALSE) {
		return SAHPI_TRUE;
	} else {
		return SAHPI_FALSE;
	}
}

/********************************************************************
 * Test the Sensor's saHpiSensorEnableSet by setting its value
 * and then reading the value to be sure that it really changed.
 * *****************************************************************/

int Test_Sensor(SaHpiSessionIdT session_id,
		SaHpiResourceIdT resource_id,
		SaHpiSensorNumT sensor_num, SaHpiBoolT enabled)
{
	int retval;
	SaErrorT status;
	SaHpiBoolT new_enabled;

	status =
	    saHpiSensorEnableSet(session_id, resource_id, sensor_num, enabled);
	if (status != SA_OK) {
		e_print(saHpiSensorEnableSet, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	} else {

		status = saHpiSensorEnableGet(session_id, resource_id,
					      sensor_num, &new_enabled);
		if (status != SA_OK) {
			e_print(saHpiSensorEnableGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else if (isSame(enabled, new_enabled)) {
			retval = SAF_TEST_PASS;
		} else {
			e_print(saHpiSensorEnableGet,
				enabled != new_enabled, status);
			retval = SAF_TEST_FAIL;
		}
	}

	return retval;
}

/*********************************************************************************
 * If we encounter a sensor for which we can change it's enabled status,
 * try toggling it the enabled status in both directions.  
 * *******************************************************************************/

int Test_Rdr(SaHpiSessionIdT session_id, SaHpiResourceIdT resource_id,
	     SaHpiRdrT rdr)
{
	SaHpiBoolT enabled;
	SaErrorT val;
	SaHpiSensorNumT num;
	int ret = SAF_TEST_NOTSUPPORT;

	/* Need to skip sensors which we can't set */
	if (rdr.RdrType == SAHPI_SENSOR_RDR &&
	    rdr.RdrTypeUnion.SensorRec.EnableCtrl != SAHPI_FALSE) {

		num = rdr.RdrTypeUnion.SensorRec.Num;

		// Get the original value.
		val = saHpiSensorEnableGet(session_id, resource_id,
					   num, &enabled);
		if (val != SA_OK) {
			e_print(saHpiSensorEnableGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
		} else {
			// try changing the enabled status
			ret =
			    Test_Sensor(session_id, resource_id, num, !enabled);
			if (ret == SAF_TEST_PASS) {
				// now try changing the enabled status back
				ret =
				    Test_Sensor(session_id, resource_id, num,
						enabled);
			}
			// Try to restore the original value.  Actually, if everything
			// well, it will have been restored, but just in case something
			// bad happened, let's do this to make sure we restored the status.

			val =
			    saHpiSensorEnableSet(session_id, resource_id, num,
						 enabled);
			if (val != SA_OK) {
				e_print(saHpiSensorEnableSet, SA_OK, val);
			}
		}
	}

	return ret;
}

/*************************************************************************************
 * Test a resource if it support sensors.
 * ***********************************************************************************/

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
