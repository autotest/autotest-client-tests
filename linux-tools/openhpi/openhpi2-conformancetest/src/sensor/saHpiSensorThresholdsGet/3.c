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
 *     Wang Jing <jing.j.wang@intel.com>
 * 
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorThresholdsGet
 * Description:   
 *   Get the thresholds and verify that the thresholds are valid.
 *   The IsSupported field must correspond to ReadThold field in the
 *   RDR and the reading type cannot be SAHPI_SENSOR_READING_TYPE_BUFFER 
 *   as indicated in SaHpi.h, line 1060.
 *   Expected return: SA_OK
 * Line:        P81-16:P81-16
 */

#include <stdio.h>
#include <string.h>
#include "saf_test.h"

/**************************************************************************
 *
 * Is the threshold valid?
 *
 *     1) The type must match the Sensor RDR reading type.
 *     2) The type cannot be BUFFER or another invalid type.
 *     3) IsSupported must match the Sensor RDR ReadThold mask.
 *
 **************************************************************************/

SaHpiBoolT isThresholdValid(const SaHpiSensorRecT * sensorRec,
			    const SaHpiSensorReadingT * threshold,
			    SaHpiSensorThdMaskT thdMask)
{
	SaHpiBoolT valid = SAHPI_TRUE;

	if (threshold->IsSupported) {
		if (threshold->Type != sensorRec->DataFormat.ReadingType) {
			valid = SAHPI_FALSE;
			m_print
			    ("Threshold Type is not the same as the Sensor RDR Reading Type!");
		}

		if (threshold->Type >= SAHPI_SENSOR_READING_TYPE_BUFFER) {
			valid = SAHPI_FALSE;
			m_print("Threshold.LowCritical.Type invalid, %d",
				threshold->Type);
		}

		if (!(sensorRec->ThresholdDefn.ReadThold & thdMask)) {
			valid = SAHPI_FALSE;
			m_print
			    ("Returned thresholds mismatch those expected in RDR ReadThold field");
		}

	} else if (sensorRec->ThresholdDefn.ReadThold & thdMask) {
		valid = SAHPI_FALSE;
		m_print
		    ("Returned thresholds mismatch those expected in RDR ReadThold field");
	}

	return valid;
}

/**************************************************************************
 *
 * Is the hysteresis valid?  All hysteresis values must be zero or positive.
 *
 **************************************************************************/

SaHpiBoolT isHysteresisValid(const SaHpiSensorReadingT * hysteresis)
{
	SaHpiBoolT valid = SAHPI_TRUE;

	switch (hysteresis->Type) {

	case SAHPI_SENSOR_READING_TYPE_INT64:
		if (hysteresis->Value.SensorInt64 < 0) {
			valid = SAHPI_FALSE;
			m_print("Hysteresis value is negative!");
		}
		break;

	case SAHPI_SENSOR_READING_TYPE_UINT64:
		// unsigned can never be negative
		break;

	case SAHPI_SENSOR_READING_TYPE_FLOAT64:
		if (hysteresis->Value.SensorFloat64 < 0) {
			valid = SAHPI_FALSE;
			m_print("Hysteresis value is negative!");
		}
		break;

	case SAHPI_SENSOR_READING_TYPE_BUFFER:
		break;
	}

	return valid;
}

/**************************************************************************
 *
 * Is the highValue greater than or equal to the lowValue?
 *
 **************************************************************************/

SaHpiBoolT isGreaterThanOrEqual(SaHpiSensorReadingT * highValue,
				SaHpiSensorReadingT * lowValue)
{
	switch (highValue->Type) {

	case SAHPI_SENSOR_READING_TYPE_INT64:
		return (highValue->Value.SensorInt64 >=
			lowValue->Value.SensorInt64);

	case SAHPI_SENSOR_READING_TYPE_UINT64:
		return (highValue->Value.SensorUint64 >=
			lowValue->Value.SensorUint64);

	case SAHPI_SENSOR_READING_TYPE_FLOAT64:
		return (highValue->Value.SensorFloat64 >=
			lowValue->Value.SensorFloat64);

	case SAHPI_SENSOR_READING_TYPE_BUFFER:
		break;
	}

	return SAHPI_TRUE;
}

/**************************************************************************
 *
 * Are the threshold values in order?  For example, LowCritcal cannot
 * have a value greater than UpMinor.
 *
 **************************************************************************/

