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
 *     Carl McAdams <carlmc@us.ibm.com>
 *      Xiaowei Yang <xiaowei.yang@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorEventMasksGet
 * Description:   
 *   Check AssertEventMask and DeassertEventMark are the same 
 *   if the sensor's SAHPI_CAPABILITY_EVT_DEASSERTS flag is set.
 * Line:        P89-33:P89-34
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Rdr(SaHpiSessionIdT session, SaHpiResourceIdT resource, SaHpiRdrT rdr)
{
	int retval = SAF_TEST_UNKNOWN;
	SaErrorT status;
	SaHpiSensorNumT s_num;
	SaHpiEventStateT Assertsaved, Deassertsaved;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {
		s_num = rdr.RdrTypeUnion.SensorRec.Num;
		status = saHpiSensorEventMasksGet(session,
						  resource,
						  s_num,
						  &Assertsaved, &Deassertsaved);
		if (status != SA_OK) {
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else if (Assertsaved == Deassertsaved) {
			retval = SAF_TEST_PASS;
			m_print
			    ("AssertEventMask %d is equal to DeassertEventMask %d",
			     Assertsaved, Deassertsaved);
		} else {
			retval = SAF_TEST_FAIL;
			m_print
			    ("AssertEventMask %d is not equal to DeassertEventMask %d",
			     Assertsaved, Deassertsaved);
		}
	} else
		retval = SAF_TEST_NOTSUPPORT;

	return retval;
}

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if ((report.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR)
	    && (report.ResourceCapabilities & SAHPI_CAPABILITY_EVT_DEASSERTS))
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
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(&Test_Resource, &Test_Rdr, NULL);

	return retval;
}
