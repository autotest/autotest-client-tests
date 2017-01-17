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
 *     Xiaowei Yang <xiaowei.yang@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorEventMasksSet
 * Description:   
 *   Call saHpiSensorEventMasksSet to clear the mask with 
 *   AssertEventMask/DeassertEventMask = SAHPI_ALL_EVENT_STATES 
 *   Check if AssertEventMask/DeassertEventMask are both set to 0
 * Line:        P91-14:P91-16
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Rdr(SaHpiSessionIdT session, SaHpiResourceIdT resource, SaHpiRdrT rdr)
{
	int retval = SAF_TEST_UNKNOWN;
	SaErrorT status;
	SaHpiSensorNumT s_num;
	SaHpiEventStateT AssertEventMask, DeassertEventMask;
	SaHpiEventStateT Assertsaved, Deassertsaved;

	/* Need to skip sensors which we can't set */
	if (rdr.RdrType == SAHPI_SENSOR_RDR) {
		if (rdr.RdrTypeUnion.SensorRec.EventCtrl != SAHPI_SEC_PER_EVENT) {
			retval = SAF_TEST_NOTSUPPORT;
			goto out;
		}
	} else {
		retval = SAF_TEST_NOTSUPPORT;
		goto out;
	}
	s_num = rdr.RdrTypeUnion.SensorRec.Num;
	status = saHpiSensorEventMasksGet(session,
					  resource,
					  s_num, &Assertsaved, &Deassertsaved);
	if (status != SA_OK) {
		e_print(saHpiSensorEventMasksGet, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
		goto out;
	}
	AssertEventMask = SAHPI_ALL_EVENT_STATES;
	DeassertEventMask = SAHPI_ALL_EVENT_STATES;
	status = saHpiSensorEventMasksSet(session,
					  resource,
					  s_num,
					  SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
					  AssertEventMask, DeassertEventMask);
	if (status != SA_OK) {
		e_print(saHpiSensorEventMasksSet, SA_OK, status);
		retval = SAF_TEST_FAIL;
		goto out;
	}
	status = saHpiSensorEventMasksGet(session,
					  resource,
					  s_num,
					  &AssertEventMask, &DeassertEventMask);
	if (status != SA_OK) {
		e_print(saHpiSensorEventMasksGet, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
		goto out1;
	} else if ((AssertEventMask != 0) || (DeassertEventMask != 0)) {
		m_print("The Event Masks were not completely cleared!");
		retval = SAF_TEST_FAIL;
	} else
		retval = SAF_TEST_PASS;
      out1:
	status = saHpiSensorEventMasksSet(session,
					  resource,
					  s_num,
					  SAHPI_SENS_ADD_EVENTS_TO_MASKS,
					  Assertsaved, Deassertsaved);
      out:
	return retval;
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
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(&Test_Resource, &Test_Rdr, NULL);

	return retval;
}
