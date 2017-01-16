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
 *     Xiaowei Yang <xiaowei.yang@intel.com>
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorEventMasksGet
 * Description:   
 *   Set event enable status enable, change the thresholds to min value
 *   then set them to old values.
 *   Check deasserted events will be generated.
 * Line:        P89-31:P89-32
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define MAX_SENSORS 2000
#define POLL_COUNT 10  // poll for events after every "n" sensors

static int sensorCount;

typedef struct {
    SaHpiResourceIdT resourceId;
    SaHpiSensorNumT sensorNum;
    SaHpiSensorThresholdsT thresholds;
    SaHpiBoolT assert;
    SaHpiBoolT deassert;
    SaHpiBoolT restoreMasks;
    SaHpiEventStateT assertEventMask;
    SaHpiEventStateT deassertEventMask;
    SaHpiBoolT origEventEnable;
} SensorData;

static SensorData sensorData[MAX_SENSORS];

/**********************************************************************************
 *
 * Restore Sensors
 *
 **********************************************************************************/

void restoreSensors(SaHpiSessionIdT sessionId) {
    int       i;
    SaErrorT  status;

    for (i = 0; i < sensorCount; i++) {
            status = saHpiSensorThresholdsSet(sessionId, 
                                              sensorData[i].resourceId,
                                              sensorData[i].sensorNum,
                                              &sensorData[i].thresholds);
            if (status != SA_OK) {
                    e_print(saHpiSensorThresholdsSet, SA_OK, status);
            }
                        

           if (sensorData[i].restoreMasks) {
                // restore event masks
                if (!(sensorData[i].assertEventMask & SAHPI_ES_UPPER_MINOR)) {
                        status = saHpiSensorEventMasksSet(sessionId, sensorData[i].resourceId,
                                                          sensorData[i].sensorNum,
                                                          SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
                                                          SAHPI_ES_UPPER_MINOR, 0x0);
                        if (status != SA_OK) {
                                e_print(saHpiSensorEventMasksSet, SA_OK, status);
                        }
                }

                if (!(sensorData[i].deassertEventMask & SAHPI_ES_UPPER_MINOR)) {
                        status = saHpiSensorEventMasksSet(sessionId, sensorData[i].resourceId,
                                                          sensorData[i].sensorNum,
                                                          SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
                                                          0x0, SAHPI_ES_UPPER_MINOR);
                        if (status != SA_OK) {
                                e_print(saHpiSensorEventMasksSet, SA_OK, status);
                        }
                }
           }
                        
           if (sensorData[i].origEventEnable == SAHPI_FALSE) {
                // restore EventEnabled state
                status =
                    saHpiSensorEventEnableSet(sessionId,
                                              sensorData[i].resourceId,
                                              sensorData[i].sensorNum,
                                              SAHPI_FALSE);
                if (status != SA_OK) {
                        e_print(saHpiSensorEventEnableSet, SA_OK, status);
                }
           }
        }
}

int verifyEvents() {
    int i;
    int retval = SAF_TEST_PASS;

    for (i = 0; i < sensorCount; i++) {
            if (!sensorData[i].assert) {
                retval = SAF_TEST_FAIL;
                m_print("Resource %d; sensor %d did not assert an UpMinor threshold event!",
                        sensorData[i].resourceId, sensorData[i].sensorNum);
            } else if (!sensorData[i].deassert) {
                retval = SAF_TEST_FAIL;
                m_print("Resource %d; sensor %d did not deassert an UpMinor threshold event!",
                        sensorData[i].resourceId, sensorData[i].sensorNum);
            }
    }

    return retval;
}

/********************************************************************************************
 *
 * Determine if the current reading of the sensor is between the Lower and Upper
 * Minor Threshold values.  In order to generate threshold events, the value must
 * be within a valid range.  By changing the UpMinor Threshold we can generate an event.
 *
 * We must also consider Hysteresis.  In other words, if Pos and Neg Hysteresis are 
 * supported, the reading must meet the following requirement:
 *
 *               (LowMinor + NegHysteresis) < value < (UpMinor - PosHysteresis)
 *
 * The reason for this is that we don't want to use a sensor that is currently asserted
 * because it crossed a threshold but hasn't yet been deasserted due to hysteresis.
 *
 ********************************************************************************************/

