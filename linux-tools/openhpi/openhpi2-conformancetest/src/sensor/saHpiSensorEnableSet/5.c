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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorEnableSet
 * Description:   
 *   Call saHpiSensorEnableSet passing in a bad Sensor Number.
 *   Expected return: SA_ERR_HPI_NOT_PRESENT.
 * Line:        P86-19:P86-19
 */
#include <stdio.h>
#include "saf_test.h"

#define UNLIKELY_SENSOR_NUM 0xDEADBEEF

int Test_Rdr(SaHpiSessionIdT session,
	     SaHpiResourceIdT resourceId, SaHpiRdrT rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiSensorNumT s_num = 0;
	SaHpiBoolT Enable = SAHPI_FALSE;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {
		s_num = rdr.RdrTypeUnion.SensorRec.Num;
		//
		//  Call saHpiSensorEnableSet passing in a bad Sensor Number
		//
		status = saHpiSensorEnableSet(session,
					      resourceId,
					      UNLIKELY_SENSOR_NUM, Enable);
		if (status != SA_ERR_HPI_NOT_PRESENT) {
			e_print(saHpiSensorEnableSet,
				SA_ERR_HPI_NOT_PRESENT, status);
			retval = SAF_TEST_FAIL;
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
