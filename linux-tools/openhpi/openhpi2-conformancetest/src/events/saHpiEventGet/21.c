/*
 * Copyright (c) 2006, University of New Hampshire
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
 * Function:    saHpiEventGet
 * Description:
 *      Create a sensor change event and verify that
 *      the rdr returned by saHpiEventGet() is the
 *      the correct rdr.
 * Line:        P62-20:P62-21
 */

#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TIMEOUT  10000000000LL	/* 10 seconds */

/*********************************************************************
 *
 * Get a sensor rdr whose EnableCtrl is true.
 *
 * *******************************************************************/

int getSensor(SaHpiSessionIdT sessionId, SaHpiResourceIdT * resourceId,
	      SaHpiRdrT * rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiEntryIdT entryId, nextEntryId;
	SaHpiRptEntryT rptEntry;
	SaHpiEntryIdT rdrEntryId, nextRdrEntryId;

	nextEntryId = SAHPI_FIRST_ENTRY;
	while (nextEntryId != SAHPI_LAST_ENTRY && retval == SAF_TEST_NOTSUPPORT) {
		entryId = nextEntryId;
		status =
		    saHpiRptEntryGet(sessionId, entryId, &nextEntryId,
				     &rptEntry);
		if (status == SA_ERR_HPI_NOT_PRESENT) {
			break;
		} else if (status != SA_OK) {
			e_print(saHpiRptEntryGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
			break;
		} else if (rptEntry.
			   ResourceCapabilities & SAHPI_CAPABILITY_SENSOR) {

			nextRdrEntryId = SAHPI_FIRST_ENTRY;
			while (nextRdrEntryId != SAHPI_LAST_ENTRY) {
				rdrEntryId = nextRdrEntryId;
				status =
				    saHpiRdrGet(sessionId, rptEntry.ResourceId,
						rdrEntryId, &nextRdrEntryId,
						rdr);
				if (status == SA_ERR_HPI_NOT_PRESENT) {
					break;
				} else if (status != SA_OK) {
					e_print(saHpiRdrEntryGet, SA_OK,
						status);
					retval = SAF_TEST_UNRESOLVED;
				} else if ((rdr->RdrType == SAHPI_SENSOR_RDR) &&
					   (rdr->RdrTypeUnion.SensorRec.
					    EnableCtrl)) {
					*resourceId = rptEntry.ResourceId;
					retval = SAF_TEST_PASS;
					break;
				}
			}
		}
	}

	return retval;
}

/*********************************************************************
 *
 * Generate a sensor enable change event.
 *
 * *******************************************************************/

int generateSensorEvent(SaHpiSessionIdT sessionId,
			SaHpiSensorNumT * snum, SaHpiRdrT * rdr)
{
	SaErrorT status;
	int retval;
	SaHpiResourceIdT resourceId;
	SaHpiBoolT enable, enable_old;

	retval = getSensor(sessionId, &resourceId, rdr);
	if (retval == SAF_TEST_PASS) {

		*snum = rdr->RdrTypeUnion.SensorRec.Num;

		status =
		    saHpiSensorEnableGet(sessionId, resourceId, *snum,
					 &enable_old);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiSensorEnableGet, SA_OK, status);
		} else {

			enable = !enable_old;

			status =
			    saHpiSensorEnableSet(sessionId, resourceId, *snum,
						 enable);
			if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiSensorEnableSet, SA_OK, status);
			} else {
				status =
				    saHpiSensorEnableSet(sessionId, resourceId,
							 *snum, enable_old);
				if (status != SA_OK) {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiSensorEnableSet, SA_OK,
						status);
				} else {
					retval = SAF_TEST_PASS;
				}
			}
		}
	}

	return retval;
}

/*********************************************************************
 *
 * Test a Domain.
 *
 * *******************************************************************/

int Test_Domain(SaHpiSessionIdT sessionId)
{
	SaHpiEventT event;
	SaHpiRdrT rdr, sensorRdr;
	SaHpiRptEntryT rpt_entry;
	SaErrorT val;
	int status;
	int ret = SAF_TEST_UNKNOWN;
	SaHpiSensorNumT snum;
	SafTimeT startTime, duration;

	val = saHpiSubscribe(sessionId);
	if (val != SA_OK) {
		e_print(saHpiSubscribe, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
	} else {

		status = generateSensorEvent(sessionId, &snum, &sensorRdr);
		if (status != SAF_TEST_PASS) {
			ret = status;
		} else {

			startTime = getCurrentTime();
			duration = 0;
			while (ret == SAF_TEST_UNKNOWN && duration < 60000) {	// wait no more than 60 seconds
				val =
				    saHpiEventGet(sessionId, TIMEOUT, &event,
						  &rdr, &rpt_entry, NULL);
				if (val != SA_OK) {
					e_print(saHpiEventGet, SA_OK, val);
					ret = SAF_TEST_UNRESOLVED;
				} else
				    if ((event.EventType ==
					 SAHPI_ET_SENSOR_ENABLE_CHANGE)
					&& (event.EventDataUnion.
					    SensorEnableChangeEvent.SensorNum ==
					    snum)) {

					if ((rdr.RdrType == SAHPI_SENSOR_RDR) &&
					    (rdr.RecordId ==
					     sensorRdr.RecordId)) {
						ret = SAF_TEST_PASS;
					} else {
						ret = SAF_TEST_FAIL;
						m_print
						    ("RDR is not the correct sensor rdr!");
					}
				}
				duration = getCurrentTime() - startTime;
			}

			if (ret == SAF_TEST_UNKNOWN) {
				ret = SAF_TEST_UNRESOLVED;
				m_print("Did not receive sensor event!");
			}
		}

		val = saHpiUnsubscribe(sessionId);
		if (val != SA_OK) {
			e_print(saHpiUnsubscribe, SA_OK, val);
		}
	}

	return ret;
}

/*********************************************************************
 *
 * Main Program.
 *
 * *******************************************************************/

int main()
{
	return process_all_domains(NULL, NULL, Test_Domain);
}