int isReadingWithinMinorLimits(SaHpiSessionIdT sessionId,
                               SaHpiResourceIdT resourceId,
                               SaHpiSensorRecT * sensorRec)
{
        SaErrorT status;
        int retval = SAF_TEST_NOTSUPPORT;
        SaHpiSensorReadingT reading;
        SaHpiSensorThresholdsT thresholds;
        SaHpiBoolT isWithin;
        SaHpiSensorReadingT low, high;

        status = saHpiSensorReadingGet(sessionId, resourceId,
                                       sensorRec->Num, &reading, NULL);
        if (status != SA_OK) {
                retval = SAF_TEST_UNRESOLVED;
                e_print(saHpiSensorReadingGet, SA_OK, status);
        } else {
                status = saHpiSensorThresholdsGet(sessionId, resourceId,
                                                  sensorRec->Num, &thresholds);
                if (status != SA_OK) {
                        retval = SAF_TEST_UNRESOLVED;
                        e_print(saHpiSensorThresholdsGet, SA_OK, status);
                } else {
                        switch (reading.Type) {
                        case SAHPI_SENSOR_READING_TYPE_INT64:
                                low.Value.SensorInt64 =
                                    thresholds.LowMinor.Value.SensorInt64;
                                if (thresholds.NegThdHysteresis.IsSupported) {
                                        low.Value.SensorInt64 +=
                                            thresholds.NegThdHysteresis.Value.
                                            SensorInt64;
                                }

                                high.Value.SensorInt64 =
                                    thresholds.UpMinor.Value.SensorInt64;
                                if (thresholds.PosThdHysteresis.IsSupported) {
                                        high.Value.SensorInt64 -=
                                            thresholds.PosThdHysteresis.Value.
                                            SensorInt64;
                                }

                                isWithin =
                                    (reading.Value.SensorInt64 >
                                     low.Value.SensorInt64)
                                    && (reading.Value.SensorInt64 <
                                        high.Value.SensorInt64);
                                break;

                        case SAHPI_SENSOR_READING_TYPE_UINT64:
                                low.Value.SensorUint64 =
                                    thresholds.LowMinor.Value.SensorUint64;
                                if (thresholds.NegThdHysteresis.IsSupported) {
                                        low.Value.SensorUint64 +=
                                            thresholds.NegThdHysteresis.Value.
                                            SensorUint64;
                                }

                                high.Value.SensorUint64 =
                                    thresholds.UpMinor.Value.SensorUint64;
                                if (thresholds.PosThdHysteresis.IsSupported) {
                                        high.Value.SensorUint64 -=
                                            thresholds.PosThdHysteresis.Value.
                                            SensorUint64;
                                }

                                isWithin =
                                    (reading.Value.SensorUint64 >
                                     low.Value.SensorUint64)
                                    && (reading.Value.SensorUint64 <
                                        high.Value.SensorUint64);
                                break;

                        case SAHPI_SENSOR_READING_TYPE_FLOAT64:
                                low.Value.SensorFloat64 =
                                    thresholds.LowMinor.Value.SensorFloat64;
                                if (thresholds.NegThdHysteresis.IsSupported) {
                                        low.Value.SensorFloat64 +=
                                            thresholds.NegThdHysteresis.Value.
                                            SensorFloat64;
                                }

                                high.Value.SensorFloat64 =
                                    thresholds.UpMinor.Value.SensorFloat64;
                                if (thresholds.PosThdHysteresis.IsSupported) {
                                        high.Value.SensorFloat64 -=
                                            thresholds.PosThdHysteresis.Value.
                                            SensorFloat64;
                                }

                                isWithin =
                                    (reading.Value.SensorFloat64 >
                                     low.Value.SensorFloat64)
                                    && (reading.Value.SensorFloat64 <
                                        high.Value.SensorFloat64);
                                break;

                        case SAHPI_SENSOR_READING_TYPE_BUFFER:
                                isWithin = SAHPI_FALSE;
                                break;

                        }

                        if (isWithin) {
                                retval = SAF_TEST_PASS;
                        }
                }
        }

        return retval;
}

