/*
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
 *     Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSessionOpen
 * Description:   
 *   Open a new session with a specific DomainId.
 *   Expected return: SA_OK.
 * Line:        P33-17:P33-17
 */

#include <stdio.h>
#include "saf_test.h"

/**********************************************************
*
*   Open a session with SAHPI_UNSPECIFIED_DOMAIN_ID, call
*   saHpiDomainInfoGet() to get domain Id. Then open a new
*   session with that domain Id.
*
*   Expected return:  saHpiSessionOpen() returns 
*                     SA_OK
*
*   Main Function
*       takes no arguments
*      
*       returns: SAF_TEST_PASS when successful
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/

int main()
{
	SaHpiSessionIdT session_id;
	SaHpiDomainInfoT domain_info;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	status =
	    saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &session_id, NULL);
	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiSessionOpen, SA_OK, status);
	} else {

		status = saHpiDomainInfoGet(session_id, &domain_info);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiDomainInfoGet, SA_OK, status);
		} else {

			status = saHpiSessionClose(session_id);

			if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(SaHpiSessionClose, SA_OK, status);
			} else {
				status =
				    saHpiSessionOpen(domain_info.DomainId,
						     &session_id, NULL);
				if (status == SA_OK) {
					retval = SAF_TEST_PASS;
					saHpiSessionClose(session_id);
				} else {
					retval = SAF_TEST_FAIL;
					e_print(SaHpiSessionOpen, SA_OK,
						status);
				}
			}
		}
	}

	return retval;
}
