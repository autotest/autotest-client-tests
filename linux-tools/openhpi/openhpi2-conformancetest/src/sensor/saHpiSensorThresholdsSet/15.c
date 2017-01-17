/*
 * (C) Copyright University of New Hampshire 2005
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
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorThresholdsSet
 * Description:   
 *   Verify that two or more thresholds can be set with one call.
 *   Expected return: SA_OK.
 * Line:        P82-16:P82-16
 */

#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define MIN_INT64 ((SaHpiInt64T) 0xffffffff)
#define MAX_INT64 ((SaHpiInt64T) 0x7fffffff)

#define MIN_UINT64 ((SaHpiUint64T) 0x0)
#define MAX_UINT64 ((SaHpiUint64T) 0xffffffff)

#define MIN_FLOAT64 ((SaHpiFloat64T) 1e-37)
#define MAX_FLOAT64 ((SaHpiFloat64T) 1e+37)

/********************************************************************************************
 *
 * Initialize a threshold structure.
 *
 ********************************************************************************************/

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

/********************************************************************************************
 *
 * Set the Writeable Low Thresholds to the minValue and 
 * the Writeable Up Thresholds to the maxValue.
 *
 ********************************************************************************************/

void setThresholds(SaHpiSensorThdMaskT mask,
		   SaHpiSensorReadingUnionT * minValue,
		   SaHpiSensorReadingUnionT * maxValue,
		   SaHpiSensorThresholdsT * thresholds)
{
	if (mask & SAHPI_STM_LOW_MINOR) {
		thresholds->LowMinor.IsSupported = SAHPI_TRUE;
		thresholds->LowMinor.Value = *minValue;
	}

	if (mask & SAHPI_STM_LOW_MAJOR) {
		thresholds->LowMajor.IsSupported = SAHPI_TRUE;
		thresholds->LowMajor.Value = *minValue;
	}

	if (mask & SAHPI_STM_LOW_CRIT) {
		thresholds->LowCritical.IsSupported = SAHPI_TRUE;
		thresholds->LowCritical.Value = *minValue;
	}

	if (mask & SAHPI_STM_UP_MINOR) {
		thresholds->UpMinor.IsSupported = SAHPI_TRUE;
		thresholds->UpMinor.Value = *maxValue;
	}

	if (mask & SAHPI_STM_UP_MAJOR) {
		thresholds->UpMajor.IsSupported = SAHPI_TRUE;
		thresholds->UpMajor.Value = *maxValue;
	}

	if (mask & SAHPI_STM_UP_CRIT) {
		thresholds->UpCritical.IsSupported = SAHPI_TRUE;
		thresholds->UpCritical.Value = *maxValue;
	}
}

/********************************************************************************************
 *
 * Does this sensor have two or more writeable thresholds?
 *
 ********************************************************************************************/

SaHpiBoolT hasTwoOrMoreThresholds(SaHpiSensorRecT * sensorRec)
{
	int cnt = 0;
	if (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_LOW_MINOR)
		cnt++;
	if (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_LOW_MAJOR)
		cnt++;
	if (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_LOW_CRIT)
		cnt++;
	if (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_UP_MINOR)
		cnt++;
	if (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_UP_MAJOR)
		cnt++;
	if (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_UP_CRIT)
		cnt++;
	return (cnt > 1);
}

/********************************************************************************************
 *
 * Can this test be done?
 *
 *    1) This must be a sensor RDR.
 *    2) The sensor must support thresholds.
 *    3) Has some thresholds that can be read and written to.
 *    4) It is not a BUFFER data type.
 *
 ********************************************************************************************/

SaHpiBoolT canTest(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId, SaHpiRdrT * rdr)
{
	SaHpiSensorRecT *sensorRec;

	if (rdr->RdrType == SAHPI_SENSOR_RDR) {
		sensorRec = &rdr->RdrTypeUnion.SensorRec;
		if (sensorRec->ThresholdDefn.IsAccessible) {
			if (sensorRec->DataFormat.ReadingType !=
			    SAHPI_SENSOR_READING_TYPE_BUFFER) {
				if (sensorRec->ThresholdDefn.ReadThold ==
				    sensorRec->ThresholdDefn.WriteThold) {
					if (hasTwoOrMoreThresholds(sensorRec)) {
						return SAHPI_TRUE;
					}
				}
			}
		}
	}

	return SAHPI_FALSE;
}

