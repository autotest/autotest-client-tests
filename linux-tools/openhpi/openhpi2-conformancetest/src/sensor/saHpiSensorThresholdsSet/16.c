/*
 * (C) Copyright Univeristy of New Hampshire 2006
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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorThresholdsSet
 * Description:   
 *   Attempt to change a threshold sensor by setting the
 *   the UpMinor threshold to a valid value and the PosThdHysteresis
 *   value to a negative value.  The set should fail and the
 *   the UpMinor value should not be changed.
 * Line:        P82-16:P82-16
 */

#include <stdio.h>
#include "saf_test.h"

/**********************************************************************************
 *
 * Initialize a threshold structure.
 *
 **********************************************************************************/

void initThresholds(SaHpiSensorThresholdsT * thresholds, int type)
{
	thresholds->LowCritical.IsSupported = SAHPI_FALSE;
	thresholds->LowMajor.IsSupported = SAHPI_FALSE;
	thresholds->LowMinor.IsSupported = SAHPI_FALSE;
	thresholds->UpCritical.IsSupported = SAHPI_FALSE;
	thresholds->UpMajor.IsSupported = SAHPI_FALSE;
	thresholds->UpMinor.IsSupported = SAHPI_FALSE;
	thresholds->PosThdHysteresis.IsSupported = SAHPI_FALSE;
	thresholds->NegThdHysteresis.IsSupported = SAHPI_FALSE;

	thresholds->LowCritical.Type = type;
	thresholds->LowMajor.Type = type;
	thresholds->LowMinor.Type = type;
	thresholds->UpCritical.Type = type;
	thresholds->UpMajor.Type = type;
	thresholds->UpMinor.Type = type;
	thresholds->PosThdHysteresis.Type = type;
	thresholds->NegThdHysteresis.Type = type;
}

/**********************************************************************************
 *
 * Set a threshold value with the value from another threshold.
 *
 **********************************************************************************/

void setThresholdValue(SaHpiSensorReadingT * toThreshold,
		       SaHpiSensorReadingT * fromThreshold)
{
	switch (toThreshold->Type) {
	case SAHPI_SENSOR_READING_TYPE_INT64:
		toThreshold->Value.SensorInt64 =
		    fromThreshold->Value.SensorInt64;
		break;

	case SAHPI_SENSOR_READING_TYPE_UINT64:
		toThreshold->Value.SensorUint64 =
		    fromThreshold->Value.SensorUint64;
		break;

	case SAHPI_SENSOR_READING_TYPE_FLOAT64:
		toThreshold->Value.SensorFloat64 =
		    fromThreshold->Value.SensorFloat64;
		break;

	case SAHPI_SENSOR_READING_TYPE_BUFFER:
		break;
	}
}

/**********************************************************************************
 *
 * Are the sensor threshold values equal or not?
 *
 **********************************************************************************/

SaHpiBoolT sameThresholdValue(SaHpiSensorReadingT * t1,
			      SaHpiSensorReadingT * t2)
{
	switch (t1->Type) {
	case SAHPI_SENSOR_READING_TYPE_INT64:
		return (t1->Value.SensorInt64 == t2->Value.SensorInt64);

	case SAHPI_SENSOR_READING_TYPE_UINT64:
		return (t1->Value.SensorUint64 == t2->Value.SensorUint64);

	case SAHPI_SENSOR_READING_TYPE_FLOAT64:
		return (t1->Value.SensorFloat64 == t2->Value.SensorFloat64);

	case SAHPI_SENSOR_READING_TYPE_BUFFER:
		break;
	}

	return SAHPI_FALSE;
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
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiSensorThresholdsT origThresholds;
	SaHpiSensorThresholdsT newThresholds;
	SaHpiSensorThresholdsT thresholds;
	SaHpiSensorRecT *sensorRec;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {

		sensorRec = &(rdr.RdrTypeUnion.SensorRec);

		if ((sensorRec->ThresholdDefn.IsAccessible) &&
		    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_LOW_MINOR)
		    && (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_MINOR)
		    && (sensorRec->ThresholdDefn.
			WriteThold & SAHPI_STM_UP_MINOR)
		    && (sensorRec->ThresholdDefn.
			WriteThold & SAHPI_STM_UP_HYSTERESIS)
		    &&
		    ((sensorRec->DataFormat.ReadingType ==
		      SAHPI_SENSOR_READING_TYPE_INT64)
		     || (sensorRec->DataFormat.ReadingType ==
			 SAHPI_SENSOR_READING_TYPE_FLOAT64))) {

			status =
			    saHpiSensorThresholdsGet(sessionId, resourceId,
						     sensorRec->Num,
						     &origThresholds);

			if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
				retval = SAF_TEST_NOTSUPPORT;
			} else if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiSensorThresholdsGet, SA_OK,
					status);
			} else {

				initThresholds(&newThresholds,
					       sensorRec->DataFormat.
					       ReadingType);
				newThresholds.UpMinor.IsSupported = SAHPI_TRUE;
				newThresholds.PosThdHysteresis.IsSupported =
				    SAHPI_TRUE;

				setThresholdValue(&newThresholds.UpMinor,
						  &origThresholds.LowMinor);

				if (sensorRec->DataFormat.ReadingType ==
				    SAHPI_SENSOR_READING_TYPE_INT64) {
					newThresholds.PosThdHysteresis.Value.
					    SensorInt64 = -1;
				} else {
					newThresholds.PosThdHysteresis.Value.
					    SensorFloat64 = -1;
				}

				status =
				    saHpiSensorThresholdsSet(sessionId,
							     resourceId,
							     sensorRec->Num,
							     &newThresholds);

				if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
					retval = SAF_TEST_NOTSUPPORT;
					m_print("sensor is not present.");
				} else if (status == SA_OK) {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiSensorThresholdsSet,
						!SA_OK, status);
				} else {
					status =
					    saHpiSensorThresholdsGet(sessionId,
								     resourceId,
								     sensorRec->
								     Num,
								     &thresholds);

					if (status ==
					    SA_ERR_HPI_ENTITY_NOT_PRESENT) {
						retval = SAF_TEST_NOTSUPPORT;
					} else if (status != SA_OK) {
						retval = SAF_TEST_UNRESOLVED;
						e_print
						    (saHpiSensorThresholdsGet,
						     SA_OK, status);
					} else
					    if (sameThresholdValue
						(&thresholds.UpMinor,
						 &origThresholds.UpMinor)) {
						retval = SAF_TEST_PASS;
					} else {
						retval = SAF_TEST_FAIL;
						m_print
						    ("UpMinor was unexpectedly modified!");
					}
				}
			}
		}
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
	return process_all_domains(Test_Resource, Test_Rdr, NULL);
}
