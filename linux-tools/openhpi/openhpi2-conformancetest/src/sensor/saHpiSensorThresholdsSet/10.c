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
 *      Qun Li <qun.li@intel.com>
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorThresholdsSet
 * Description:   
 *   Set the critical upper threshold to an out-of-range value.
 *   Expected return: SA_ERR_HPI_INVALID_CMD.
 * Line:        P82-26:P82-27
 */

#include <stdio.h>
#include "saf_test.h"

#define MAX_INT64 ((SaHpiInt64T) 0x7fffffff)

#define MAX_UINT64 ((SaHpiUint64T) 0xffffffff)

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
 *    3) Has some thresholds that can be written to.
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
				if (sensorRec->ThresholdDefn.WriteThold) {
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
 * Get the maximum value for a threshold.
 *
 ********************************************************************************************/

SaHpiSensorReadingUnionT getMaxValue(SaHpiSensorRecT * sensorRec)
{
	return sensorRec->DataFormat.Range.Max.Value;
}

/********************************************************************************************
 *
 * Is it possible to get an overflow?  An overflow can only occur if
 * the max value is also the largest value possible for the data type.
 *
 ********************************************************************************************/

SaHpiBoolT isOverflow(SaHpiSensorReadingUnionT value,
		      SaHpiSensorReadingTypeT type)
{
	switch (type) {
	case SAHPI_SENSOR_READING_TYPE_INT64:
		return (value.SensorInt64 == MAX_INT64);

	case SAHPI_SENSOR_READING_TYPE_UINT64:
		return (value.SensorUint64 == MAX_UINT64);

	case SAHPI_SENSOR_READING_TYPE_FLOAT64:
		return (value.SensorFloat64 == MAX_FLOAT64);

	case SAHPI_SENSOR_READING_TYPE_BUFFER:
		return SAHPI_TRUE;
	}

	return SAHPI_TRUE;
}

/********************************************************************************************
 *
 * Increase the given value by a small amount.
 *
 ********************************************************************************************/

SaHpiSensorReadingUnionT increaseValue(SaHpiSensorReadingUnionT value,
				       SaHpiSensorReadingTypeT type)
{
	SaHpiSensorReadingUnionT newValue;

	switch (type) {
	case SAHPI_SENSOR_READING_TYPE_INT64:
		newValue.SensorInt64 = value.SensorInt64 + 1;
		break;

	case SAHPI_SENSOR_READING_TYPE_UINT64:
		newValue.SensorUint64 = value.SensorUint64 + 1;
		break;

	case SAHPI_SENSOR_READING_TYPE_FLOAT64:
		newValue.SensorFloat64 = value.SensorFloat64 + 0.1;
		break;

	case SAHPI_SENSOR_READING_TYPE_BUFFER:
		break;
	}

	return newValue;
}

/********************************************************************************************
 *
 * Test a Sensor RDR. 
 *
 * Use Up and Low Critical so that we don't mistakenly get an out-of-order error instead
 * the max range error that we are seeking.
 *
 ********************************************************************************************/

int Test_Rdr(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId, SaHpiRdrT rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiSensorRecT *sensorRec;
	SaHpiSensorThresholdsT threshold;
	SaHpiSensorReadingTypeT type;
	SaHpiSensorReadingUnionT maxValue;

	if (canTest(sessionId, resourceId, &rdr)) {

		sensorRec = &rdr.RdrTypeUnion.SensorRec;
		type = sensorRec->DataFormat.ReadingType;

		if (hasMax(sensorRec)) {

			maxValue = getMaxValue(sensorRec);
			if (!isOverflow(maxValue, type)) {

				if (hasWriteThreshold
				    (sensorRec, SAHPI_STM_UP_CRIT)) {

					initThresholds(&threshold, type);

					threshold.UpCritical.IsSupported =
					    SAHPI_TRUE;
					threshold.UpCritical.Value =
					    increaseValue(maxValue, type);

					status =
					    saHpiSensorThresholdsSet(sessionId,
								     resourceId,
								     sensorRec->
								     Num,
								     &threshold);

					if (status == SA_ERR_HPI_INVALID_CMD) {
						retval = SAF_TEST_PASS;
					} else {
						retval = SAF_TEST_FAIL;
						e_print
						    (saHpiSensorThresholdsSet,
						     SA_ERR_HPI_INVALID_CMD,
						     status);
					}
				} else
				    if (hasWriteThreshold
					(sensorRec, SAHPI_STM_UP_MAJOR)) {

					initThresholds(&threshold, type);

					threshold.UpMajor.IsSupported =
					    SAHPI_TRUE;
					threshold.UpMajor.Value =
					    increaseValue(maxValue, type);

					status =
					    saHpiSensorThresholdsSet(sessionId,
								     resourceId,
								     sensorRec->
								     Num,
								     &threshold);

					if (status == SA_ERR_HPI_INVALID_CMD) {
						retval = SAF_TEST_PASS;
					} else {
						retval = SAF_TEST_FAIL;
						e_print
						    (saHpiSensorThresholdsSet,
						     SA_ERR_HPI_INVALID_CMD,
						     status);
					}
				} else
				    if (hasWriteThreshold
					(sensorRec, SAHPI_STM_UP_MINOR)) {

					initThresholds(&threshold, type);

					threshold.UpMinor.IsSupported =
					    SAHPI_TRUE;
					threshold.UpMinor.Value =
					    increaseValue(maxValue, type);

					status =
					    saHpiSensorThresholdsSet(sessionId,
								     resourceId,
								     sensorRec->
								     Num,
								     &threshold);

					if (status == SA_ERR_HPI_INVALID_CMD) {
						retval = SAF_TEST_PASS;
					} else {
						retval = SAF_TEST_FAIL;
						e_print
						    (saHpiSensorThresholdsSet,
						     SA_ERR_HPI_INVALID_CMD,
						     status);
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