SaHpiBoolT isOrderValid(const SaHpiSensorThresholdsT * thresholds)
{
	int i;
	SaHpiSensorReadingT *value = NULL;
	SaHpiSensorReadingT *threshold[] = { &thresholds->LowCritical,
		&thresholds->LowMajor,
		&thresholds->LowMinor,
		&thresholds->UpMinor,
		&thresholds->UpMajor,
		&thresholds->UpCritical
	};

	for (i = 0; i < 6; i++) {
		if (threshold[i]->IsSupported) {
			if (value != NULL) {
				if (!isGreaterThanOrEqual(threshold[i], value)) {
					m_print
					    ("Threshold values are not in order!");
					return SAHPI_FALSE;
				}
			}
			value = threshold[i];
		}
	}

	return SAHPI_TRUE;
}

/*********************************************************************************
 *
 * Verify the Thresholds.
 *
 *********************************************************************************/

SaHpiBoolT areThresholdsValid(const SaHpiSensorRecT * sensorRec,
			      const SaHpiSensorThresholdsT * thresholds)
{
	SaHpiBoolT valid = SAHPI_TRUE;

	if (!isThresholdValid
	    (sensorRec, &thresholds->LowCritical, SAHPI_STM_LOW_CRIT)) {
		valid = SAHPI_FALSE;
	}

	if (!isThresholdValid
	    (sensorRec, &thresholds->LowMajor, SAHPI_STM_LOW_MAJOR)) {
		valid = SAHPI_FALSE;
	}

	if (!isThresholdValid
	    (sensorRec, &thresholds->LowMinor, SAHPI_STM_LOW_MINOR)) {
		valid = SAHPI_FALSE;
	}

	if (!isThresholdValid
	    (sensorRec, &thresholds->UpCritical, SAHPI_STM_UP_CRIT)) {
		valid = SAHPI_FALSE;
	}

	if (!isThresholdValid
	    (sensorRec, &thresholds->UpMajor, SAHPI_STM_UP_MAJOR)) {
		valid = SAHPI_FALSE;
	}

	if (!isThresholdValid
	    (sensorRec, &thresholds->UpMinor, SAHPI_STM_UP_MINOR)) {
		valid = SAHPI_FALSE;
	}

	if (!isThresholdValid
	    (sensorRec, &thresholds->PosThdHysteresis,
	     SAHPI_STM_UP_HYSTERESIS)) {
		valid = SAHPI_FALSE;
	}

	if (!isThresholdValid
	    (sensorRec, &thresholds->NegThdHysteresis,
	     SAHPI_STM_LOW_HYSTERESIS)) {
		valid = SAHPI_FALSE;
	}

	if (!isHysteresisValid(&thresholds->PosThdHysteresis)) {
		valid = SAHPI_FALSE;
	}

	if (!isHysteresisValid(&thresholds->NegThdHysteresis)) {
		valid = SAHPI_FALSE;
	}

	if (!isOrderValid(thresholds)) {
		valid = SAHPI_FALSE;
	}

	return valid;
}

/**************************************************************************
 *
 * Test the thresholds for a sensor.
 *
 **************************************************************************/

int Test_Rdr(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId,
	     SaHpiRdrT rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiSensorThresholdsT thresholds;
	SaHpiSensorRecT *sensorRec;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {

		sensorRec = &(rdr.RdrTypeUnion.SensorRec);

		if (sensorRec->ThresholdDefn.IsAccessible
		    && sensorRec->ThresholdDefn.ReadThold) {

			status = saHpiSensorThresholdsGet(sessionId, resourceId,
							  sensorRec->Num,
							  &thresholds);

			if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
				retval = SAF_TEST_NOTSUPPORT;
				m_print("sensor is not present.");
			} else if (status != SA_OK) {
				retval = SAF_TEST_FAIL;
				e_print(saHpiSensorThresholdsGet,
					SA_OK
					|| SA_ERR_HPI_ENTITY_NOT_PRESENT,
					status);
			} else if (areThresholdsValid(sensorRec, &thresholds)) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
			}
		}
	}

	return retval;
}

/**************************************************************************
 *
 * Test a resource.
 *
 **************************************************************************/

int Test_Resource(SaHpiSessionIdT sessionId,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_NOTSUPPORT;

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR) {
		retval = do_resource(sessionId, report, func);
	}

	return retval;
}

/**************************************************************************
 *
 * Main Program.
 *
 **************************************************************************/

int main()
{
	return process_all_domains(&Test_Resource, &Test_Rdr, NULL);
}
