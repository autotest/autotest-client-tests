/*
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005, Intel Corporation
 * Copyright (c) 2005, University of New Hampshire
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
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventGet
 * Description: 
 *      Verify that when SA_ERR_HPI_TIMEOUT is returned that
 *      the function did indeed block for the given timeout period.
 * Line:        P63-4:P63-5
 */

#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define SMALL_TIME 2000		/* msec */
#define TIMEOUT  6000000000LL	/*6 seconds */
#define ABS(x) (((x) >= 0) ? (x) : -(x))

/*************************************************************************
 *
 * Test a domain
 *
 * Keep reading events from the event queue until we get a TIMEOUT.
 * Once a TIMEOUT occurs, verify that the function did wait for the
 * given timeout duration.  
 *
 * ***********************************************************************/

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiEventT event;
	SaErrorT val;
	SafTimeT startTime, endTime, duration, delta;
	int ret = SAF_TEST_UNKNOWN;

	val = saHpiSubscribe(session_id);
	if (val != SA_OK) {
		e_print(saHpiSubscribe, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
	} else {
		while (ret == SAF_TEST_UNKNOWN) {

			startTime = getCurrentTime();
			val =
			    saHpiEventGet(session_id, TIMEOUT, &event, NULL,
					  NULL, NULL);
			endTime = getCurrentTime();

			if (val == SA_ERR_HPI_TIMEOUT) {
				duration = endTime - startTime;
				delta = ABS(duration - (TIMEOUT / 1000000LL));
				if (delta < SMALL_TIME) {
					ret = SAF_TEST_PASS;
				} else {
					ret = SAF_TEST_FAIL;
					m_print
					    ("\"saHpiEventGet\" did not block for timeout period [time = %lld msec.",
					     duration);
				}
			} else if (val != SA_OK) {
				e_print(saHpiEventGet, SA_OK
					|| SA_ERR_HPI_TIMEOUT, val);
				ret = SAF_TEST_UNRESOLVED;
			}
		}

		val = saHpiUnsubscribe(session_id);
		if (val != SA_OK) {
			e_print(saHpiUnsubscribe, SA_OK, val);
		}
	}

	return ret;
}

/*************************************************************************
 *
 * Main Program.
 *
 * ***********************************************************************/

int main()
{
	return process_all_domains(NULL, NULL, Test_Domain);
}
