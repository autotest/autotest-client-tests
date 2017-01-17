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
 *     Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventGet
 * Description:   
 *      Call the function with passing a series of timeout values.
 * Line:        P62-15:P62-17
 */

#include <stdio.h>
#include "saf_test.h"

#define TEST_COUNT        3
#define INITIAL_TIMEOUT   2000	// msec
#define INCREMENT_TIMEOUT 2000	// msec
#define MSEC_TO_NANO      1000000

#define SMALL_TIME 500		/* msec */
#define ABS(x) (((x) >= 0) ? (x) : -(x))

/*****************************************************************************
 *
 * Clear the Event Queue.  Keep looping until we get a TIMEOUT which
 * indicates that there are no more events in the queue.
 *
 *****************************************************************************/

SaErrorT clearEventQueue(SaHpiSessionIdT sessionId)
{
	SaErrorT status;
	SaHpiEventT event;
	SaHpiEvtQueueStatusT eventQueueStatus;

	while (SAHPI_TRUE) {
		status = saHpiEventGet(sessionId, SAHPI_TIMEOUT_IMMEDIATE,
				       &event, NULL, NULL, &eventQueueStatus);
		if (status == SA_ERR_HPI_TIMEOUT) {
			status = SA_OK;
			break;
		} else if (status != SA_OK) {
			e_print(saHpiEventGet, SA_OK, status);
			break;
		}
	}

	return status;
}

/*****************************************************************************
 *
 * This test will try several timeout values to verify that the
 * function is timing out properly.  Care must be taken when doing
 * the timing.  First, we only have millisecond accuracy and thus we
 * we use timeouts in the seconds.  Secondly, we only look for a 0.5 msec
 * accuracy.  For example, if we ask for a 2000 msec timeout and we 
 * compute the timeout as 2010, we have to accept that.  In this case we
 * won't fail unless we computed 2501 or greater.
 *
 *****************************************************************************/

int main()
{
	SaHpiSessionIdT sessionId;
	SaHpiEventT event;
	SaErrorT status;
	SafTimeT startTime, endTime;
	int i = 0;
	int retval;
	SaHpiTimeT timeout;
	SafTimeT timeOutValue = INITIAL_TIMEOUT;
	long duration, delta;
	SaHpiEvtQueueStatusT eventQueueStatus;

	status =
	    saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &sessionId, NULL);
	if (status != SA_OK) {
		e_print(saHpiSessionOpen, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
		goto out1;
	}
	status = saHpiSubscribe(sessionId);
	if (status != SA_OK) {
		e_print(saHpiSubscribe, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
		goto out2;
	}
	// Always empty the queue before each test, but this
	// does not guarantee that the event queue will remain
	// empty.  Thus, if we do get an unexpected event, then
	// try the same timeout again.

	retval = SAF_TEST_PASS;
	while (i < TEST_COUNT) {

		status = clearEventQueue(sessionId);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			break;
		} else {

			timeout = timeOutValue * (SaHpiTimeT) MSEC_TO_NANO;
			startTime = getCurrentTime();
			status = saHpiEventGet(sessionId, timeout, &event,
					       NULL, NULL, &eventQueueStatus);
			endTime = getCurrentTime();

			if (status == SA_ERR_HPI_TIMEOUT) {
				duration = endTime - startTime;
				delta = ABS(duration - timeOutValue);
				if (delta > SMALL_TIME) {
					retval = SAF_TEST_FAIL;
					m_print("Failed to timeout within specified interval. %d-%lld=%d < %d", duration, timeOutValue, delta, SMALL_TIME);
					
					break;
				} else {
					timeOutValue += INCREMENT_TIMEOUT;
					i++;
				}
			} else if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiEventGet,
					SA_OK | SA_ERR_HPI_TIMEOUT, status);
				break;
			}
		}
	}

	status = saHpiUnsubscribe(sessionId);
	if (status != SA_OK)
		e_print(saHpiUnsubscribe, SA_OK, status);

      out2:
	status = saHpiSessionClose(sessionId);
	if (status != SA_OK)
		e_print(saHpiSessionClose, SA_OK, status);

      out1:
	return retval;
}
