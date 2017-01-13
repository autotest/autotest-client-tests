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
 *      Verify that the function returns "immediately" if the function
 *      is called with SAHPI_TIMEOUT_IMMEDIATE and the event queue is empty.
 * Line:        P63-1:P63-3
 */

#include <stdio.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
#include "saf_test.h"

#define MAX_EVENTS 100
#define SMALL_TIME 2500		/* msec */

/***********************************************************************************
 * 
 * Test a domain.
 *
 * ********************************************************************************/

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiEventT event;
	SaErrorT val;
	SafTimeT startTime, endTime, duration;
	int ret = SAF_TEST_UNKNOWN;
	int i = 0;

	val = saHpiSubscribe(session_id);
	if (val != SA_OK) {
		e_print(saHpiSubscribe, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
	} else {

		while ((i++ < MAX_EVENTS) && (ret == SAF_TEST_UNKNOWN)) {

			startTime = getCurrentTime();
			val = saHpiEventGet(session_id, SAHPI_TIMEOUT_IMMEDIATE,
					    &event, NULL, NULL, NULL);
			endTime = getCurrentTime();

			if (val == SA_ERR_HPI_TIMEOUT) {
				duration = endTime - startTime;
				if (duration < SMALL_TIME) {
					ret = SAF_TEST_PASS;
				} else {
					ret = SAF_TEST_FAIL;
					m_print
					    ("\"saHpiEventGet\" did not return immediately [time = %lld msec]",
					     duration);
				}
			} else if (val != SA_OK) {
				e_print(saHpiEventGet, SA_OK, val);
				ret = SAF_TEST_UNRESOLVED;
			}
		}

		if (ret == SAF_TEST_UNKNOWN) {
			ret = SAF_TEST_FAIL;
			m_print
			    ("\"saHpiEventGet\": Never received SA_ERR_HPI_TIMEOUT!");
		}

		val = saHpiUnsubscribe(session_id);
		if (val != SA_OK) {
			e_print(saHpiUnsubscribe, SA_OK, val);
		}
	}

	return ret;
}

/***********************************************************************************
 * 
 * Main Program.
 *
 * ********************************************************************************/

int main()
{
	return process_all_domains(NULL, NULL, Test_Domain);
}