/********************************************************************************************
 *
 * Is there a max value for the sensor threshold?
 *
 ********************************************************************************************/

SaHpiBoolT hasMax(SaHpiSensorRecT * sensorRec)
{
	return sensorRec->DataFormat.Range.Flags & SAHPI_SRF_MAX;
}

/********************************************************************************************
 *
 * Get the maximum value for a threshold.
 *
 ********************************************************************************************/

SaHpiSensorReadingUnionT getMaxValue(SaHpiSensorRecT * sensorRec)
{
	SaHpiSensorReadingUnionT maxValue;

	if (sensorRec->DataFormat.Range.Flags & SAHPI_SRF_MAX) {
		return sensorRec->DataFormat.Range.Max.Value;
	} else {

		switch (sensorRec->DataFormat.ReadingType) {
		case SAHPI_SENSOR_READING_TYPE_INT64:
			maxValue.SensorInt64 = MAX_INT64;
			break;

		case SAHPI_SENSOR_READING_TYPE_UINT64:
			maxValue.SensorUint64 = MAX_UINT64;
			break;

		case SAHPI_SENSOR_READING_TYPE_FLOAT64:
			maxValue.SensorFloat64 = MAX_FLOAT64;
			break;

		case SAHPI_SENSOR_READING_TYPE_BUFFER:
			break;
		}

		return maxValue;
	}
}

/********************************************************************************************
 *
 * Get the minimum value for a threshold.
 *
 ********************************************************************************************/

SaHpiSensorReadingUnionT getMinValue(SaHpiSensorRecT * sensorRec)
{
	SaHpiSensorReadingUnionT minValue;

	if (sensorRec->DataFormat.Range.Flags & SAHPI_SRF_MIN) {
		return sensorRec->DataFormat.Range.Min.Value;
	} else {

		switch (sensorRec->DataFormat.ReadingType) {
		case SAHPI_SENSOR_READING_TYPE_INT64:
			minValue.SensorInt64 = MIN_INT64;
			break;

		case SAHPI_SENSOR_READING_TYPE_UINT64:
			minValue.SensorUint64 = MIN_UINT64;
			break;

		case SAHPI_SENSOR_READING_TYPE_FLOAT64:
			minValue.SensorFloat64 = MIN_FLOAT64;
			break;

		case SAHPI_SENSOR_READING_TYPE_BUFFER:
			break;
		}

		return minValue;
	}
}

/********************************************************************************************
 *
 * Are the two booleans the same?
 *
 ********************************************************************************************/

SaHpiBoolT sameBool(SaHpiBoolT b1, SaHpiBoolT b2)
{
	if (b1 && b2)
		return SAHPI_TRUE;
	if (!b1 && !b2)
		return SAHPI_TRUE;
	return SAHPI_FALSE;
}

/********************************************************************************************
 *
 * Are the threshold values the same or not?
 *
 ********************************************************************************************/

SaHpiBoolT sameThresholdValue(SaHpiSensorReadingTypeT type,
			      SaHpiSensorReadingUnionT * r1,
			      SaHpiSensorReadingUnionT * r2)
{
	switch (type) {
	case SAHPI_SENSOR_READING_TYPE_INT64:
		return r1->SensorInt64 == r2->SensorInt64;

	case SAHPI_SENSOR_READING_TYPE_UINT64:
		return r1->SensorUint64 == r2->SensorUint64;

	case SAHPI_SENSOR_READING_TYPE_FLOAT64:
		return r1->SensorFloat64 == r2->SensorFloat64;

	case SAHPI_SENSOR_READING_TYPE_BUFFER:
		return SAHPI_FALSE;
	}

	return SAHPI_FALSE;
}

/********************************************************************************************
 *
 * Are the two sensor threshold values the same or not?
 *
 ********************************************************************************************/

SaHpiBoolT sameThreshold(SaHpiSensorReadingT * r1, SaHpiSensorReadingT * r2)
{
	if (!sameBool(r1->IsSupported, r2->IsSupported)) {
		return SAHPI_FALSE;
	} else if (r1->IsSupported && r2->IsSupported) {
		if (!sameThresholdValue(r1->Type, &(r1->Value), &(r2->Value))) {
			return SAHPI_FALSE;
		}
	}
	return SAHPI_TRUE;
}

