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
 * Function:    saHpiParmControl
 * Description:
 *   Call saHpiParmControl with Action=SAHPI_DEFAULT_PARM. Use
 *      saHpiSensorEventEnableGet() to get the sensor event enable
 *      state. Then use saHpiSensorEventEnableSet() to change the value.
 *      Call saHpiParmControl with Action=SAHPI_DEFAULT_PARM. Get
 *      the new value for the sensor event enable state. Compare the
 *      old and new values to make sure that saHpiParmControl works 
 *      with Action=SAHPI_DEFAULT_PARM.
 *   Expected return:  call returns SA_OK
 *
 * Line:        P153-14:P153-15
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

int do_sensor(SaHpiSessionIdT session, SaHpiResourceIdT resourceId,
	      SaHpiRdrT rdr)
{
	SaErrorT status;
	int ret = SAF_TEST_UNKNOWN;
	SaHpiSensorNumT sensorNum;

	SaHpiEventStateT event;

	SaHpiBoolT originalEventEnabled;
	SaHpiBoolT newEventEnabled;

	// --------------- Restore the default values ----------------
	status = saHpiParmControl(session, resourceId, SAHPI_DEFAULT_PARM);

	if (status != SA_OK)	// The function works abnormally
	{
		e_print(saHpiParmControl, SA_OK, status);
		ret = SAF_TEST_FAIL;
		return ret;
	}

	if (rdr.RdrType == SAHPI_SENSOR_RDR &&
	    rdr.RdrTypeUnion.SensorRec.EventCtrl != SAHPI_SEC_READ_ONLY) {
		sensorNum = rdr.RdrTypeUnion.SensorRec.Num;
		event = rdr.RdrTypeUnion.SensorRec.Events;

		// --------- Get the sensor event enable state --------
		status =
		    saHpiSensorEventEnableGet(session, resourceId, sensorNum,
					      &originalEventEnabled);

		if (status != SA_OK) {
			e_print(saHpiSensorEventEnableGet, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}
		// ------- Change the sensor event enable state -------
		if (originalEventEnabled == SAHPI_TRUE)
			saHpiSensorEventEnableSet(session, resourceId,
						  sensorNum, SAHPI_FALSE);
		else
			saHpiSensorEventEnableSet(session, resourceId,
						  sensorNum, SAHPI_TRUE);

		if (status != SA_OK)	// The function works abnormally
		{
			e_print(saHpiSensorEventEnableGet, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}
		// --- Call saHpiParmControl with valid parameters ---
		status =
		    saHpiParmControl(session, resourceId, SAHPI_DEFAULT_PARM);

		if (status != SA_OK)	// The function works abnormally
		{
			e_print(saHpiParmControl, SA_OK, status);
			ret = SAF_TEST_FAIL;
			return ret;
		}
		// ------ Get the sensor event enable state ------
		status =
		    saHpiSensorEventEnableGet(session, resourceId, sensorNum,
					      &newEventEnabled);

		if (status != SA_OK) {
			e_print(saHpiSensorEventEnableGet, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}
		// ---- Compare the old value and the new value ----
		if (newEventEnabled != originalEventEnabled)
			ret = SAF_TEST_FAIL;
		else
			ret = SAF_TEST_PASS;
	} else {
		ret = SAF_TEST_NOTSUPPORT;
	}

	return ret;
}

int Test_Resource(SaHpiSessionIdT session, SaHpiRptEntryT report,
		  callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if ((report.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR) &&
	    (report.ResourceCapabilities & SAHPI_CAPABILITY_CONFIGURATION)) {
		retval = do_resource(session, report, func);
	} else {
		retval = SAF_TEST_NOTSUPPORT;
	}

	return retval;
}

/************************************************************************
 * Main Function
 *    takes no arguments
 *
 *     returns: SAF_TEST_PASS when successful
 *              SAF_TEST_FAIL when an unexpected error occurs
 ***********************************************************************/
int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(&Test_Resource, &do_sensor, NULL);

	return ret;
}
