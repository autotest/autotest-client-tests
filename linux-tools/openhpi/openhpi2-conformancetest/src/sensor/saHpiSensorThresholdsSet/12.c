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
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorThresholdsSet
 * Description:   
 *   Call function on a sensor which thresholds are set out of order.
 *   Expected return: SA_ERR_HPI_INVALID_DATA.
 * Line:        P82-29:P82-29
 */
#include <stdio.h>
#include "saf_test.h"

#define MAX_INT64 ((SaHpiInt64T) 0x7fffffff)

#define MAX_UINT64 ((SaHpiUint64T) 0xffffffff)

#define MAX_FLOAT64 ((SaHpiFloat64T) 1e+37)

/*************************************************************************************
 *
 * Can we do this test?  Must support thresholds.
 *
 *************************************************************************************/

SaHpiBoolT canTest(SaHpiSensorRecT * sensorRec)
{
	return (sensorRec->ThresholdDefn.IsAccessible) &&
	    (sensorRec->DataFormat.ReadingType !=
	     SAHPI_SENSOR_READING_TYPE_BUFFER);
}

/*************************************************************************************
 *
 * Get the maximum possible threshold value. 
 *
 *************************************************************************************/

SaHpiSensorReadingT getMaxThreshold(SaHpiSensorRecT * sensorRec)
{
	SaHpiSensorReadingT max;
	SaHpiBoolT hasMax = sensorRec->DataFormat.Range.Flags & SAHPI_SRF_MAX;
	SaHpiSensorReadingTypeT type = sensorRec->DataFormat.ReadingType;

	if (hasMax) {
		max = sensorRec->DataFormat.Range.Max;
	} else {

		max.Type = type;

		switch (type) {
		case SAHPI_SENSOR_READING_TYPE_INT64:
			max.Value.SensorInt64 = MAX_INT64;
			break;

		case SAHPI_SENSOR_READING_TYPE_UINT64:
			max.Value.SensorUint64 = MAX_UINT64;
			break;

		case SAHPI_SENSOR_READING_TYPE_FLOAT64:
			max.Value.SensorFloat64 = MAX_FLOAT64;
			break;

		case SAHPI_SENSOR_READING_TYPE_BUFFER:
			break;
		}
	}

	return max;
}

/*************************************************************************************
 *
 * Find a writable threshold.
 *
 *************************************************************************************/

SaHpiSensorThdMaskT findWritableLowThreshold(SaHpiSensorRecT * sensorRec)
{
	if (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_LOW_CRIT) {
		return SAHPI_STM_LOW_CRIT;
	} else if (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_LOW_MAJOR) {
		return SAHPI_STM_LOW_MAJOR;
	} else if (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_LOW_MINOR) {
		return SAHPI_STM_LOW_MINOR;
	} else if (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_UP_MINOR) {
		return SAHPI_STM_UP_MINOR;
	} else if (sensorRec->ThresholdDefn.WriteThold & SAHPI_STM_UP_MAJOR) {
		return SAHPI_STM_UP_MAJOR;
	} else {
		return 0x0;
	}
}

/*************************************************************************************
 *
 * If possible, find a readable threshold that is "higher" than the
 * selected "lowMask" threshold.
 *
 *************************************************************************************/

