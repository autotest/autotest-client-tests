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
 * Function:    saHpiSensorThresholdsGet
 * Description:   
 *   Call saHpiSensorThresholdsGet passing in a NULL pointer to SensorThresholds.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P81-19:P81-19
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Rdr(SaHpiSessionIdT session,
	     SaHpiResourceIdT resourceId, SaHpiRdrT rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiSensorNumT s_num = 0;
	SaHpiBoolT accessible;
	SaHpiSensorThdMaskT readmask;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {
		accessible =
		    rdr.RdrTypeUnion.SensorRec.ThresholdDefn.IsAccessible;
		readmask = rdr.RdrTypeUnion.SensorRec.ThresholdDefn.ReadThold;
		s_num = rdr.RdrTypeUnion.SensorRec.Num;
		if (accessible == SAHPI_FALSE || readmask == 0)
			retval = SAF_TEST_NOTSUPPORT;
	} else			// Non-Sensor RDR
		retval = SAF_TEST_NOTSUPPORT;

	if (retval == SAF_TEST_UNKNOWN) {
		//
		//  Call saHpiSensorThresholdsGet passing in a NULL pointer to SensorThresholds
		//
		status = saHpiSensorThresholdsGet(session,
						  resourceId, s_num, NULL);
		if (status != SA_ERR_HPI_INVALID_PARAMS) {
			if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
				m_print("sensor is not present.");
				retval = SAF_TEST_NOTSUPPORT;
			} else {
				e_print(saHpiSensorThresholdsGet,
					SA_ERR_HPI_INVALID_PARAMS
					|| SA_ERR_HPI_ENTITY_NOT_PRESENT,
					status);
				retval = SAF_TEST_FAIL;
			}
		} else
			retval = SAF_TEST_PASS;
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