/********************************************************************************************
 *
 * Are the two sets of thresholds the same or not?
 *
 ********************************************************************************************/

SaHpiBoolT sameThresholds(SaHpiSensorThresholdsT * t1,
			  SaHpiSensorThresholdsT * t2)
{
	if (!sameThreshold(&(t1->LowMinor), &(t2->LowMinor))) {
		return SAHPI_FALSE;
	}

	if (!sameThreshold(&(t1->LowMajor), &(t2->LowMajor))) {
		return SAHPI_FALSE;
	}

	if (!sameThreshold(&(t1->LowCritical), &(t2->LowCritical))) {
		return SAHPI_FALSE;
	}

	if (!sameThreshold(&(t1->UpMinor), &(t2->UpMinor))) {
		return SAHPI_FALSE;
	}

	if (!sameThreshold(&(t1->UpMajor), &(t2->UpMajor))) {
		return SAHPI_FALSE;
	}

	if (!sameThreshold(&(t1->UpCritical), &(t2->UpCritical))) {
		return SAHPI_FALSE;
	}

	return SAHPI_TRUE;
}

/********************************************************************************************
 *
 * Test a Sensor RDR. 
 *
 * Use the Up Critical so that we don't mistakenly get an out-of-order error.
 *
 ********************************************************************************************/

int Test_Rdr(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId, SaHpiRdrT rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiSensorRecT *sensorRec;
	SaHpiSensorThresholdsT old_thresholds;
	SaHpiSensorThresholdsT new_thresholds;
	SaHpiSensorThresholdsT thresholds;
	SaHpiSensorReadingTypeT type;
	SaHpiSensorReadingUnionT minValue;
	SaHpiSensorReadingUnionT maxValue;

	if (canTest(sessionId, resourceId, &rdr)) {

		sensorRec = &rdr.RdrTypeUnion.SensorRec;
		type = sensorRec->DataFormat.ReadingType;

		status = saHpiSensorThresholdsGet(sessionId, resourceId,
						  sensorRec->Num,
						  &old_thresholds);

		if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
			retval = SAF_TEST_NOTSUPPORT;
		} else if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiSensorThresholdsGet, SA_OK, status);
		} else {

			minValue = getMinValue(sensorRec);
			maxValue = getMaxValue(sensorRec);

			initThresholds(&new_thresholds, type);
			setThresholds(sensorRec->ThresholdDefn.WriteThold,
				      &minValue, &maxValue, &new_thresholds);

			status = saHpiSensorThresholdsSet(sessionId, resourceId,
							  sensorRec->Num,
							  &new_thresholds);

			if (status != SA_OK) {
				retval = SAF_TEST_FAIL;
				e_print(saHpiSensorThresholdsSet, SA_OK,
					status);
			} else {

				status =
				    saHpiSensorThresholdsGet(sessionId,
							     resourceId,
							     sensorRec->Num,
							     &thresholds);
				if (status != SA_OK) {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiSensorThresholdsGet, SA_OK,
						status);
				} else
				    if (!sameThresholds
					(&thresholds, &new_thresholds)) {
					retval = SAF_TEST_FAIL;
					m_print
					    ("Threshold values were not changed!");
				} else {
					retval = SAF_TEST_PASS;
				}

				status =
				    saHpiSensorThresholdsSet(sessionId,
							     resourceId,
							     sensorRec->Num,
							     &old_thresholds);
				if (status != SA_OK) {
					e_print(saHpiSensorThresholdsSet, SA_OK,
						status);
				}
			}
		}
	}

	return retval;
}

/********************************************************************************************
 *
 * Test a resource if it supports sensors.
 *
 ********************************************************************************************/

int Test_Resource(SaHpiSessionIdT sessionId,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_NOTSUPPORT;

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR) {
		retval = do_resource(sessionId, report, func);
	}

	return retval;
}

/********************************************************************************************
 *
 * Main Program
 *
 ********************************************************************************************/

int main(int argc, char **argv)
{
	return process_all_domains(Test_Resource, Test_Rdr, NULL);
}