SaHpiSensorThdMaskT findReadableUpThreshold(SaHpiSensorRecT * sensorRec,
					    SaHpiSensorThdMaskT low)
{
	if (low & SAHPI_STM_LOW_CRIT) {
		if (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_LOW_MAJOR) {
			return SAHPI_STM_LOW_MAJOR;
		} else if (sensorRec->ThresholdDefn.
			   ReadThold & SAHPI_STM_LOW_MINOR) {
			return SAHPI_STM_LOW_MINOR;
		} else if (sensorRec->ThresholdDefn.
			   ReadThold & SAHPI_STM_UP_MINOR) {
			return SAHPI_STM_UP_MINOR;
		} else if (sensorRec->ThresholdDefn.
			   ReadThold & SAHPI_STM_UP_MAJOR) {
			return SAHPI_STM_UP_MAJOR;
		} else if (sensorRec->ThresholdDefn.
			   ReadThold & SAHPI_STM_UP_CRIT) {
			return SAHPI_STM_UP_CRIT;
		}
	} else if (low & SAHPI_STM_LOW_MAJOR) {
		if (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_LOW_MINOR) {
			return SAHPI_STM_LOW_MINOR;
		} else if (sensorRec->ThresholdDefn.
			   ReadThold & SAHPI_STM_UP_MINOR) {
			return SAHPI_STM_UP_MINOR;
		} else if (sensorRec->ThresholdDefn.
			   ReadThold & SAHPI_STM_UP_MAJOR) {
			return SAHPI_STM_UP_MAJOR;
		} else if (sensorRec->ThresholdDefn.
			   ReadThold & SAHPI_STM_UP_CRIT) {
			return SAHPI_STM_UP_CRIT;
		}
	} else if (low & SAHPI_STM_LOW_MINOR) {
		if (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_MINOR) {
			return SAHPI_STM_UP_MINOR;
		} else if (sensorRec->ThresholdDefn.
			   ReadThold & SAHPI_STM_UP_MAJOR) {
			return SAHPI_STM_UP_MAJOR;
		} else if (sensorRec->ThresholdDefn.
			   ReadThold & SAHPI_STM_UP_CRIT) {
			return SAHPI_STM_UP_CRIT;
		}
	} else if (low & SAHPI_STM_UP_MINOR) {
		if (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_MAJOR) {
			return SAHPI_STM_UP_MAJOR;
		} else if (sensorRec->ThresholdDefn.
			   ReadThold & SAHPI_STM_UP_CRIT) {
			return SAHPI_STM_UP_CRIT;
		}
	} else if (low & SAHPI_STM_UP_MAJOR) {
		if (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_CRIT) {
			return SAHPI_STM_UP_CRIT;
		}
	}

	return 0x0;
}

/*************************************************************************************
 *
 * From the given set of thresholds, return the individual threshold
 * corresponding to the "highMask".
 *
 *************************************************************************************/

SaHpiSensorReadingT *getThresholdValue(SaHpiSensorThresholdsT * thresholds,
				       SaHpiSensorThdMaskT highMask)
{
	if (highMask & SAHPI_STM_LOW_CRIT) {
		return &(thresholds->LowCritical);
	} else if (highMask & SAHPI_STM_LOW_MAJOR) {
		return &(thresholds->LowMajor);
	} else if (highMask & SAHPI_STM_LOW_MINOR) {
		return &(thresholds->LowMinor);
	} else if (highMask & SAHPI_STM_UP_MINOR) {
		return &(thresholds->UpMinor);
	} else if (highMask & SAHPI_STM_UP_MAJOR) {
		return &(thresholds->UpMajor);
	} else if (highMask & SAHPI_STM_UP_CRIT) {
		return &(thresholds->UpCritical);
	}
	return NULL;
}

/*************************************************************************************
 *
 * Is the given threshold value less than the given maximum threshold?
 *
 *************************************************************************************/

SaHpiBoolT lessThan(SaHpiSensorReadingTypeT type,
		    SaHpiSensorReadingT * threshold,
		    SaHpiSensorReadingT * maxThreshold)
{
	switch (type) {
	case SAHPI_SENSOR_READING_TYPE_INT64:
		return (threshold->Value.SensorInt64 <
			maxThreshold->Value.SensorInt64);

	case SAHPI_SENSOR_READING_TYPE_UINT64:
		return (threshold->Value.SensorUint64 <
			maxThreshold->Value.SensorUint64);

	case SAHPI_SENSOR_READING_TYPE_FLOAT64:
		return (threshold->Value.SensorFloat64 <
			maxThreshold->Value.SensorFloat64);

	case SAHPI_SENSOR_READING_TYPE_BUFFER:
		return SAHPI_FALSE;
	}

	return SAHPI_FALSE;
}

/*************************************************************************************
 *
 * For the given "lowMask", set the individual threshold in "thresholds"
 * to the given maximum threshold value.
 *
 *************************************************************************************/