/********************************************************************************************
 *
 * Can this RDR be tested?  It meet the following requirements:
 *
 *     1) It must be a Sensor RDR.
 *     2) It must have thresholds.
 *     3) It must support the SAHPI_ES_UPPER_MINOR event.
 *     4) We must be able to read the current LOW and UP MINOR threshold values.
 *     5) We must be able to change the UP MINOR threshold value.
 *     6) The sensor must be enabled.
 *     7) The current sensor value must be between the lower and upper minor threshold values.
 *
 ********************************************************************************************/

int canTest(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId,
            SaHpiRdrT * rdr)
{
        SaErrorT status;
        int retval = SAF_TEST_NOTSUPPORT;
        SaHpiSensorRecT *sensorRec;
        SaHpiBoolT sensorEnabled;

        if (rdr->RdrType == SAHPI_SENSOR_RDR) {
                sensorRec = &rdr->RdrTypeUnion.SensorRec;

                if ((sensorCount < MAX_SENSORS) &&
                        (sensorRec->ThresholdDefn.IsAccessible) &&
                    (sensorRec->Events & SAHPI_ES_UPPER_MINOR) &&
                    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_LOW_MINOR)
                    && (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_MINOR)
                    && (sensorRec->ThresholdDefn.
                        WriteThold & SAHPI_STM_UP_MINOR)) {

                        status = saHpiSensorEnableGet(sessionId, resourceId,
                                                      sensorRec->Num,
                                                      &sensorEnabled);
                        if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
                                retval = SAF_TEST_NOTSUPPORT;
                        } else if (status != SA_OK) {
                                retval = SAF_TEST_UNRESOLVED;
                                e_print(saHpiSensorEnableGet, SA_OK, status);
                        } else if (sensorEnabled) {
                                retval =
                                    isReadingWithinMinorLimits(sessionId,
                                                               resourceId,
                                                               sensorRec);
                        }
                }
        }

        return retval;
}

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
 * Set the UP MINOR threshold value.
 *
 ********************************************************************************************/

SaErrorT setUpMinorThreshold(SaHpiSessionIdT sessionId,
                             SaHpiResourceIdT resourceId,
                             SaHpiSensorRecT * sensorRec,
                             SaHpiSensorReadingUnionT upMinorValue)
{
        SaErrorT status;
        SaHpiSensorThresholdsT thresholds;

        initThresholds(&thresholds, sensorRec->DataFormat.ReadingType);

        thresholds.UpMinor.IsSupported = SAHPI_TRUE;
        thresholds.UpMinor.Value = upMinorValue;

        status =
            saHpiSensorThresholdsSet(sessionId, resourceId, sensorRec->Num,
                                     &thresholds);
        if (status != SA_OK) {
                e_print(saHpiSensorThresholdsSet, SA_OK, status);
        }

        return status;
}

/********************************************************************************************
 *
 * Determine if two boolean values are the same.  Keep in mind that any positive value
 * is considered to be true.
 *
 ********************************************************************************************/

SaHpiBoolT boolean_equals(SaHpiBoolT b1, SaHpiBoolT b2)
{
        if (b1 && b2)
                return SAHPI_TRUE;

        if (!b1 && !b2)
                return SAHPI_TRUE;

        return SAHPI_FALSE;
}

/**********************************************************************************
 *
 * Check for any events that may have been mistakenly generated by the sensors.
 *
 **********************************************************************************/

