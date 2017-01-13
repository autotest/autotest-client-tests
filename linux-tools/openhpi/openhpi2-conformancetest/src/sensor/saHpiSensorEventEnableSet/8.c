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
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorEventEnableSet
 * Description:   
 *   Set event enable status enable, change the thresholds to cross the current value
 *   Check asserted events will be generated.
 * Line:        P88-25:P88-26
 */

#include <stdio.h>
#include <string.h>
#include "saf_test.h"
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>

#define MAX_SENSORS 2000
#define POLL_COUNT 10  // poll for events after every "n" sensors

static int sensorCount;

typedef struct {
    SaHpiResourceIdT resourceId;
    SaHpiSensorNumT sensorNum;
    SaHpiSensorThresholdsT thresholds;
    SaHpiBoolT foundEvent;
    SaHpiBoolT disableEvents;
} SensorData;

static SensorData sensorData[MAX_SENSORS];

/**********************************************************************************
 *
 * Restore sensors
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

        if (sensorData[i].disableEvents) {
                status = saHpiSensorEventEnableSet(sessionId, sensorData[i].resourceId,
                                                   sensorData[i].sensorNum, SAHPI_FALSE);
                if (status != SA_OK) {
                        e_print(saHpiSensorEventEnableSet, SA_OK, status);
                }
        }
    }
}

int verifyEvents() {
    int       i;
    SaErrorT  status;
    int retval = SAF_TEST_PASS;

    for (i = 0; i < sensorCount; i++) {
        if (!sensorData[i].foundEvent) {
                retval = SAF_TEST_FAIL;
                m_print("Resource %d; sensor %d did not generate an UpMinor threshold event!",
                        sensorData[i].resourceId, sensorData[i].sensorNum);
        }
    }

    return retval;
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
                               SaHpiSensorRecT * sensorRec,
                               SaHpiSensorThresholdsT * thresholds)
{
        SaErrorT status;
        int retval = SAF_TEST_NOTSUPPORT;
        SaHpiSensorReadingT reading;
        SaHpiBoolT isWithin;
        SaHpiSensorReadingT low, high;

        status = saHpiSensorReadingGet(sessionId, resourceId,
                                       sensorRec->Num, &reading, NULL);
        if (status != SA_OK) {
                retval = SAF_TEST_UNRESOLVED;
                e_print(saHpiSensorReadingGet, SA_OK, status);
        } else {
                switch (reading.Type) {
                case SAHPI_SENSOR_READING_TYPE_INT64:
                        low.Value.SensorInt64 =
                            thresholds->LowMinor.Value.SensorInt64;
                        if (thresholds->NegThdHysteresis.IsSupported) {
                                low.Value.SensorInt64 +=
                                    thresholds->NegThdHysteresis.Value.
                                    SensorInt64;
                        }

                        high.Value.SensorInt64 =
                            thresholds->UpMinor.Value.SensorInt64;
                        if (thresholds->PosThdHysteresis.IsSupported) {
                                high.Value.SensorInt64 -=
                                    thresholds->PosThdHysteresis.Value.
                                    SensorInt64;
                        }

                        isWithin =
                            (reading.Value.SensorInt64 > low.Value.SensorInt64)
                            && (reading.Value.SensorInt64 <
                                high.Value.SensorInt64);
                        break;

                case SAHPI_SENSOR_READING_TYPE_UINT64:
                        low.Value.SensorUint64 =
                            thresholds->LowMinor.Value.SensorUint64;
                        if (thresholds->NegThdHysteresis.IsSupported) {
                                low.Value.SensorUint64 +=
                                    thresholds->NegThdHysteresis.Value.
                                    SensorUint64;
                        }

                        high.Value.SensorUint64 =
                            thresholds->UpMinor.Value.SensorUint64;
                        if (thresholds->PosThdHysteresis.IsSupported) {
                                high.Value.SensorUint64 -=
                                    thresholds->PosThdHysteresis.Value.
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
                            thresholds->LowMinor.Value.SensorFloat64;
                        if (thresholds->NegThdHysteresis.IsSupported) {
                                low.Value.SensorFloat64 +=
                                    thresholds->NegThdHysteresis.Value.
                                    SensorFloat64;
                        }

                        high.Value.SensorFloat64 =
                            thresholds->UpMinor.Value.SensorFloat64;
                        if (thresholds->PosThdHysteresis.IsSupported) {
                                high.Value.SensorFloat64 -=
                                    thresholds->PosThdHysteresis.Value.
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

        return retval;
}

/**********************************************************************************
 *
 * Can we run this test?  The requirements are:
 *
 *      1) Must be a sensor.
 *      2) Must not have exceeded the number of sensors we are allowed to test.
 *      3) Must be a threshold sensor.
 *      4) Must be able to change the UpMinor threshold.
 *      5) Event sensor must be enabled.
 *      6) The UpMinor assert event must be set.
 *
 **********************************************************************************/

