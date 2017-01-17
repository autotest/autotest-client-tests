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
 *     Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorEventMasksGet
 * Description:   
 *   Call saHpiSensorEventMasksSet to clear/set or set/clear mask 
 *   then call this function to check if it takes effect.
 * Line:        P89-25:P89-26
 */
#include <stdio.h>
#include "saf_test.h"

int add_events_test(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId, SaHpiRdrT * rdr)
{
	SaErrorT status;
	int retval;
	SaHpiSensorNumT s_num = rdr->RdrTypeUnion.SensorRec.Num;
	SaHpiEventStateT mask = rdr->RdrTypeUnion.SensorRec.Events;
	SaHpiEventStateT AssertEventMask, DeassertEventMask;

	status = saHpiSensorEventMasksSet(sessionId, resourceId, s_num,
					  SAHPI_SENS_ADD_EVENTS_TO_MASKS,
					  mask, mask);
	if (status != SA_OK) {
		e_print(saHpiSensorEventMasksSet, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	} else {

		status = saHpiSensorEventMasksGet(sessionId, resourceId, s_num,
						  &AssertEventMask,
						  &DeassertEventMask);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
		} else if (AssertEventMask == mask && DeassertEventMask == mask) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			m_print("Assert/Deassert Masks were not set!");
		}
	}

	return retval;
}

int remove_events_test(SaHpiSessionIdT sessionId,
		       SaHpiResourceIdT resourceId, SaHpiRdrT * rdr)
{
	SaErrorT status;
	int retval;
	SaHpiSensorNumT s_num = rdr->RdrTypeUnion.SensorRec.Num;
	SaHpiEventStateT mask = rdr->RdrTypeUnion.SensorRec.Events;
	SaHpiEventStateT AssertEventMask, DeassertEventMask;

	status = saHpiSensorEventMasksSet(sessionId, resourceId, s_num,
					  SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
					  mask, mask);
	if (status != SA_OK) {
		e_print(saHpiSensorEventMasksSet, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	} else {

		status = saHpiSensorEventMasksGet(sessionId, resourceId, s_num,
						  &AssertEventMask,
						  &DeassertEventMask);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
		} else if (AssertEventMask == 0 && DeassertEventMask == 0) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			m_print("Assert/Deassert Masks were not cleared!");
		}
	}

	return retval;
}

void reset_event_masks(SaHpiSessionIdT sessionId,
		       SaHpiResourceIdT resourceId,
		       SaHpiRdrT * rdr,
		       SaHpiEventStateT assertMask,
		       SaHpiEventStateT deassertMask)
{
	SaErrorT status;
	SaHpiSensorNumT s_num = rdr->RdrTypeUnion.SensorRec.Num;
	SaHpiEventStateT mask = rdr->RdrTypeUnion.SensorRec.Events;

	// clear all of the bits
	status = saHpiSensorEventMasksSet(sessionId, resourceId, s_num,
					  SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
					  mask, mask);
	if (status != SA_OK) {
		e_print(saHpiSensorEventMasksSet, SA_OK, status);
	} else {
		status = saHpiSensorEventMasksSet(sessionId, resourceId, s_num,
						  SAHPI_SENS_ADD_EVENTS_TO_MASKS,
						  assertMask, deassertMask);

		if (status != SA_OK) {
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
		}
	}
}

int Test_Rdr(SaHpiSessionIdT session, SaHpiResourceIdT resource, SaHpiRdrT rdr)
{
	int retval = SAF_TEST_NOTSUPPORT;
	SaErrorT status;
	SaHpiSensorNumT s_num;
	SaHpiEventStateT Assertsaved, Deassertsaved;

	/* Need to skip sensors which we can't set */
	if ((rdr.RdrType == SAHPI_SENSOR_RDR) &&
	    (rdr.RdrTypeUnion.SensorRec.EventCtrl == SAHPI_SEC_PER_EVENT)) {
		s_num = rdr.RdrTypeUnion.SensorRec.Num;
		status = saHpiSensorEventMasksGet(session, resource, s_num,
						  &Assertsaved, &Deassertsaved);

		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
		} else {

			if (Assertsaved == 0) {
				retval =
				    add_events_test(session, resource, &rdr);
				if (retval == SAF_TEST_PASS) {
					retval =
					    remove_events_test(session,
							       resource, &rdr);
				}
			} else {
				retval =
				    remove_events_test(session, resource, &rdr);
				if (retval == SAF_TEST_PASS) {
					retval =
					    add_events_test(session, resource,
							    &rdr);
				}
			}

			reset_event_masks(session, resource, &rdr, Assertsaved,
					  Deassertsaved);
		}
	}

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
