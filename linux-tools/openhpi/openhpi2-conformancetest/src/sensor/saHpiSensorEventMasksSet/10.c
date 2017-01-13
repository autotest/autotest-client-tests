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
 *   Call saHpiSensorEventMasksSet with an invalid Action parameter.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P90-36:P90-36
 */

#include <stdio.h>
#include "saf_test.h"

int Test_Rdr(SaHpiSessionIdT session, SaHpiResourceIdT resource, SaHpiRdrT rdr)
{
	int retval = SAF_TEST_UNKNOWN;
	SaErrorT status;
	SaHpiSensorNumT s_num;
	SaHpiEventStateT assertEventMask, deassertEventMask;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {
		if (rdr.RdrTypeUnion.SensorRec.EventCtrl != SAHPI_SEC_PER_EVENT) {
			retval = SAF_TEST_NOTSUPPORT;
			return retval;
		}

		s_num = rdr.RdrTypeUnion.SensorRec.Num;

		// Get the assert and deassert event masks for the sensor.
		status = saHpiSensorEventMasksGet(session,
						  resource,
						  s_num,
						  &assertEventMask,
						  &deassertEventMask);

		if (status != SA_OK) {
			if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
				m_print("The sensor is not present!");
				retval = SAF_TEST_NOTSUPPORT;
			} else {
				e_print(saHpiSensorEventMasksGet,
					SA_OK || SA_ERR_HPI_ENTITY_NOT_PRESENT,
					status);
				retval = SAF_TEST_UNRESOLVED;
			}
		} else {
			status = saHpiSensorEventMasksSet(session,
							  resource,
							  s_num,
							  SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS
							  + 1, assertEventMask,
							  deassertEventMask);

			if (status != SA_ERR_HPI_INVALID_PARAMS) {
				if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
					m_print("The sensor is not present!");
					retval = SAF_TEST_NOTSUPPORT;
				} else {
					e_print(saHpiSensorEventMasksSet,
						SA_ERR_HPI_INVALID_PARAMS
						||
						SA_ERR_HPI_ENTITY_NOT_PRESENT,
						status);
					retval = SAF_TEST_FAIL;
				}
			} else {
				retval = SAF_TEST_PASS;
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

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR) {
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