int canTest(SaHpiSessionIdT sessionId,
            SaHpiResourceIdT resourceId, SaHpiRdrT * rdr)
{
        SaErrorT status;
        int retval = SAF_TEST_NOTSUPPORT;
        SaHpiSensorRecT *sensorRec;
        SaHpiEventStateT assertMask;
        SaHpiBoolT enabled;

        if (rdr->RdrType == SAHPI_SENSOR_RDR) {

                sensorRec = &(rdr->RdrTypeUnion.SensorRec);

                if ((sensorCount < MAX_SENSORS) &&
                    (sensorRec->ThresholdDefn.IsAccessible) &&
                    (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_LOW_MINOR)
                    && (sensorRec->ThresholdDefn.ReadThold & SAHPI_STM_UP_MINOR)
                    && (sensorRec->ThresholdDefn.
                        WriteThold & SAHPI_STM_UP_MINOR)) {

                        status = saHpiSensorEnableGet(sessionId, resourceId,
                                                      sensorRec->Num, &enabled);

                        if (status == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
                                retval = SAF_TEST_NOTSUPPORT;
                                m_print("Sensor is not present.");
                        } else if (status != SA_OK) {
                                retval = SAF_TEST_UNRESOLVED;
                                e_print(saHpiSensorEnableGet, SA_OK, status);
                        } else if (enabled) {

                                status =
                                    saHpiSensorEventMasksGet(sessionId,
                                                             resourceId,
                                                             sensorRec->Num,
                                                             &assertMask, NULL);
                                if (status != SA_OK) {
                                        retval = SAF_TEST_UNRESOLVED;
                                        e_print(saHpiSensorEventMaskGet, SA_OK, status);
                                } else if (assertMask & SAHPI_ES_UPPER_MINOR) {
                                        retval = SAF_TEST_PASS;
                                }
                        }
                }
        }

        return retval;
}

/**********************************************************************************
 *
 * Check for any events that may have been generated by the sensors.
 *
 **********************************************************************************/

int checkForEvents(SaHpiSessionIdT sessionId)
{
    int i;
    int retval = SAF_TEST_PASS;
    SaErrorT status;
    SaHpiEventT event;
    SaHpiSensorNumT sensorNum;

    while (SAHPI_TRUE) {
         status = saHpiEventGet(sessionId, SAHPI_TIMEOUT_IMMEDIATE, &event, NULL, NULL, NULL);
         if (status == SA_ERR_HPI_TIMEOUT) {
              break;
         } else if (status != SA_OK) {
              retval = SAF_TEST_UNRESOLVED;
              e_print(saHpiEventGet, SA_OK, status);
              break;
         } else if (event.EventType == SAHPI_ET_SENSOR) {
              sensorNum = event.EventDataUnion.SensorEvent.SensorNum;
              for (i = 0; i < sensorCount; i++) {
                  if ((sensorData[i].resourceId == event.Source) &&
                      (sensorData[i].sensorNum == sensorNum)) {

                      sensorData[i].foundEvent = SAHPI_TRUE;
                      break;
                  }
              }
         }
    }

    return retval;
}


