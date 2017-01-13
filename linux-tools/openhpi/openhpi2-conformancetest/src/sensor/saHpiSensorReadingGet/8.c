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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorReadingGet
 * Description:   
 *   The EventState can only have bits set that correspond to the
 *   Sensor RDR Events field.
 * Line:        P80-31:P80-34
 */

#include <stdio.h>
#include "saf_test.h"

/***********************************************************************
 *
 * For enabled sensors, get the EventState and verify that all of
 * its set bits correspond to the Sensor RDR Events bit mask.
 *
 ***********************************************************************/

int Test_Rdr(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId, SaHpiRdrT rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiBoolT SensorEnabled;
	SaHpiEventStateT EventState;
	SaHpiSensorRecT *sensorRec;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {

		sensorRec = &(rdr.RdrTypeUnion.SensorRec),
		    status = saHpiSensorEnableGet(sessionId, resourceId,
						  sensorRec->Num,
						  &SensorEnabled);

		if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
			retval = SAF_TEST_NOTSUPPORT;
		} else if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiSensorEnableGet, SA_OK, status);
		} else if (!SensorEnabled) {
			// when the sensor is disabled we wont use it
			retval = SAF_TEST_NOTSUPPORT;
		} else {

			status = saHpiSensorReadingGet(sessionId, resourceId,
						       sensorRec->Num, NULL,
						       &EventState);

			if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
				retval = SAF_TEST_NOTSUPPORT;
			} else if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiSensorReadingGet, SA_OK, status);
			} else if ((EventState & sensorRec->Events) ==
				   EventState) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				m_print
				    ("Sensor is asserting events that are not supported!");
			}
		}
	}

	return retval;
}

/***********************************************************************
 *
 *
 *
 ***********************************************************************/

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_NOTSUPPORT;

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR) {
		retval = do_resource(session, report, func);
	}

	return retval;
}

/***********************************************************************
 *
 * Main Program
 *
 ***********************************************************************/

int main(int argc, char **argv)
{
	return process_all_domains(Test_Resource, Test_Rdr, NULL);
}
