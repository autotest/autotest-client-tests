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
 *      Aaron Chen <yukun.chen@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiResourceSeveritySet
 * Description:
 *   Call saHpiResourceSeveritySet() to change the RPT entry for a resource in just
 *   a single domain - if the resource appears in other (peer) domains, the RPT
 *   entries for that resource in the other domain should not change.
 *   Expected return:  The severity of the same resource in another domain will
 *                     remain untouched
 * Line:        ????
 */

#include <stdio.h>
#include "saf_test.h"

// This test will not be used HPI-B.01.01 since the spec doesn't contain
// the above description.  Although, it should have.   This test can be included
// in future versions of the spec.
//
// ERROR: This is no guarantee that the two severities were originally the
// same in the two resources.

int is_entitypath_equal(SaHpiEntityPathT * entity_path1,
			SaHpiEntityPathT * entity_path2)
{
	int i = 0;
	int j = 0;

	if (!entity_path1 || !entity_path2) {
		return 0;
	}

	while (i < SAHPI_MAX_ENTITY_PATH) {
		if (entity_path1->Entry[i].EntityType == SAHPI_ENT_ROOT) {
			break;
		}

		i++;
	}

	while (j < SAHPI_MAX_ENTITY_PATH) {
		if (entity_path2->Entry[j].EntityType == SAHPI_ENT_ROOT) {
			break;
		}

		j++;
	}

	if (i != j)
		return 0;

	i = 0;
	while (i < j) {
		if (entity_path1->Entry[i].EntityType !=
		    entity_path2->Entry[i].EntityType
		    || entity_path1->Entry[i].EntityLocation !=
		    entity_path2->Entry[i].EntityLocation) {
			return 0;
		}
		i++;
	}

	return 1;
}

/**********************************************************
*   Main Function
*      takes no arguments
*
*       returns: SAF_TEST_PASS when successfull
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main(int argc, char **argv)
{
	SaHpiSessionIdT session, new_session;
	SaErrorT status;
	SaHpiDomainInfoT domain_info;
	SaHpiEntryIdT entry_id, next_entry_id, entry_id_domain2;
	SaHpiDrtEntryT domain_table_entry;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiSeverityT new_severity, old_severity, old_severity_domain2;
	SaHpiEntityPathT old_entity_path;
	SaHpiRptEntryT Report;

	SaHpiBoolT old_session_open = SAHPI_FALSE;
	SaHpiBoolT new_session_open = SAHPI_FALSE;

	SaHpiBoolT found_res = SAHPI_FALSE;
	SaHpiResourceIdT res_id_domain1;

	//
	//  Open the session
	//
	status = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &session, NULL);

	if (status != SA_OK) {
		e_print(saHpiSessionOpen, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	} else {
		old_session_open = SAHPI_TRUE;

		//
		//  Get the DRT info
		//
		status = saHpiDomainInfoGet(session, &domain_info);

		if (status != SA_OK) {
			m_print
			    (" Function \"saHpiDomainInfoGet\" works abnormally!\n");
			m_print
			    (" Expected SA_ERR_HPI_INVALID_SESSION when running\n");
			m_print
			    ("   saHpiDomainInfoGet on a non-existant session!\n");
			e_print(saHpiDomainInfoGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			if (!domain_info.IsPeer)
				retval = SAF_TEST_NOTSUPPORT;
			else {
				status = saHpiDrtEntryGet(session,
							  SAHPI_FIRST_ENTRY,
							  &next_entry_id,
							  &domain_table_entry);

				if (status != SA_OK) {
					e_print(saHpiDrtEntryGet, SA_OK,
						status);
					retval = SAF_TEST_FAIL;
				}
			}

		}
	}

	//Get the information of another domain
	if (retval == SAF_TEST_UNKNOWN) {
		status =
		    saHpiSessionOpen(domain_table_entry.DomainId, &new_session,
				     NULL);

		if (status != SA_OK) {
			e_print(saHpiSessionOpen, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			//
			// Discover Resources
			//      
			new_session_open = SAHPI_TRUE;
		}
	}
	//update the resource severity in the first domain
	if (retval == SAF_TEST_UNKNOWN) {
		status = saHpiRptEntryGet(session,
					  SAHPI_FIRST_ENTRY,
					  &next_entry_id, &Report);

		if (status != SA_OK) {
			e_print(saHpiRptEntryGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			old_entity_path = Report.ResourceEntity;
			old_severity = Report.ResourceSeverity;
			res_id_domain1 = Report.ResourceId;

			//get the old severity in the 2nd domain

			next_entry_id = SAHPI_FIRST_ENTRY;
			while (next_entry_id != SAHPI_LAST_ENTRY) {
				entry_id = next_entry_id;

				status = saHpiRptEntryGet(new_session,
							  entry_id,
							  &next_entry_id,
							  &Report);

				if (status != SA_OK) {
					e_print(saHpiRptEntryGet, SA_OK,
						status);
					retval = SAF_TEST_UNRESOLVED;
					break;
				} else {
					if (is_entitypath_equal
					    (&Report.ResourceEntity,
					     &old_entity_path)) {
						found_res = SAHPI_TRUE;
						entry_id_domain2 =
						    Report.EntryId;
						old_severity_domain2 =
						    Report.ResourceSeverity;
						break;
					}

				}
			}	//while

			if (!found_res) {
				m_print("The resource was not found");
				retval = SAF_TEST_UNRESOLVED;
			}
			//set the new severity for res in the 1st domain
			if (retval == SAF_TEST_UNKNOWN) {
				new_severity = SAHPI_OK;
				if (old_severity == SAHPI_OK)
					new_severity = SAHPI_DEBUG;

				status = saHpiResourceSeveritySet(session,
								  res_id_domain1,
								  new_severity);

				if (status != SA_OK) {
					e_print(saHpiResourceSeveritySet, SA_OK,
						status);
					retval = SAF_TEST_FAIL;
				}
			}
		}
	}
	//find the resource in the sencond domain and check whether the severity has been changed
	if (retval == SAF_TEST_UNKNOWN) {
		status = saHpiRptEntryGet(new_session,
					  entry_id_domain2,
					  &next_entry_id, &Report);

		if (status != SA_OK) {
			e_print(saHpiRptEntryGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			if (Report.ResourceSeverity == old_severity_domain2)
				retval = SAF_TEST_PASS;
			else {
				m_print
				    ("The severity for the resource in the second domain has been changed!");
				retval = SAF_TEST_FAIL;
			}
		}
	}
	//
	// Close all the session
	//
	if (old_session_open) {
		status = saHpiSessionClose(session);

		if (status != SA_OK) {
			m_print("Old session failed to close properly!");
			e_print(saHpiSessionClose, SA_OK, status);
		}
	}

	if (new_session_open) {
		status = saHpiSessionClose(new_session);

		if (status != SA_OK) {
			m_print("New session failed to close properly!");
			e_print(saHpiSessionClose, SA_OK, status);
		}
	}

	return (retval);
}