/**********************************************************************************
 *
 * Run the test.  We will subscribe for events and then we will change the 
 * UpMinor threshold to be equal to the LowMinor threshold.  This should cause
 * an event to be generated.  But since we have disabled
 *
 **********************************************************************************/

int run_test(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId,
             SaHpiSensorRecT * sensorRec)
{
        SaErrorT status;
        int retval;
        int response;
        SaHpiSensorThresholdsT thresholds;
        SaHpiSensorThresholdsT newThresholds;

        status = saHpiSensorThresholdsGet(sessionId, resourceId,
                                          sensorRec->Num, &thresholds);
        if (status != SA_OK) {
                retval = SAF_TEST_UNRESOLVED;
                e_print(saHpiSensorThresholdsGet, SA_OK, status);
        } else {

                response =
                    isReadingWithinMinorLimits(sessionId, resourceId,
                                               sensorRec, &thresholds);
                if (response != SAF_TEST_PASS) {
                        retval = response;
                } else {

                        initThresholds(&newThresholds,
                                       sensorRec->DataFormat.ReadingType);
                        newThresholds.UpMinor.IsSupported = SAHPI_TRUE;
                        setThresholdValue(&newThresholds.UpMinor,
                                          &thresholds.LowMinor);

                        status =
                            saHpiSensorThresholdsSet(sessionId,
                                                     resourceId,
                                                     sensorRec->Num,
                                                     &newThresholds);
                        if (status != SA_OK) {
                                retval = SAF_TEST_UNRESOLVED;
                                e_print(saHpiSensorThresholdsSet, SA_OK,
                                        status);
                        } else {
                                retval = SAF_TEST_PASS;

                                // restore the UpMinor Threshold
                                setThresholdValue(&newThresholds.UpMinor,
                                                  &thresholds.UpMinor);


                                // Wait until the test is complete before
                                // restoring the thresholds. Don't want a possible 
                                // race condition where the event doesn't get generated.

                                sensorData[sensorCount].resourceId = resourceId;
                                sensorData[sensorCount].sensorNum = sensorRec->Num;
                                sensorData[sensorCount].thresholds = newThresholds;
                                sensorData[sensorCount].disableEvents = SAHPI_FALSE;
                                sensorCount++;
                        }
                }
        }

        return retval;
}

/**********************************************************************************
 *
 * Test an RDR.  If we can run the test, we will do so.  Note that if event
 * generation is already enabled, we can simply run the test.  If it is disabled,
 * we will enable it and then run the test.
 *
 **********************************************************************************/

int testSensor(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId, SaHpiRdrT *rdr)
{
        SaErrorT status;
        int retval = SAF_TEST_NOTSUPPORT;
        SaHpiBoolT enabled;
        SaHpiSensorRecT *sensorRec = &(rdr->RdrTypeUnion.SensorRec);

        status = saHpiSensorEventEnableGet(sessionId, resourceId,
                                      sensorRec->Num, &enabled);
        if (status != SA_OK) {
                retval = SAF_TEST_UNRESOLVED;
                e_print(saHpiSensorEventEnableGet, SA_OK, status);
        } else if (enabled) {
                retval = run_test(sessionId, resourceId, sensorRec);
        } else if (sensorRec->EventCtrl != SAHPI_SEC_READ_ONLY) {
                status =
                    saHpiSensorEventEnableSet(sessionId, resourceId,
                                              sensorRec->Num,
                                              SAHPI_TRUE);
                if (status != SA_OK) {
                        retval = SAF_TEST_UNRESOLVED;
                        e_print(saHpiSensorEventEnableSet, SA_OK, status);
                } else {
                        retval = run_test(sessionId, resourceId, sensorRec);
                        if (retval == SAF_TEST_PASS) {
                                sensorData[sensorCount-1].disableEvents = SAHPI_TRUE;
                        } else {
                                status = saHpiSensorEventEnableSet(sessionId,
                                                               resourceId,
                                                               sensorRec->Num,
                                                               enabled);
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
                         retval = verifyEvents();
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
