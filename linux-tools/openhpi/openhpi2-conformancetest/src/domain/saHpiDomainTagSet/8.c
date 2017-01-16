/*
 * Copyright (c) 2005, Intel Corporation
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without1 even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307 USA.
 *
 * Author(s):
 *      Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiDomainTagSet/saHpiDomainInfoGet
 * Description:   
 *   Update DomainTag and insure it's immediately visible
 *   on another session opened to the same domain.
 *   Expected return: SA_OK.
 * Line:        P38-22:P38-26
 */

#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STRING "Test Tag"
#define TEST_STRING_SIZE 8

int main(int argc, char **argv)
{
	SaHpiSessionIdT session_a, session_b;
	SaHpiDomainInfoT DomainInfo_a, DomainInfo_b;
	SaHpiTextBufferT NewTag;
	SaErrorT status_a, status_b;
	int retval = SAF_TEST_UNKNOWN;

	//
	// Open session_a & session_b with the same domain
	//
	status_a =
	    saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &session_a, NULL);

	if (status_a != SA_OK) {
		m_print("The first session failed to open!");
		e_print(saHpiSessionOpen, SA_OK, status_a);
		retval = SAF_TEST_UNRESOLVED;
	} else {
		status_b =
		    saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &session_b,
				     NULL);

		if (status_b != SA_OK) {
			m_print("The second session failed to open!");
			e_print(saHpiSessionOpen, SA_OK, status_b);
			retval = SAF_TEST_UNRESOLVED;
		} else {

			// Set up the test Tag to write into the DomainTag
			NewTag.DataType = SAHPI_TL_TYPE_TEXT;
			NewTag.Language = SAHPI_LANG_ENGLISH;
			NewTag.DataLength = TEST_STRING_SIZE;
			strncpy(NewTag.Data, TEST_STRING, TEST_STRING_SIZE);

			// Retrieve the current DomainTag
			status_a = saHpiDomainInfoGet(session_a, &DomainInfo_a);
			if (status_a != SA_OK) {
				e_print(saHpiDomainInfoGet, SA_OK, status_a);
				retval = SAF_TEST_UNRESOLVED;
			}
			// Update Tag of domain_a
			status_a = saHpiDomainTagSet(session_a, &NewTag);
			if (status_a != SA_OK) {
				e_print(saHpiDomainTagSet, SA_OK, status_a);
				retval = SAF_TEST_UNRESOLVED;
			} else {
				status_b =
				    saHpiDomainInfoGet(session_b,
						       &DomainInfo_b);

				if (status_b != SA_OK) {
					e_print(saHpiDomainInfoGet, SA_OK,
						status_b);
					retval = SAF_TEST_UNRESOLVED;
				} else {
					if (DomainInfo_b.DomainTag.DataType ==
					    NewTag.DataType
					    && DomainInfo_b.DomainTag.
					    Language == NewTag.Language
					    && DomainInfo_b.DomainTag.
					    DataLength == NewTag.DataLength
					    && !strncmp(DomainInfo_b.DomainTag.
							Data, NewTag.Data,
							TEST_STRING_SIZE)) {
						retval = SAF_TEST_PASS;
					} else {
						m_print
						    ("Updated Domain Tag isn't immediatedly visible on another session on the same domain!");
						retval = SAF_TEST_FAIL;
					}
				}

				//restore the Domain Tag to what it previously was.
				status_a =
				    saHpiDomainTagSet(session_a,
						      &DomainInfo_a.DomainTag);

				if (status_a != SA_OK) {
					m_print
					    ("Domain tag was not restored to its previous value!");
					e_print(saHpiDomainTagSet, SA_OK,
						status_a);
				}
			}

			status_b = saHpiSessionClose(session_b);

			if (status_b != SA_OK) {
				m_print
				    ("The second session did not close properly!");
				e_print(saHpiSessionClose, SA_OK, status_b);
			}
		}

		status_a = saHpiSessionClose(session_a);

		if (status_a != SA_OK) {
			m_print("The first session did not close properly!");
			e_print(saHpiSessionClose, SA_OK, status_a);
		}
	}

	return (retval);
}
