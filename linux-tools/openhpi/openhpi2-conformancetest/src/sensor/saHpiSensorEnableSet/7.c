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
 * Function:    saHpiSensorEnableSet
 * Description:   
 *   Disable a sensor, then call saHpiSensorReadingGet
 *   to check if it return an error.
 * Line:        P86-23:P86-23
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Rdr(SaHpiSessionIdT session_id, SaHpiResourceIdT resource_id,
	     SaHpiRdrT rdr)
{
	SaHpiBoolT enable, enable_old;
	SaErrorT val;
	SaHpiSensorNumT num;
	int ret = SAF_TEST_UNKNOWN;
	SaHpiSensorReadingT reading;

	/* Need to skip sensors which we can't set */
	if (rdr.RdrType == SAHPI_SENSOR_RDR &&
	    rdr.RdrTypeUnion.SensorRec.EnableCtrl != SAHPI_FALSE) {
		num = rdr.RdrTypeUnion.SensorRec.Num;

		val = saHpiSensorEnableGet(session_id, resource_id, num,
					   &enable_old);
		if (val != SA_OK) {
			e_print(saHpiSensorEnableGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out;
		}

		if (enable_old) {
			enable = SAHPI_FALSE;
			val = saHpiSensorEnableSet(session_id, resource_id, num,
						   enable);
			if (val != SA_OK) {
				e_print(saHpiSensorEnableSet, SA_OK, val);
				ret = SAF_TEST_UNRESOLVED;
				goto out1;
			}
		}

		val = saHpiSensorReadingGet(session_id, resource_id, num,
					    &reading, NULL);
		if (val != SA_ERR_HPI_INVALID_REQUEST) {
			e_print(saHpiSensorReadingGet, val != SA_OK, val);
			ret = SAF_TEST_FAIL;
		} else
			ret = SAF_TEST_PASS;

		if (ret == SAF_TEST_UNKNOWN)
			ret = SAF_TEST_PASS;
	      out1:
		val = saHpiSensorEnableSet(session_id, resource_id, num,
					   enable_old);
		if (val != SA_OK)
			e_print(saHpiSensorEnableSet, SA_OK, val);
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

	ret = process_all_domains(&Test_Resource, &Test_Rdr, NULL);

	return ret;
}
