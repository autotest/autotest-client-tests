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
 *   Call saHpiParmControl with Action=SAHPI_RESTORE_PARM, use 
 *      saHpiSensorThresholdsGet to retrieve the threshold values.
 *      Use saHpiSensorThresholdsSet to set the threshold values. 
 *      Call saHpiParmControl with SAHPI_RESTORE_PARM. Then use 
 *      saHpiSensorThresholdsGet to retrieve the threshold values. 
 *      This is used to show that saHpiParmControl works with
 *      Action=SAHPI_RESTORE_PARM.
 *      
 *   Expected return:  call returns SA_OK
 *
 * Line:        P153-19:P153-21
*/
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "saf_test.h"

#define THRESHOLDS_TEST_DATA    2

int do_sensor(SaHpiSessionIdT session, SaHpiResourceIdT resource, SaHpiRdrT rdr)
{
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	SaHpiSensorThresholdsT SensorThresholdsOld;
	SaHpiSensorThresholdsT SensorThresholdsNew;
	SaHpiSensorThresholdsT thresholds;

	SaHpiSensorThdMaskT read_thold;
	SaHpiSensorThdMaskT write_thold;

	SaHpiSensorNumT num;
	SaHpiSensorThdDefnT defn;

	// ----- Call saHpiParmControl with SAHPI_RESTORE_PARM ------
	val = saHpiParmControl(session, resource, SAHPI_RESTORE_PARM);

	if (val != SA_OK) {
		e_print(saHpiParmControl, SA_OK, val);
		ret = SAF_TEST_FAIL;
		return ret;
	}

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {
		num = rdr.RdrTypeUnion.SensorRec.Num;
		defn = rdr.RdrTypeUnion.SensorRec.ThresholdDefn;

		if (defn.IsAccessible == SAHPI_FALSE) {
			ret = SAF_TEST_NOTSUPPORT;
			return ret;
		}

		if (!defn.ReadThold || !defn.WriteThold) {
			ret = SAF_TEST_NOTSUPPORT;
			return ret;
		}
		// ---------------- Get the thresholds values -------------------
		val =
		    saHpiSensorThresholdsGet(session, resource, num,
					     &SensorThresholdsOld);

		if (val != SA_OK) {
			e_print(saHpiSensorThresholdsGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}
		// ---------------- Set the thresholds values -------------------

		thresholds = SensorThresholdsOld;
		read_thold = defn.ReadThold;
		write_thold = defn.WriteThold;

		if (read_thold & SAHPI_STM_LOW_CRIT
		    && write_thold & SAHPI_STM_LOW_CRIT) {
			if (thresholds.LowCritical.IsSupported == SAHPI_TRUE)
				thresholds.LowCritical.IsSupported =
				    SAHPI_FALSE;
			else
				thresholds.LowCritical.IsSupported = SAHPI_TRUE;
		}

		if (read_thold & SAHPI_STM_LOW_MAJOR
		    && write_thold & SAHPI_STM_LOW_MAJOR) {
			if (thresholds.LowMajor.IsSupported == SAHPI_TRUE)
				thresholds.LowMajor.IsSupported = SAHPI_FALSE;
			else
				thresholds.LowMajor.IsSupported = SAHPI_TRUE;
		}

		val =
		    saHpiSensorThresholdsSet(session, resource, num,
					     &thresholds);

		if (val != SA_OK) {
			e_print(saHpiSensorThresholdsSet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}
		// --------- Call saHpiParmControl with SAHPI_RESTORE_PARM ----------
		val = saHpiParmControl(session, resource, SAHPI_RESTORE_PARM);

		if (val != SA_OK) {
			e_print(saHpiParmControl, SA_OK, val);
			ret = SAF_TEST_FAIL;
			return ret;
		}
		// ------- Get the threshold values -------
		val =
		    saHpiSensorThresholdsGet(session, resource, num,
					     &SensorThresholdsNew);

		if (val != SA_OK) {
			e_print(saHpiSensorThresholdsGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			return ret;
		}

		if (memcmp
		    (&SensorThresholdsOld, &SensorThresholdsNew,
		     sizeof(thresholds)))
			ret = SAF_TEST_PASS;
		else {
			printf
			    ("  Does not conform to the expected behaviors!\n");
			printf
			    ("  Comparison between old and new thresholds failed!\n");
			printf("  The new thresholds is invalid!\n");
			ret = SAF_TEST_FAIL;
		}
	} else {
		// Not a Sensor RDR
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

/****************************************************************
 *   Main Function
 *      takes no arguments
 *
 *       returns: SAF_TEST_PASS when successful
 *                SAF_TEST_FAIL when an unexpected error occurs
 *
 ***************************************************************/
int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(&Test_Resource, &do_sensor, NULL);

	return ret;
}
