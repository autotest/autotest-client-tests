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
 *   Call saHpiParmControl with Action=SAHPI_SAVE_PARM. Use
 *      saHpiSensorEnableGet() to get the sensor enable state.
 *      Then use saHpiAutoSensorEnableSet() to change the value.
 *      Then call saHpiParmControl with Action=SAHPI_RESTORE_PARM to
 *      make sure that saHpiParmControl with SAHPI_SAVE_PARM works.
 *   Expected return:  call returns SA_OK
 *
 * Line:        P152-7:P153-16:P153-17:P153-18
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

int do_sensor(SaHpiSessionIdT session, SaHpiResourceIdT resourceId,
	      SaHpiRdrT rdr)
{
	SaErrorT status;
	int ret = SAF_TEST_UNKNOWN;
	SaHpiSensorNumT sensorNum = 0;

	SaHpiBoolT originalSensorEnabled;
	SaHpiBoolT newSensorEnabled;

	// ------------- Save the current values --------------

	status = saHpiParmControl(session, resourceId, SAHPI_SAVE_PARM);

	if (status != SA_OK)	// The function works abnormally
	{
		e_print(saHpiParmControl, SA_OK, status);
		ret = SAF_TEST_FAIL;
		return ret;
	}

	if (rdr.RdrType == SAHPI_SENSOR_RDR &&
	    rdr.RdrTypeUnion.SensorRec.EnableCtrl != SAHPI_FALSE) {
		sensorNum = rdr.RdrTypeUnion.SensorRec.Num;

		// --------- Get the sensor enable state ---------

		status =
		    saHpiSensorEnableGet(session, resourceId, sensorNum,
					 &originalSensorEnabled);

		if (status != SA_OK) {
			e_print(saHpiSensorEnableGet, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}
		// -------- Change the sensor enable state --------

		if (originalSensorEnabled == SAHPI_TRUE)
			saHpiSensorEnableSet(session, resourceId, sensorNum,
					     SAHPI_FALSE);
		else
			saHpiSensorEnableSet(session, resourceId, sensorNum,
					     SAHPI_TRUE);

		if (status != SA_OK)	// The function works abnormally
		{
			e_print(saHpiSensorEnableGet, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}
		// ------- Call saHpiParmControl with valid parameters -------

		status =
		    saHpiParmControl(session, resourceId, SAHPI_RESTORE_PARM);

		if (status != SA_OK)	// The function works abnormally
		{
			e_print(saHpiParmControl, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}
		// ---------- Get the sensor enable state ----------

		status =
		    saHpiSensorEnableGet(session, resourceId, sensorNum,
					 &newSensorEnabled);

		if (status != SA_OK) {
			e_print(saHpiSensorEnableGet, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}
		// ----- Compare the old value to the new value -----

		if (newSensorEnabled != originalSensorEnabled)
			ret = SAF_TEST_FAIL;
		else
			ret = SAF_TEST_PASS;
	} else {
		// Resource does not support sensors
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

	return (retval);
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
