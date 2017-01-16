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
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *     Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorThresholdsSet
 * Description:   
 *   Call saHpiSensorThresholdsSet with valid threshold at the edge of
 *   one range value
 *   Expected return: SA_OK
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
			if (sensorRec->ThresholdDefn.ReadThold
			    && sensorRec->ThresholdDefn.WriteThold) {
				if (sensorRec->DataFormat.ReadingType !=
				    SAHPI_SENSOR_READING_TYPE_BUFFER) {
					return SAHPI_TRUE;
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
 * Does this sensor support a given threshold?
 *
 ********************************************************************************************/

SaHpiBoolT hasWriteThreshold(SaHpiSensorRecT * sensorRec,
			     SaHpiSensorThdMaskT mask)
{
	return sensorRec->ThresholdDefn.WriteThold & mask;
}

/********************************************************************************************
 *
 * Does this sensor support a given threshold?
 *
 ********************************************************************************************/

SaHpiBoolT hasReadThreshold(SaHpiSensorRecT * sensorRec,
			    SaHpiSensorThdMaskT mask)
{
	return sensorRec->ThresholdDefn.ReadThold & mask;
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
 * Are the two sensor reading values the same?
 *
 ********************************************************************************************/

SaHpiBoolT sameValue(SaHpiSensorReadingT * x, SaHpiSensorReadingT * y)
{
	if (x->Type == y->Type) {
		switch (x->Type) {
		case SAHPI_SENSOR_READING_TYPE_INT64:
			return x->Value.SensorInt64 == y->Value.SensorInt64;
		case SAHPI_SENSOR_READING_TYPE_UINT64:
			return x->Value.SensorUint64 == y->Value.SensorUint64;
		case SAHPI_SENSOR_READING_TYPE_FLOAT64:
			return x->Value.SensorFloat64 == y->Value.SensorFloat64;
		case SAHPI_SENSOR_READING_TYPE_BUFFER:
			return SAHPI_FALSE;
		}
	}

	return SAHPI_FALSE;
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
	SaHpiSensorThresholdsT old_threshold;
	SaHpiSensorThresholdsT new_threshold;
	SaHpiSensorThresholdsT threshold;
	SaHpiSensorReadingTypeT type;
	SaHpiSensorReadingUnionT maxValue;

	if (canTest(sessionId, resourceId, &rdr)) {

		sensorRec = &rdr.RdrTypeUnion.SensorRec;
		type = sensorRec->DataFormat.ReadingType;

		if ((hasMax(sensorRec)) &&
		    (hasReadThreshold(sensorRec, SAHPI_STM_LOW_CRIT)) &&
		    (hasReadThreshold(sensorRec, SAHPI_STM_UP_CRIT)) &&
		    (hasWriteThreshold(sensorRec, SAHPI_STM_UP_CRIT))) {

			status = saHpiSensorThresholdsGet(sessionId, resourceId,
							  sensorRec->Num,
							  &old_threshold);
			if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiSensorThresholdsGet, SA_OK,
					status);
			} else {

				maxValue = getMaxValue(sensorRec);

				initThresholds(&new_threshold, type);

				new_threshold.UpCritical.IsSupported =
				    SAHPI_TRUE;
				new_threshold.UpCritical.Value = maxValue;

				// The low critical threshold should be ignored by
				// the implementation.

				new_threshold.LowCritical.IsSupported =
				    SAHPI_FALSE;
				new_threshold.LowCritical.Value =
				    getMinValue(sensorRec);

				status =
				    saHpiSensorThresholdsSet(sessionId,
							     resourceId,
							     sensorRec->Num,
							     &new_threshold);

				if (status != SA_OK) {
					retval = SAF_TEST_FAIL;
					e_print(saHpiSensorThresholdsSet, SA_OK,
						status);
				} else {

					status =
					    saHpiSensorThresholdsGet(sessionId,
								     resourceId,
								     sensorRec->
								     Num,
								     &threshold);
					if (status != SA_OK) {
						retval = SAF_TEST_UNRESOLVED;
						e_print
						    (saHpiSensorThresholdsGet,
						     SA_OK, status);
					} else
					    if (!sameValue
						(&threshold.UpCritical,
						 &new_threshold.UpCritical)) {
						retval = SAF_TEST_FAIL;
						m_print
						    ("UpCritical Threshold was not set!");
					} else
					    if (!sameValue
						(&threshold.LowCritical,
						 &old_threshold.LowCritical)) {
						retval = SAF_TEST_FAIL;
						m_print
						    ("LowCritical Threshold was incorrectly changed!");
					} else {
						retval = SAF_TEST_PASS;
					}
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
