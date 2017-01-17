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
 *      Wang Jing <jing.j.wang@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorEventMasksSet
 * Description:   
 *   Call saHpiSensorEventMasksSet against the sensor 
 *   with SAHPI_CAPABILITY_EVT_DEASSERTS flag set, 
 *   check DeassertEventMask is ignored
 * Line:        P91-9:P91-13
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Rdr(SaHpiSessionIdT session, SaHpiResourceIdT resource, SaHpiRdrT rdr)
{
	int retval = SAF_TEST_NOTSUPPORT;
	SaErrorT error;
	SaHpiSensorNumT s_num;
	SaHpiEventStateT AssertEventMask, DeassertEventMask;
	SaHpiEventStateT origAssertMask, origDeassertMask;
	SaHpiSensorRecT *sensorRec;

	/* Need to skip sensors which we can't set */
	if ((rdr.RdrType == SAHPI_SENSOR_RDR) &&
		(rdr.RdrTypeUnion.SensorRec.EventCtrl == SAHPI_SEC_PER_EVENT)) {

		sensorRec = &rdr.RdrTypeUnion.SensorRec;

		s_num = sensorRec->Num;
		error = saHpiSensorEventMasksGet(session, resource,
					  	        s_num, &origAssertMask, &origDeassertMask);
	    if (error != SA_OK) {
	    	retval = SAF_TEST_UNRESOLVED;
	    	e_print(saHpiSensorEventMasksGet, SA_OK, error);
	    } else {
			error = saHpiSensorEventMasksSet(session, resource,
							  s_num, SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
					  		  SAHPI_ALL_EVENT_STATES, 0x0);
			if (error != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiSensorEventMasksSet, SA_OK, error);
			} else {
				error = saHpiSensorEventMasksGet(session, resource,
					  			s_num, &AssertEventMask, &DeassertEventMask);
				if (error != SA_OK) {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiSensorEventMasksGet, SA_OK, error);
				} else if ((AssertEventMask != 0) || (DeassertEventMask != 0)) {
					retval = SAF_TEST_FAIL;
					m_print("The Event Masks were not completely cleared!");
				} else {
					error = saHpiSensorEventMasksSet(session, resource,
					  				s_num, SAHPI_SENS_ADD_EVENTS_TO_MASKS,
					  				sensorRec->Events, 0x0);

					if (error != SA_OK) {
						retval = SAF_TEST_UNRESOLVED;
						e_print(saHpiSensorEventMasksSet, SA_OK, error);
					} else {
						error = saHpiSensorEventMasksGet(session, resource,
					  					s_num, &AssertEventMask, &DeassertEventMask);
						if (error != SA_OK) {
							retval = SAF_TEST_UNRESOLVED;
							e_print(saHpiSensorEventMasksGet, SA_OK, error);
						} else if ((AssertEventMask != sensorRec->Events) ||
		   					       (DeassertEventMask != sensorRec->Events)) {
							retval = SAF_TEST_FAIL;
							m_print("The Event Masks were not set properly!");
						} else {
							retval = SAF_TEST_PASS;
						}
					}
				}
			}

			error = saHpiSensorEventMasksSet(session, resource,
							  s_num, SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
					  		  SAHPI_ALL_EVENT_STATES, SAHPI_ALL_EVENT_STATES);
			if (error != SA_OK) {
				e_print(saHpiSensorEventMasksSet, SA_OK, error);
			} else {
				error = saHpiSensorEventMasksSet(session, resource,
					  				s_num, SAHPI_SENS_ADD_EVENTS_TO_MASKS,
					  				origAssertMask, origDeassertMask);
				if (error != SA_OK) {
					e_print(saHpiSensorEventMasksSet, SA_OK, error);
				}
			}
		}
	}

	return retval;
}

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if ((report.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR) &&
	    (report.ResourceCapabilities & SAHPI_CAPABILITY_EVT_DEASSERTS))
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
