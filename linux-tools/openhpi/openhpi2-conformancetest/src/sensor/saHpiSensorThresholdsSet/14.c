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
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorThresholdsSet
 * Description:   
 *   Call function on a sensor which thresholds are set with invalid type
 *   with that in the DataFormat.
 *   Expected return:  SA_ERR_HPI_INVALID_DATA.
 * Line:        P82-17:P82-18
 */

#include <stdio.h>
#include "saf_test.h"

SaHpiBoolT canTestLowCritical(SaHpiSensorRecT * sensorRec)
{
	return (sensorRec->ThresholdDefn.IsAccessible) &&
	    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_LOW_CRIT) &&
	    (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_LOW_CRIT);
}

SaHpiBoolT canTestLowMajor(SaHpiSensorRecT * sensorRec)
{
	return (sensorRec->ThresholdDefn.IsAccessible) &&
	    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_LOW_MAJOR) &&
	    (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_LOW_MAJOR);
}

SaHpiBoolT canTestLowMinor(SaHpiSensorRecT * sensorRec)
{
	return (sensorRec->ThresholdDefn.IsAccessible) &&
	    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_LOW_MINOR) &&
	    (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_LOW_MINOR);
}

SaHpiBoolT canTestUpCritical(SaHpiSensorRecT * sensorRec)
{
	return (sensorRec->ThresholdDefn.IsAccessible) &&
	    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_CRIT) &&
	    (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_UP_CRIT);
}

SaHpiBoolT canTestUpMajor(SaHpiSensorRecT * sensorRec)
{
	return (sensorRec->ThresholdDefn.IsAccessible) &&
	    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_MAJOR) &&
	    (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_UP_MAJOR);
}

SaHpiBoolT canTestUpMinor(SaHpiSensorRecT * sensorRec)
{
	return (sensorRec->ThresholdDefn.IsAccessible) &&
	    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_MINOR) &&
	    (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_UP_MINOR);
}

SaHpiBoolT canTestPosThdHysteresis(SaHpiSensorRecT * sensorRec)
{
	return (sensorRec->ThresholdDefn.IsAccessible) &&
	    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_HYSTERESIS) &&
	    (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_UP_HYSTERESIS);
}

SaHpiBoolT canTestNegThdHysteresis(SaHpiSensorRecT * sensorRec)
{
	return (sensorRec->ThresholdDefn.IsAccessible) &&
	    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_LOW_HYSTERESIS) &&
	    (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_LOW_HYSTERESIS);
}

/*************************************************************************************
 *
 * Test the Sensor.
 *
 *************************************************************************************/

