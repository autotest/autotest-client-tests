/*
 * (C) Copyright University of New Hampshire 2006
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
 * Function:    saHpiSensorEventMasksSet
 * Description:   
 *   For sensors that don't support SAHPI_CAPABILITY_EVT_DEASSERTS, 
 *   verify that the assert/deassert event masks can be independently
 *   changed.
 * Line:        P91-9:P91-10
 */

#include <stdio.h>
#include "saf_test.h"
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>

/************************************************************************
 *
 * Restore the event masks.
 *
 ************************************************************************/

void restore_event_masks(SaHpiSessionIdT sessionId,
			 SaHpiResourceIdT resourceId,
			 SaHpiRdrT * rdr,
			 SaHpiEventStateT assertMask,
			 SaHpiEventStateT deassertMask)
{
	SaErrorT status;
	SaHpiSensorNumT s_num = rdr->RdrTypeUnion.SensorRec.Num;
	SaHpiEventStateT mask = rdr->RdrTypeUnion.SensorRec.Events;

	// clear all of the bits
	status = saHpiSensorEventMasksSet(sessionId, resourceId, s_num,
					  SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
					  mask, mask);
	if (status != SA_OK) {
		e_print(saHpiSensorEventMasksSet, SA_OK, status);
	} else {
		status = saHpiSensorEventMasksSet(sessionId, resourceId, s_num,
						  SAHPI_SENS_ADD_EVENTS_TO_MASKS,
						  assertMask, deassertMask);

		if (status != SA_OK) {
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
		}
	}
}

/************************************************************************
 *
 * To see if we can set the assert and deassert masks separately, we
 * will first clear both and then set all of the bits for the assert
 * masks, but not change the deassert.  We will get the masks again
 * to verify that the change worked correctly.  We will then do the
 * reverse.   Clear both, but now only set the deassert bits but not
 * the assert bits.
 *
 ************************************************************************/

int Test_Rdr(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId, SaHpiRdrT rdr)
{
	int retval = SAF_TEST_NOTSUPPORT;
	SaErrorT status;
	SaHpiSensorNumT s_num;
	SaHpiEventStateT Assertsaved, Deassertsaved;
	SaHpiEventStateT AssertMask, DeassertMask;
	SaHpiSensorRecT *sensorRec;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {

		sensorRec = &rdr.RdrTypeUnion.SensorRec;
		s_num = sensorRec->Num;

		status = saHpiSensorEventMasksGet(sessionId, resourceId, s_num,
						  &Assertsaved, &Deassertsaved);

		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
		} else {

			status =
			    saHpiSensorEventMasksSet(sessionId, resourceId,
						     s_num,
						     SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
						     SAHPI_ALL_EVENT_STATES,
						     SAHPI_ALL_EVENT_STATES);

			if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiSensorEventMasksSet, SA_OK,
					status);
			} else {

				status =
				    saHpiSensorEventMasksSet(sessionId,
							     resourceId, s_num,
							     SAHPI_SENS_ADD_EVENTS_TO_MASKS,
							     SAHPI_ALL_EVENT_STATES,
							     0x0);

				if (status != SA_OK) {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiSensorEventMasksSet, SA_OK,
						status);
				} else {

					status =
					    saHpiSensorEventMasksGet(sessionId,
								     resourceId,
								     s_num,
								     &AssertMask,
								     &DeassertMask);
					if (AssertMask != sensorRec->Events) {
						retval = SAF_TEST_FAIL;
						m_print
						    ("AssertEventMask was not changed!");
					} else if (DeassertMask != 0x0) {
						retval = SAF_TEST_FAIL;
						m_print
						    ("DeassertEventMask was changed!");
					} else {
						status =
						    saHpiSensorEventMasksSet
						    (sessionId, resourceId,
						     s_num,
						     SAHPI_SENS_REMOVE_EVENTS_FROM_MASKS,
						     SAHPI_ALL_EVENT_STATES,
						     SAHPI_ALL_EVENT_STATES);

						if (status != SA_OK) {
							retval =
							    SAF_TEST_UNRESOLVED;
							e_print
							    (saHpiSensorEventMasksSet,
							     SA_OK, status);
						} else {

							status =
							    saHpiSensorEventMasksSet
							    (sessionId,
							     resourceId, s_num,
							     SAHPI_SENS_ADD_EVENTS_TO_MASKS,
							     0x0,
							     SAHPI_ALL_EVENT_STATES);

							if (status != SA_OK) {
								retval =
								    SAF_TEST_UNRESOLVED;
								e_print
								    (saHpiSensorEventMasksSet,
								     SA_OK,
								     status);
							} else {

								status =
								    saHpiSensorEventMasksGet
								    (sessionId,
								     resourceId,
								     s_num,
								     &AssertMask,
								     &DeassertMask);
								if (AssertMask
								    != 0x0) {
									retval =
									    SAF_TEST_FAIL;
									m_print
									    ("AssertEventMask was changed!");
								} else if (DeassertMask != sensorRec->Events) {
									retval =
									    SAF_TEST_FAIL;
									m_print
									    ("DeassertEventMask was not changed!");
								} else {
									retval =
									    SAF_TEST_PASS;
								}
							}
						}
					}
				}
			}

			restore_event_masks(sessionId, resourceId, &rdr,
					    Assertsaved, Deassertsaved);
		}
	}

	return retval;
}

/************************************************************************
 *
 * test resource
 *
 ************************************************************************/

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_NOTSUPPORT;

	if ((report.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR) &&
	    !(report.ResourceCapabilities & SAHPI_CAPABILITY_EVT_DEASSERTS)) {
		retval = do_resource(session, report, func);
	}

	return retval;
}

/************************************************************************
 *
 * Main Program.
 *
 ************************************************************************/

int main()
{
	return process_all_domains(&Test_Resource, &Test_Rdr, NULL);
}
