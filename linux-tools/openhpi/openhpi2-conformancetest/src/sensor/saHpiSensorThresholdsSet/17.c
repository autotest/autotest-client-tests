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
 *   Verify that the implementation isn't adding the thresholds one value
 *   at a time and thus potentially responding with an out-of-order error.
 *   Expected return: SA_OK.
 * Line:        P82-16:P82-16
 */

#include <stdio.h>
#include "saf_test.h"

/**********************************************************************************
 *
 * Can we test this sensor?
 *
 **********************************************************************************/

SaHpiBoolT canTest(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId, SaHpiRdrT * rdr)
{
	SaHpiSensorRecT *sensorRec;

	if (rdr->RdrType == SAHPI_SENSOR_RDR) {

		sensorRec = &(rdr->RdrTypeUnion.SensorRec);

		if ((sensorRec->ThresholdDefn.IsAccessible) &&
		    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_LOW_CRIT) &&
		    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_LOW_MAJOR)
		    && (sensorRec->ThresholdDefn.
			ReadThold & SAHPI_STM_LOW_MINOR)
		    && (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_MINOR)
		    && (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_MAJOR)
		    && (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_CRIT)
		    && (sensorRec->ThresholdDefn.
			WriteThold & SAHPI_STM_LOW_MAJOR)
		    && (sensorRec->ThresholdDefn.
			WriteThold & SAHPI_STM_LOW_MINOR)
		    && (sensorRec->ThresholdDefn.
			WriteThold & SAHPI_STM_UP_MINOR)
		    && (sensorRec->ThresholdDefn.
			WriteThold & SAHPI_STM_UP_MAJOR)) {

			return SAHPI_TRUE;
		}

	}

	return SAHPI_FALSE;
}

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

/***************************************************************
 *
 * Set the LowMajor, LowMinor, UpMinor, and UpMajor thresholds.
 *
 ***************************************************************/

SaErrorT setThresholds(SaHpiSessionIdT sessionId,
		       SaHpiResourceIdT resourceId,
		       SaHpiSensorRecT * sensorRec,
		       SaHpiSensorReadingT * lowMajor,
		       SaHpiSensorReadingT * lowMinor,
		       SaHpiSensorReadingT * upMinor,
		       SaHpiSensorReadingT * upMajor)
{
	SaHpiSensorThresholdsT newThresholds;

	initThresholds(&newThresholds, sensorRec->DataFormat.ReadingType);

	newThresholds.LowMajor.IsSupported = SAHPI_TRUE;
	newThresholds.LowMinor.IsSupported = SAHPI_TRUE;
	newThresholds.UpMinor.IsSupported = SAHPI_TRUE;
	newThresholds.UpMajor.IsSupported = SAHPI_TRUE;

	setThresholdValue(&newThresholds.LowMajor, lowMajor);
	setThresholdValue(&newThresholds.LowMinor, lowMinor);
	setThresholdValue(&newThresholds.UpMinor, upMinor);
	setThresholdValue(&newThresholds.UpMajor, upMajor);

	return saHpiSensorThresholdsSet(sessionId, resourceId,
					sensorRec->Num, &newThresholds);
}

/***************************************************************
 *
 * Test Sensor.
 *
 * Should be able to set the Minor and Major thresholds
 * to Low Critical and Up Critical.  The implementation
 * should not get confused and report an out-of-order 
 * error.
 *
 ***************************************************************/

int Test_Rdr(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId, SaHpiRdrT rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiSensorThresholdsT origThresholds;
	SaHpiSensorRecT *sensorRec;

	if (canTest(sessionId, resourceId, &rdr)) {

		sensorRec = &(rdr.RdrTypeUnion.SensorRec);

		status =
		    saHpiSensorThresholdsGet(sessionId, resourceId,
					     sensorRec->Num, &origThresholds);

		if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
			retval = SAF_TEST_NOTSUPPORT;
		} else if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiSensorThresholdsGet, SA_OK, status);
		} else {

			status = setThresholds(sessionId, resourceId, sensorRec,
					       &origThresholds.LowCritical,
					       &origThresholds.LowCritical,
					       &origThresholds.LowCritical,
					       &origThresholds.LowCritical);

			if (status != SA_OK) {
				retval = SAF_TEST_FAIL;
				e_print(saHpiSensorThresholdsSet, SA_OK,
					status);
			} else {

				// restore the original values for the next test

				status =
				    setThresholds(sessionId, resourceId,
						  sensorRec,
						  &origThresholds.LowMajor,
						  &origThresholds.LowMinor,
						  &origThresholds.UpMinor,
						  &origThresholds.UpMajor);

				if (status != SA_OK) {
					status = SAF_TEST_UNRESOLVED;
					e_print(saHpiSensorThresholdsSet, SA_OK,
						status);
				} else {

					status =
					    setThresholds(sessionId, resourceId,
							  sensorRec,
							  &origThresholds.
							  UpCritical,
							  &origThresholds.
							  UpCritical,
							  &origThresholds.
							  UpCritical,
							  &origThresholds.
							  UpCritical);

					if (status != SA_OK) {
						retval = SAF_TEST_FAIL;
						e_print
						    (saHpiSensorThresholdsSet,
						     SA_OK, status);
					} else {
						retval = SAF_TEST_PASS;

						// restore thresholds

						status =
						    setThresholds(sessionId,
								  resourceId,
								  sensorRec,
								  &origThresholds.
								  LowMajor,
								  &origThresholds.
								  LowMinor,
								  &origThresholds.
								  UpMinor,
								  &origThresholds.
								  UpMajor);

						if (status != SA_OK) {
							e_print
							    (saHpiSensorThresholdsSet,
							     SA_OK, status);
						}
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