void setThreshold(SaHpiSensorThdMaskT lowMask,
		  SaHpiSensorReadingT * maxThreshold,
		  SaHpiSensorThresholdsT * thresholds)
{
	if (lowMask & SAHPI_STM_LOW_CRIT) {
		thresholds->LowCritical.IsSupported = SAHPI_TRUE;
		thresholds->LowCritical.Value = maxThreshold->Value;
	} else if (lowMask & SAHPI_STM_LOW_MAJOR) {
		thresholds->LowMajor.IsSupported = SAHPI_TRUE;
		thresholds->LowMajor.Value = maxThreshold->Value;
	} else if (lowMask & SAHPI_STM_LOW_MINOR) {
		thresholds->LowMinor.IsSupported = SAHPI_TRUE;
		thresholds->LowMinor.Value = maxThreshold->Value;
	} else if (lowMask & SAHPI_STM_UP_MINOR) {
		thresholds->UpMinor.IsSupported = SAHPI_TRUE;
		thresholds->UpMinor.Value = maxThreshold->Value;
	} else if (lowMask & SAHPI_STM_UP_MAJOR) {
		thresholds->UpMajor.IsSupported = SAHPI_TRUE;
		thresholds->UpMajor.Value = maxThreshold->Value;
	} else if (lowMask & SAHPI_STM_UP_CRIT) {
		thresholds->UpCritical.IsSupported = SAHPI_TRUE;
		thresholds->UpCritical.Value = maxThreshold->Value;
	}
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
	SaHpiSensorThresholdsT thresholds;
	SaHpiSensorThresholdsT curThresholds;
	SaHpiSensorNumT s_num = 0;
	SaHpiSensorReadingTypeT type;
	SaHpiSensorRecT *sensorRec;
	SaHpiSensorReadingT *threshold;
	SaHpiSensorReadingT maxThreshold;
	SaHpiSensorThdMaskT lowMask, highMask;

	if (rdr.RdrType == SAHPI_SENSOR_RDR
	    && canTest(&rdr.RdrTypeUnion.SensorRec)) {

		sensorRec = &rdr.RdrTypeUnion.SensorRec;
		s_num = sensorRec->Num;
		type = sensorRec->DataFormat.ReadingType;

		lowMask = findWritableLowThreshold(sensorRec);
		if (lowMask != 0x0) {
			highMask = findReadableUpThreshold(sensorRec, lowMask);
			if (highMask != 0x0) {

				status =
				    saHpiSensorThresholdsGet(sessionId,
							     resourceId, s_num,
							     &curThresholds);

				if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
					retval = SAF_TEST_NOTSUPPORT;
					m_print("sensor is not present.");
				} else if (status != SA_OK) {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiSensorThresholdsGet, SA_OK,
						status);
				} else {

					threshold =
					    getThresholdValue(&curThresholds,
							      highMask);
					maxThreshold =
					    getMaxThreshold(sensorRec);

					// If the max possible threshold value is greater than
					// the current threshold for the selected "highMask" threshold,
					// then we can set the "lowMask" threshold.

					if (lessThan
					    (type, threshold, &maxThreshold)) {

						// We will only set the threshold for the
						// selected "lowMask" threshold.

						thresholds.LowCritical.
						    IsSupported = SAHPI_FALSE;
						thresholds.LowCritical.Type =
						    type;
						thresholds.LowMajor.
						    IsSupported = SAHPI_FALSE;
						thresholds.LowMajor.Type = type;
						thresholds.LowMinor.
						    IsSupported = SAHPI_FALSE;
						thresholds.LowMinor.Type = type;
						thresholds.UpCritical.
						    IsSupported = SAHPI_FALSE;
						thresholds.UpCritical.Type =
						    type;
						thresholds.UpMajor.IsSupported =
						    SAHPI_FALSE;
						thresholds.UpMajor.Type = type;
						thresholds.UpMinor.IsSupported =
						    SAHPI_FALSE;
						thresholds.UpMinor.Type = type;
						thresholds.PosThdHysteresis.
						    IsSupported = SAHPI_FALSE;
						thresholds.PosThdHysteresis.
						    Type = type;
						thresholds.NegThdHysteresis.
						    IsSupported = SAHPI_FALSE;
						thresholds.NegThdHysteresis.
						    Type = type;

						setThreshold(lowMask,
							     &maxThreshold,
							     &thresholds);

						status =
						    saHpiSensorThresholdsSet
						    (sessionId, resourceId,
						     s_num, &thresholds);

						if (status ==
						    SA_ERR_HPI_INVALID_DATA) {
							retval = SAF_TEST_PASS;
						} else if (status ==
							   SA_ERR_HPI_ENTITY_NOT_PRESENT)
						{
							retval =
							    SAF_TEST_NOTSUPPORT;
							m_print
							    ("sensor is not present.");
						} else {
							retval = SAF_TEST_FAIL;
							e_print
							    (saHpiSensorThresholdsSet,
							     SA_ERR_HPI_INVALID_DATA
							     ||
							     SA_ERR_HPI_ENTITY_NOT_PRESENT,
							     status);
						}
					}
				}
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
