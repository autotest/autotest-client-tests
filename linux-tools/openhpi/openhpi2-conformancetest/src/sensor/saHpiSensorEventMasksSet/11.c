/*
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
 *      Lauren DeMarco <lkdm@cisunix.unh.edu>
 * 
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorEventMasksSet
 * Description:   
 *   Call saHpiSensorReadingGet to retrieve a sensor reading and the event
 *   states that are supported. Find an event state that is not supported.
 *   First call saHpiSensorEventMasksSet() with the Action parameter equal to
 *   SAHPI_SENS_ADD_EVENTS_TO_MASKS and with an assertEventMask that includes
 *   a bit for an event state that is not supported by the sensor. Then
 *   call saHpiSensorEventMasksSet() with the Action parameter equal to
 *   SAHPI_SENS_ADD_EVENTS_TO_MASKS and with a deassertEventMask that includes
 *   a bit for an event state that is not supported by the sensor.
 *   Expected return: SA_ERR_HPI_INVALID_DATA.
 * Line:        P90-33:P90-35
 */

#include <stdio.h>
#include "saf_test.h"

int Test_Rdr(SaHpiSessionIdT session, SaHpiResourceIdT resource, SaHpiRdrT rdr)
{
	int retval = SAF_TEST_UNKNOWN;
	SaErrorT status;
	SaHpiSensorNumT s_num;
	SaHpiSensorReadingT reading;
	SaHpiEventStateT eventState;
	SaHpiEventStateT assertEventMask, deassertEventMask;
	SaHpiSensorRecT *sensorRec;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {
		if (rdr.RdrTypeUnion.SensorRec.EventCtrl != SAHPI_SEC_PER_EVENT) {
			retval = SAF_TEST_NOTSUPPORT;
			return retval;
		}

	    sensorRec = &rdr.RdrTypeUnion.SensorRec;
		s_num = sensorRec->Num;

		//
		//  Call saHpiSensorReadingGet to retrieve the event states that
		//  are supported.
		// 

		eventState = sensorRec->Events;

		if (retval == SAF_TEST_UNKNOWN) {

			//
			//  Examine each bit in eventState to find an event state that 
			//  is not supported. Set assertEventMask equal to that value.
			//

			if (!(eventState & 0x0001)) {
				assertEventMask = 0x0001;
			} else if (!(eventState & 0x0002)) {
				assertEventMask = 0x0002;
			} else if (!(eventState & 0x0004)) {
				assertEventMask = 0x0004;
			} else if (!(eventState & 0x0008)) {
				assertEventMask = 0x0008;
			} else if (!(eventState & 0x0010)) {
				assertEventMask = 0x0010;
			} else if (!(eventState & 0x0020)) {
				assertEventMask = 0x0020;
			} else if (!(eventState & 0x0040)) {
				assertEventMask = 0x0040;
			} else if (!(eventState & 0x0080)) {
				assertEventMask = 0x0080;
			} else if (!(eventState & 0x0100)) {
				assertEventMask = 0x0100;
			} else if (!(eventState & 0x0200)) {
				assertEventMask = 0x0200;
			} else if (!(eventState & 0x0400)) {
				assertEventMask = 0x0400;
			} else if (!(eventState & 0x0800)) {
				assertEventMask = 0x0800;
			} else if (!(eventState & 0x1000)) {
				assertEventMask = 0x1000;
			} else if (!(eventState & 0x2000)) {
				assertEventMask = 0x2000;
			} else if (!(eventState & 0x4000)) {
				assertEventMask = 0x4000;
			} else {
				m_print("All event states are supported!");
				retval = SAF_TEST_NOTSUPPORT;
			}

			deassertEventMask = 0x0000;
		}

		if (retval == SAF_TEST_UNKNOWN) {

			//
			//  Call saHpiSensorEventMasksSet with an assertEventMask value
			//  that includes a bit for an event state that is not supported
			//  by the sensor.
			//      

			status = saHpiSensorEventMasksSet(session,
							  resource,
							  s_num,
							  SAHPI_SENS_ADD_EVENTS_TO_MASKS,
							  assertEventMask,
							  deassertEventMask);

			if (status != SA_ERR_HPI_INVALID_DATA) {
				if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
					m_print("The sensor is not present!");
					retval = SAF_TEST_NOTSUPPORT;
				} else {
					e_print(saHpiSensorEventMasksSet,
						SA_ERR_HPI_INVALID_DATA || SA_ERR_HPI_ENTITY_NOT_PRESENT,
						status);
					retval = SAF_TEST_FAIL;
				}
			} else {
				deassertEventMask = assertEventMask;
				assertEventMask = 0x0000;

				//
				//  Call saHpiSensorEventMasksSet with a deassertEventMask 
				//  value that includes a bit for an event state that is 
				//  not supported by the sensor.
				//   

				status = saHpiSensorEventMasksSet(session,
								  resource,
								  s_num,
								  SAHPI_SENS_ADD_EVENTS_TO_MASKS,
								  assertEventMask,
								  deassertEventMask);

				if (status != SA_ERR_HPI_INVALID_DATA) {
					if (status ==
					    SA_ERR_HPI_ENTITY_NOT_PRESENT) {
						m_print
						    ("The sensor is not present!");
						retval = SAF_TEST_NOTSUPPORT;
					} else {
						e_print
						    (saHpiSensorEventMasksSet,
						     SA_ERR_HPI_INVALID_DATA
						     ||
						     SA_ERR_HPI_ENTITY_NOT_PRESENT,
						     status);
						retval = SAF_TEST_FAIL;
					}
				} else {
					retval = SAF_TEST_PASS;
				}
			}
		}
	} else {
		retval = SAF_TEST_NOTSUPPORT;
	}

	return retval;
}

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if ((report.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR) &&
	    !(report.ResourceCapabilities & SAHPI_CAPABILITY_EVT_DEASSERTS)) {
		retval = do_resource(session, report, func);
	} else {
		// Resource does not support sensors
		retval = SAF_TEST_NOTSUPPORT;
	}

	return (retval);
}

/**********************************************************
 *   Main Function
 *      takes no arguments
 *      
 *       returns: SAF_TEST_PASS when successful
 *                SAF_TEST_FAIL when an unexpected error occurs
 *************************************************************/
int main()
{
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(&Test_Resource, &Test_Rdr, NULL);

	return retval;
}