int checkForEvents(SaHpiSessionIdT sessionId)
{
    int i;
    int retval = SAF_TEST_PASS;
    SaErrorT status;
    SaHpiEventT event;
    SaHpiSensorNumT sensorNum;
    SaHpiBoolT assertion;

    while (SAHPI_TRUE && retval == SAF_TEST_PASS) {
         status = saHpiEventGet(sessionId, SAHPI_TIMEOUT_IMMEDIATE, &event, NULL, NULL, NULL);
         if (status == SA_ERR_HPI_TIMEOUT) {
              break;
         } else if (status != SA_OK) {
              retval = SAF_TEST_UNRESOLVED;
              e_print(saHpiEventGet, SA_OK, status);
              break;
         } else if ((event.EventType == SAHPI_ET_SENSOR) &&
                    (event.EventDataUnion.SensorEvent.EventState == SAHPI_ES_UPPER_MINOR)) {

              assertion = event.EventDataUnion.SensorEvent.Assertion;
              sensorNum = event.EventDataUnion.SensorEvent.SensorNum;
              for (i = 0; i < sensorCount; i++) {
                  if ((sensorData[i].resourceId == event.Source) &&
                      (sensorData[i].sensorNum == sensorNum)) {

                          if (assertion) {
                                  sensorData[i].assert = SAHPI_TRUE;
                                  // restore threshold which should kick off a deassert event
                                  status = saHpiSensorThresholdsSet(sessionId, 
                                                                    sensorData[i].resourceId,
                                                                    sensorData[i].sensorNum,
                                                                    &sensorData[i].thresholds);
                                  if (status != SA_OK) {
                                          e_print(saHpiSensorThresholdsSet, SA_OK, status);
                                          retval = SAF_TEST_UNRESOLVED;
                                  }
                          } else {
                                  sensorData[i].deassert = SAHPI_TRUE;
                          }
                          break;
                  }
              }
         }
    }

    return retval;
}

/********************************************************************************************
 *
 * Generate assert events for a sensor.  The assert event is generated by
 * changing the Up Minor threshold value to be the same as the Low Minor threshold value.
 * This will cause the current sensor reading to be above the Up Minor value, thus causing
 * an assert event.
 *
 ********************************************************************************************/

int generateAssertEvents(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId,
                                 SaHpiSensorRecT * sensorRec)
{
        SaErrorT status;
        int retval;
        SaHpiSensorThresholdsT old_thresholds;
        SaHpiSensorThresholdsT thresholds;

        status = saHpiSensorThresholdsGet(sessionId, resourceId,
                                          sensorRec->Num, &old_thresholds);
        if (status != SA_OK) {
                retval = SAF_TEST_UNRESOLVED;
                e_print(saHpiSensorThresholdsGet, SA_OK, status);
        } else {
                status = setUpMinorThreshold(sessionId, resourceId, sensorRec,
                                             old_thresholds.LowMinor.Value);
                if (status != SA_OK) {
                        retval = SAF_TEST_UNRESOLVED;
                } else {
                        retval = SAF_TEST_PASS;
                        initThresholds(&thresholds, sensorRec->DataFormat.ReadingType);
                        thresholds.UpMinor.IsSupported = SAHPI_TRUE;
                        thresholds.UpMinor.Value = old_thresholds.UpMinor.Value;

                        sensorData[sensorCount].resourceId = resourceId;
                        sensorData[sensorCount].sensorNum = sensorRec->Num;
                        sensorData[sensorCount].thresholds = thresholds;
                        sensorData[sensorCount].assert = SAHPI_FALSE;
                        sensorData[sensorCount].deassert = SAHPI_FALSE;
                        sensorData[sensorCount].restoreMasks = SAHPI_FALSE;
                        sensorData[sensorCount].origEventEnable = SAHPI_TRUE;
                        sensorCount++;
                }
        }

        return retval;
}

/********************************************************************************************
 *
 * This function will first determine if the SAHPI_ES_UPPER_MINOR can be asserted and
 * deasserted.  If so, the events will be generated.  If not, this function will attempt,
 * if possible, to change the Event Masks so that ES_UPPER_MINOR can be asserted/deasserted.
 *
 ********************************************************************************************/

