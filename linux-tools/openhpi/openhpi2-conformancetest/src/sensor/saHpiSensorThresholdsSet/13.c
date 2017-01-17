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
 *   Call function on a sensor which thresholds are set 
 *   with a negative hysteresis value.
 *   Expected return:  call returns with SA_ERR_HPI_INVALID_DATA
 * Line:        P82-30:P82-30
 */
#include <stdio.h>
#include "saf_test.h"

/**********************************************************
 *
 * Can this Sensor be tested?
 *
 **********************************************************/

SaHpiBoolT canTestPosThdHysteresis(SaHpiSensorRecT * sensorRec)
{
	return (sensorRec->ThresholdDefn.IsAccessible) &&
	    (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_UP_HYSTERESIS) &&
	    ((sensorRec->DataFormat.ReadingType ==
	      SAHPI_SENSOR_READING_TYPE_INT64)
	     || (sensorRec->DataFormat.ReadingType ==
		 SAHPI_SENSOR_READING_TYPE_FLOAT64));
}

SaHpiBoolT canTestNegThdHysteresis(SaHpiSensorRecT * sensorRec)
{
	return (sensorRec->ThresholdDefn.IsAccessible) &&
	    (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_LOW_HYSTERESIS) &&
	    ((sensorRec->DataFormat.ReadingType ==
	      SAHPI_SENSOR_READING_TYPE_INT64)
	     || (sensorRec->DataFormat.ReadingType ==
		 SAHPI_SENSOR_READING_TYPE_FLOAT64));
}

/**********************************************************
 *
 * Test Sensor.
 *
 **********************************************************/

int Test_Rdr(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId, SaHpiRdrT rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiSensorThresholdsT threshold;
	SaHpiSensorNumT s_num = 0;
	SaHpiSensorReadingTypeT type;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {
		if (canTestPosThdHysteresis(&rdr.RdrTypeUnion.SensorRec)) {
			// Test PosThdHysteresis

			s_num = rdr.RdrTypeUnion.SensorRec.Num;
			type =
			    rdr.RdrTypeUnion.SensorRec.DataFormat.ReadingType;

			threshold.LowCritical.IsSupported = SAHPI_FALSE;
			threshold.LowMajor.IsSupported = SAHPI_FALSE;
			threshold.LowMinor.IsSupported = SAHPI_FALSE;
			threshold.UpCritical.IsSupported = SAHPI_FALSE;
			threshold.UpMajor.IsSupported = SAHPI_FALSE;
			threshold.UpMinor.IsSupported = SAHPI_FALSE;
			threshold.NegThdHysteresis.IsSupported = SAHPI_FALSE;
			threshold.PosThdHysteresis.IsSupported = SAHPI_TRUE;
			threshold.PosThdHysteresis.Type = type;

			//
			//  Call saHpiSensorThresholdsSet setting the thresholds
			//  with a negative hysteresis value.
			//

			if (type == SAHPI_SENSOR_READING_TYPE_INT64) {
				threshold.PosThdHysteresis.Value.SensorInt64 =
				    -1;
			} else {
				threshold.PosThdHysteresis.Value.SensorFloat64 =
				    -1;
			}

			status = saHpiSensorThresholdsSet(sessionId,
							  resourceId,
							  s_num, &threshold);

			if (status == SA_ERR_HPI_INVALID_DATA) {
				retval = SAF_TEST_PASS;
			} else if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
				m_print("sensor is not present.");
				retval = SAF_TEST_NOTSUPPORT;
			} else if (status != SA_ERR_HPI_INVALID_DATA) {
				m_print("Test for PosThdHysteresis failed!");
				e_print(saHpiSensorThresholdsSet,
					SA_ERR_HPI_INVALID_DATA
					|| SA_ERR_HPI_ENTITY_NOT_PRESENT,
					status);
				retval = SAF_TEST_FAIL;
			} else {
				// Test for PosThdHysteresis passed and NegThdHysteresis is writable should be tested
				retval = SAF_TEST_UNKNOWN;
			}
		}
		// Even if the test passed for PosHysteresis, let's try the NegHysteresis
		// if possible.  If we can do, it should also pass.

		if ((retval == SAF_TEST_UNKNOWN || retval == SAF_TEST_PASS) &&
		    (canTestNegThdHysteresis(&rdr.RdrTypeUnion.SensorRec))) {

			// Test NegThdHysteresis

			s_num = rdr.RdrTypeUnion.SensorRec.Num;
			type =
			    rdr.RdrTypeUnion.SensorRec.DataFormat.ReadingType;

			threshold.LowCritical.IsSupported = SAHPI_FALSE;
			threshold.LowMajor.IsSupported = SAHPI_FALSE;
			threshold.LowMinor.IsSupported = SAHPI_FALSE;
			threshold.UpCritical.IsSupported = SAHPI_FALSE;
			threshold.UpMajor.IsSupported = SAHPI_FALSE;
			threshold.UpMinor.IsSupported = SAHPI_FALSE;
			threshold.PosThdHysteresis.IsSupported = SAHPI_FALSE;
			threshold.NegThdHysteresis.IsSupported = SAHPI_TRUE;
			threshold.NegThdHysteresis.Type = type;

			//
			//  Call saHpiSensorThresholdsSet setting the thresholds
			//  with a negative hysteresis value.
			//

			if (type == SAHPI_SENSOR_READING_TYPE_INT64) {
				threshold.NegThdHysteresis.Value.SensorInt64 =
				    -1;
			} else {
				threshold.NegThdHysteresis.Value.SensorFloat64 =
				    -1;
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
				m_print("Test for NegThdHysteresis failed!");
				e_print(saHpiSensorThresholdsSet,
					SA_ERR_HPI_INVALID_DATA
					|| SA_ERR_HPI_ENTITY_NOT_PRESENT,
					status);
			}
		}
	} else {
		retval = SAF_TEST_NOTSUPPORT;
	}

	return retval;
}

/**********************************************************
 *
 * Test resource
 *
 **********************************************************/

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
