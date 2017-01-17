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
 *      saHpiSensorEventMasksSet() to get the sensor assert and 
 *      deassert states. Use saHpiSensorEventMasksGet() to change the
 *      value. Call saHpiParmControl with Action=SAHPI_DEFAULT_PARM.
 *      Get the new values for the sensor assert and deassert states.
 *      Compare the new and old values to make sure that 
 *      saHpiParmControl works with Action=SAHPI_DEFAULT_PARM.
 *   Expected return:  call returns SA_OK
 *
 * Line:        P153-14:P153-15
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Case_Rdr(SaHpiSessionIdT session, SaHpiResourceIdT resourceId,
		  SaHpiRdrT rdr)
{
	int ret = SAF_TEST_UNKNOWN;
	SaErrorT status;
	SaHpiSensorNumT sensorNum;

	SaHpiEventStateT assertMaskOld, assertMaskNew;
	SaHpiEventStateT deassertMaskOld, deassertMaskNew;
	SaHpiEventStateT assertSaved, deassertSaved;

	// -------- Restore the default values --------
	status = saHpiParmControl(session, resourceId, SAHPI_DEFAULT_PARM);

	if (status != SA_OK)	// The function works abnormally
	{
		e_print(saHpiParmControl, SA_OK, status);
		ret = SAF_TEST_FAIL;
		return ret;
	}

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {
		if (rdr.RdrTypeUnion.SensorRec.EventCtrl != SAHPI_SEC_PER_EVENT) {
			ret = SAF_TEST_NOTSUPPORT;
			return ret;
		}

		sensorNum = rdr.RdrTypeUnion.SensorRec.Num;

		// ------ Get the state of the sensor ------
		status =
		    saHpiSensorEventMasksGet(session, resourceId, sensorNum,
					     &assertMaskOld, &deassertMaskOld);

		if (status != SA_OK) {
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}

		assertSaved = assertMaskOld + 5;
		deassertSaved = deassertMaskOld + 5;

		status =
		    saHpiSensorEventMasksSet(session, resourceId, sensorNum,
					     SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
					     assertSaved, deassertSaved);

		if (status != SA_OK) {
			e_print(saHpiSensorEventMasksSet, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}
		// ------- Call saHpiParmControl with valid parameters -------
		status =
		    saHpiParmControl(session, resourceId, SAHPI_DEFAULT_PARM);

		if (status != SA_OK) {
			e_print(saHpiParmControl, SA_OK, status);
			ret = SAF_TEST_FAIL;
			return ret;
		}
		// ------ Get the state of the sensor ------
		status =
		    saHpiSensorEventMasksGet(session, resourceId, sensorNum,
					     &assertMaskNew, &deassertMaskNew);

		if (status != SA_OK) {
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}
		// -------- Compare the old values with the new values --------
		if ((assertMaskOld != assertMaskNew)
		    || (deassertMaskOld != deassertMaskNew))
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
	int ret = SAF_TEST_UNKNOWN;

	if ((report.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR) &&
	    (report.ResourceCapabilities & SAHPI_CAPABILITY_CONFIGURATION)) {
		ret = do_resource(session, report, func);
	} else {
		ret = SAF_TEST_NOTSUPPORT;
	}

	return ret;
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

	ret = process_all_domains(&Test_Resource, &Test_Case_Rdr, NULL);

	return ret;
}
