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
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Xiaowei Yang <xiaowei.yang@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorReadingGet
 * Description:   
 *   Call saHpiSensorReadingGet on a sensor which is disabled.
 *   Expected return:  call returns SA_ERR_HPI_INVALID_REQUEST.
 * Line:        P80-23:P80-23
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Rdr(SaHpiSessionIdT session,
	     SaHpiResourceIdT resourceId, SaHpiRdrT rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiSensorReadingT reading;
	SaHpiEventStateT EventState;
	SaHpiBoolT enable_old;
	SaHpiBoolT enable;

	if (rdr.RdrType == SAHPI_SENSOR_RDR
	    && rdr.RdrTypeUnion.SensorRec.EnableCtrl != SAHPI_FALSE) {
		//
		// Is this sensor disabled?
		//
		status = saHpiSensorEnableGet(session,
					      resourceId,
					      rdr.RdrTypeUnion.SensorRec.Num,
					      &enable_old);
		if (status != SA_OK) {
			e_print(saHpiSensorEnableGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			//
			// Check to see if the sensor is disabled
			//

			if (enable_old) {

				//
				// The sensor has not been disabled yet.
				// Call saHpiSensorEnableSet to disable the sensor.
				// 

				enable = !enable_old;
				status = saHpiSensorEnableSet(session,
							      resourceId,
							      rdr.RdrTypeUnion.
							      SensorRec.Num,
							      enable);

				if (status != SA_OK) {
					e_print(saHpiSensorEnableSet, SA_OK,
						status);
					retval = SAF_TEST_UNRESOLVED;
				}
			} else {
				enable = enable_old;
			}
		}
	} else			// Non-Sensor RDR
		retval = SAF_TEST_NOTSUPPORT;

	if (retval == SAF_TEST_UNKNOWN) {
		//
		//  Call saHpiSensorReadingGet passing on a disabled sensor.
		//
		status = saHpiSensorReadingGet(session,
					       resourceId,
					       rdr.RdrTypeUnion.SensorRec.Num,
					       &reading, &EventState);

		if (status != SA_ERR_HPI_INVALID_REQUEST) {
			e_print(saHpiSensorReadingGet,
				SA_ERR_HPI_INVALID_REQUEST, status);
			retval = SAF_TEST_FAIL;
		} else
			retval = SAF_TEST_PASS;

		//
		// Check to see if the sensor was originally disabled.
		// If not, saHpiSensorEnableSet needs to be called to enable the sensor.
		//

		if (enable != enable_old) {
			status = saHpiSensorEnableSet(session,
						      resourceId,
						      rdr.RdrTypeUnion.
						      SensorRec.Num,
						      enable_old);
		}
	}

	return (retval);
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
int main(int argc, char **argv)
{
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(Test_Resource, Test_Rdr, NULL);

	return (retval);
}