int run_test(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId,
             SaHpiSensorRecT * sensorRec)
{
        SaErrorT status;
        int retval;
        SaHpiEventStateT assertEventMask;
        SaHpiEventStateT deassertEventMask;

        status = saHpiSensorEventMasksGet(sessionId, resourceId, sensorRec->Num,
                                          &assertEventMask, &deassertEventMask);

        if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
                retval = SAF_TEST_NOTSUPPORT;
        } else if (status != SA_OK) {
                retval = SAF_TEST_UNRESOLVED;
                e_print(saHpiSensorEnableGet, SA_OK, status);
        } else if (assertEventMask & SAHPI_ES_UPPER_MINOR
                   && deassertEventMask & SAHPI_ES_UPPER_MINOR) {
                retval = generateAssertEvents(sessionId, resourceId, sensorRec);
        } else if (sensorRec->EventCtrl == SAHPI_SEC_PER_EVENT) {

                status =
                    saHpiSensorEventMasksSet(sessionId, resourceId,
                                             sensorRec->Num,
                                             SAHPI_SENS_ADD_EVENTS_TO_MASKS,
                                             SAHPI_ES_UPPER_MINOR,
                                             SAHPI_ES_UPPER_MINOR);
                if (status != SA_OK) {
                        retval = SAF_TEST_UNRESOLVED;
                        e_print(saHpiSensorEventMasksSet, SA_OK, status);
                } else {

                        retval = generateAssertEvents(sessionId, resourceId, sensorRec);
                        if (retval == SAF_TEST_PASS) {
                                sensorData[sensorCount-1].restoreMasks = SAHPI_TRUE;
                                sensorData[sensorCount-1].assertEventMask = assertEventMask;
                                sensorData[sensorCount-1].deassertEventMask = deassertEventMask;
                        } else {
                                // restore event masks
                                if (!(assertEventMask & SAHPI_ES_UPPER_MINOR)) {
                                        status =
                                            saHpiSensorEventMasksSet(sessionId,
                                                                     resourceId,
                                                                     sensorRec->Num,
                                                                     SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
                                                                     SAHPI_ES_UPPER_MINOR,
                                                                     0x0);
                                        if (status != SA_OK) {
                                                e_print(saHpiSensorEventMasksSet, SA_OK,
                                                        status);
                                        }
                                }

                                if (!(deassertEventMask & SAHPI_ES_UPPER_MINOR)) {
                                        status =
                                            saHpiSensorEventMasksSet(sessionId,
                                                                     resourceId,
                                                                     sensorRec->Num,
                                                                     SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
                                                                     0x0,
                                                                     SAHPI_ES_UPPER_MINOR);
                                        if (status != SA_OK) {
                                                e_print(saHpiSensorEventMasksSet, SA_OK,
                                                        status);
                                        }
                                }
                       }
                }
        } else {
                retval = SAF_TEST_NOTSUPPORT;
        }

        return retval;
}

/********************************************************************************************
 *
 * Test a Sensor RDR.
 *
 ********************************************************************************************/

int testSensor(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId, SaHpiRdrT *rdr)
{
        SaErrorT status;
        int retval = SAF_TEST_NOTSUPPORT;
        SaHpiSensorRecT *sensorRec;
        SaHpiBoolT sensorEventsEnabled;

        sensorRec = &rdr->RdrTypeUnion.SensorRec;

        status =
            saHpiSensorEventEnableGet(sessionId, resourceId,
                                      sensorRec->Num,
                                      &sensorEventsEnabled);
        if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
                retval = SAF_TEST_NOTSUPPORT;
        } else if (status != SA_OK) {
                retval = SAF_TEST_UNRESOLVED;
                e_print(saHpiSensorEnableGet, SA_OK, status);
        } else if (sensorEventsEnabled) {
                retval =
                    run_test(sessionId, resourceId, sensorRec);
        } else if (sensorRec->EventCtrl == SAHPI_SEC_PER_EVENT) {
                status =
                    saHpiSensorEventEnableSet(sessionId,
                                              resourceId,
                                              sensorRec->Num,
                                              SAHPI_TRUE);
                if (status != SA_OK) {
                        retval = SAF_TEST_UNRESOLVED;
                        e_print(saHpiSensorEventEnableSet, SA_OK, status);
                } else {
                        retval = run_test(sessionId, resourceId, sensorRec);

                        if (retval == SAF_TEST_PASS) {
                                sensorData[sensorCount-1].origEventEnable = SAHPI_FALSE;
                        } else {

                                // restore EventEnabled state
                                status = saHpiSensorEventEnableSet(sessionId,
                                                                   resourceId,
                                                                   sensorRec->Num,
                                                                   SAHPI_FALSE);
                                if (status != SA_OK) {
                                         e_print(saHpiSensorEventEnableSet, SA_OK, status);
                                }
                        }
                }
        }

        if (retval == SAF_TEST_PASS && sensorCount % POLL_COUNT == 0) {
                retval = checkForEvents(sessionId);
        }

        return retval;
}