int Test_Rdr(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId, SaHpiRdrT rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiSensorThresholdsT threshold;
	SaHpiSensorNumT s_num;
	SaHpiSensorReadingTypeT type;

	if (rdr.RdrType == SAHPI_SENSOR_RDR &&
	    (canTestLowCritical(&rdr.RdrTypeUnion.SensorRec) ||
	     canTestLowMajor(&rdr.RdrTypeUnion.SensorRec) ||
	     canTestLowMinor(&rdr.RdrTypeUnion.SensorRec) ||
	     canTestUpCritical(&rdr.RdrTypeUnion.SensorRec) ||
	     canTestUpMajor(&rdr.RdrTypeUnion.SensorRec) ||
	     canTestUpMinor(&rdr.RdrTypeUnion.SensorRec) ||
	     canTestPosThdHysteresis(&rdr.RdrTypeUnion.SensorRec) ||
	     canTestNegThdHysteresis(&rdr.RdrTypeUnion.SensorRec))) {

		s_num = rdr.RdrTypeUnion.SensorRec.Num;
		type = rdr.RdrTypeUnion.SensorRec.DataFormat.ReadingType;

		status = saHpiSensorThresholdsGet(sessionId,
						  resourceId,
						  s_num, &threshold);

		if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
			m_print("sensor is not present.");
			retval = SAF_TEST_NOTSUPPORT;
		} else if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiSensorThresholdsSet,
				SA_OK || SA_ERR_HPI_ENTITY_NOT_PRESENT, status);
		} else {

			// Set them all to SAHPI_FALSE initially

			threshold.UpMajor.IsSupported = SAHPI_FALSE;
			threshold.LowMajor.IsSupported = SAHPI_FALSE;
			threshold.LowCritical.IsSupported = SAHPI_FALSE;
			threshold.UpCritical.IsSupported = SAHPI_FALSE;
			threshold.PosThdHysteresis.IsSupported = SAHPI_FALSE;
			threshold.NegThdHysteresis.IsSupported = SAHPI_FALSE;
			threshold.LowMinor.IsSupported = SAHPI_FALSE;
			threshold.UpMinor.IsSupported = SAHPI_FALSE;

			if (canTestLowCritical(&rdr.RdrTypeUnion.SensorRec)) {
				// We are only setting LowCritical
				threshold.LowCritical.IsSupported = SAHPI_TRUE;

				if (type != SAHPI_SENSOR_READING_TYPE_INT64)
					threshold.LowCritical.Type =
					    SAHPI_SENSOR_READING_TYPE_INT64;
				else
					threshold.LowCritical.Type =
					    SAHPI_SENSOR_READING_TYPE_FLOAT64;
			} else if (canTestLowMajor(&rdr.RdrTypeUnion.SensorRec)) {
				// We are only setting LowMajor
				threshold.LowMajor.IsSupported = SAHPI_TRUE;

				if (type != SAHPI_SENSOR_READING_TYPE_INT64)
					threshold.LowMajor.Type =
					    SAHPI_SENSOR_READING_TYPE_INT64;
				else
					threshold.LowMajor.Type =
					    SAHPI_SENSOR_READING_TYPE_FLOAT64;
			} else if (canTestLowMinor(&rdr.RdrTypeUnion.SensorRec)) {
				// We are only setting LowMinor
				threshold.LowMinor.IsSupported = SAHPI_TRUE;

				if (type != SAHPI_SENSOR_READING_TYPE_INT64)
					threshold.LowMinor.Type =
					    SAHPI_SENSOR_READING_TYPE_INT64;
				else
					threshold.LowMinor.Type =
					    SAHPI_SENSOR_READING_TYPE_FLOAT64;
			} else
			    if (canTestUpCritical(&rdr.RdrTypeUnion.SensorRec))
			{
				// We are only setting UpCritical
				threshold.UpCritical.IsSupported = SAHPI_TRUE;

				if (type != SAHPI_SENSOR_READING_TYPE_INT64)
					threshold.UpCritical.Type =
					    SAHPI_SENSOR_READING_TYPE_INT64;
				else
					threshold.UpCritical.Type =
					    SAHPI_SENSOR_READING_TYPE_FLOAT64;
			} else if (canTestUpMajor(&rdr.RdrTypeUnion.SensorRec)) {
				// We are only setting UpMajor
				threshold.UpMajor.IsSupported = SAHPI_TRUE;

				if (type != SAHPI_SENSOR_READING_TYPE_INT64)
					threshold.UpMajor.Type =
					    SAHPI_SENSOR_READING_TYPE_INT64;
				else
					threshold.UpMajor.Type =
					    SAHPI_SENSOR_READING_TYPE_FLOAT64;
			} else if (canTestUpMinor(&rdr.RdrTypeUnion.SensorRec)) {
				// We are only setting UpMinor
				threshold.UpMinor.IsSupported = SAHPI_TRUE;

				if (type != SAHPI_SENSOR_READING_TYPE_INT64)
					threshold.UpMinor.Type =
					    SAHPI_SENSOR_READING_TYPE_INT64;
				else
					threshold.UpMinor.Type =
					    SAHPI_SENSOR_READING_TYPE_FLOAT64;
			} else
			    if (canTestPosThdHysteresis
				(&rdr.RdrTypeUnion.SensorRec)) {
				// We are only setting PosThdHysteresis
				threshold.PosThdHysteresis.IsSupported =
				    SAHPI_TRUE;

				if (type != SAHPI_SENSOR_READING_TYPE_INT64)
					threshold.PosThdHysteresis.Type =
					    SAHPI_SENSOR_READING_TYPE_INT64;
				else
					threshold.PosThdHysteresis.Type =
					    SAHPI_SENSOR_READING_TYPE_FLOAT64;
			} else
			    if (canTestNegThdHysteresis
				(&rdr.RdrTypeUnion.SensorRec)) {
				// We are only setting NegThdHysteresis
				threshold.NegThdHysteresis.IsSupported =
				    SAHPI_TRUE;

				if (type != SAHPI_SENSOR_READING_TYPE_INT64)
					threshold.NegThdHysteresis.Type =
					    SAHPI_SENSOR_READING_TYPE_INT64;
				else
					threshold.NegThdHysteresis.Type =
					    SAHPI_SENSOR_READING_TYPE_FLOAT64;
			}

			status = saHpiSensorThresholdsSet(sessionId,
							  resourceId,
							  s_num, &threshold);

			if (status == SA_ERR_HPI_INVALID_DATA) {
				retval = SAF_TEST_PASS;
			} else if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
				m_print("sensor is not present.");
				retval = SAF_TEST_NOTSUPPORT;
			} else {
				retval = SAF_TEST_FAIL;
				e_print(saHpiSensorThresholdsSet,
					SA_ERR_HPI_INVALID_DATA
					|| SA_ERR_HPI_ENTITY_NOT_PRESENT,
					status);
			}
		}
	}

	return retval;
}

/*************************************************************************************
 *
 * Test the Resource.
 *
 *************************************************************************************/

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
int main(int argc, char **argv)
{
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(Test_Resource, Test_Rdr, NULL);

	return (retval);
}