/**********************************************************************************
 *
 * Test a resource.
 *
 **********************************************************************************/

int testResource(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId) {
     int retval = SAF_TEST_NOTSUPPORT;
     int response;
     SaErrorT error;
     SaHpiEntryIdT nextEntryId;
     SaHpiEntryIdT entryId;
     SaHpiRdrT rdr;
     SaHpiBoolT pass = SAHPI_FALSE;

     nextEntryId = SAHPI_FIRST_ENTRY;
     while (nextEntryId != SAHPI_LAST_ENTRY && retval == SAF_TEST_NOTSUPPORT) {
          entryId = nextEntryId;
          error = saHpiRdrGet(sessionId, resourceId, entryId, &nextEntryId, &rdr);
          if (error == SA_ERR_HPI_NOT_PRESENT) {
              break;
          } else if (error != SA_OK) {
              retval = SAF_TEST_UNRESOLVED;
              e_print(saHpiRdrGet, SA_OK, error);
          } else {
              response = canTest(sessionId, resourceId, &rdr);
              if (response != SAF_TEST_PASS) {
                   retval = response;
              } else {
                   response = testSensor(sessionId, resourceId, &rdr);
                   if (response == SAF_TEST_PASS) {
                       pass = SAHPI_TRUE;
                   } else {
                       retval = response;
                   }
              }
          }
     }

     if (retval == SAF_TEST_NOTSUPPORT && pass) {
         retval = SAF_TEST_PASS;
     }

     return retval;
}

/**********************************************************************************
 *
 * Test a domain.
 *
 **********************************************************************************/

int TestDomain(SaHpiSessionIdT sessionId)
{
     int retval = SAF_TEST_NOTSUPPORT;
     int response;
     SaErrorT error;
     SaHpiEntryIdT nextEntryId;
     SaHpiEntryIdT entryId;
     SaHpiRptEntryT rptEntry;
     SaHpiBoolT pass = SAHPI_FALSE;

     sensorCount = 0;
     error = saHpiSubscribe(sessionId);
     if (error != SA_OK) {
         e_print(saHpiSubscribe, SA_OK, error);
         retval = SAF_TEST_UNRESOLVED;
     } else {
         nextEntryId = SAHPI_FIRST_ENTRY;
         while (nextEntryId != SAHPI_LAST_ENTRY && retval == SAF_TEST_NOTSUPPORT) {
              entryId = nextEntryId;
              error = saHpiRptEntryGet(sessionId, entryId, &nextEntryId, &rptEntry);
              if (error == SA_ERR_HPI_NOT_PRESENT) {
                  break;
              } else if (error != SA_OK) {
                  retval = SAF_TEST_UNRESOLVED;
                  e_print(saHpiRptEntryGet, SA_OK, error);
              } else if (rptEntry.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR) {
                  response = testResource(sessionId, rptEntry.ResourceId);
                  if (response == SAF_TEST_PASS) {
                      pass = SAHPI_TRUE;
                  } else {
                      retval = response;
                  }
              }
         }

         if (retval == SAF_TEST_NOTSUPPORT && pass) {
             // Check for any remaining events that may have been generated.
             // We will pause for 5 seconds to give the last sensor time to
             // generate an event.

             sleep(5);
             retval = checkForEvents(sessionId);
             if (retval == SAF_TEST_PASS) {
                 // at this point, only the deassert events should be coming in
                 sleep(5);
                 retval = checkForEvents(sessionId);

                 if (retval == SAF_TEST_PASS) {
                     retval = verifyEvents();
                 }
             }
         }

         restoreSensors(sessionId);

         error = saHpiUnsubscribe(sessionId);
         if (error != SA_OK) {
              e_print(saHpiUnsubscribe, SA_OK, error);
         }
     }

     return retval;
}

/**********************************************************************************
 *
 * Main Program 
 *
 **********************************************************************************/

int main()
{
     return process_all_domains(NULL, NULL, TestDomain);
}

