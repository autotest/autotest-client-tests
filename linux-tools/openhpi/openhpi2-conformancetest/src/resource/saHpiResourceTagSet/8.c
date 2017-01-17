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
 *   Call saHpiResourceTagSet() to change the Resource Tag for a resource in just
 *   a single domain - if the resource appears in other (peer) domains, the Resource
 *   tag for that resource in the other domain should not change.
 *   Expected return:  The tag of the same resource in another domain will
 *                     remain untouched
 * Line:        P44-27:P44-28
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STR        "Test Tag Components"

int tag_cmp(SaHpiTextBufferT * tag, SaHpiTextBufferT * tag_new)
{
	if (tag->DataType == tag_new->DataType &&
	    tag->Language == tag_new->Language &&
	    tag->DataLength == tag_new->DataLength &&
	    !memcmp(tag->Data, tag_new->Data, tag->DataLength))
		return 0;
	else
		return -1;
}

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
	SaHpiTextBufferT new_tag, old_tag, old_tag_domain2;
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
		//
		// Discover Resources
		//
		old_session_open = SAHPI_TRUE;

		//
		//  Get the DRT info
		//
		status = saHpiDomainInfoGet(session, &domain_info);

		if (status != SA_OK) {
			//Unable to discover
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
					retval = SAF_TEST_UNRESOLVED;
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
	//update the resource tag in the first domain
	if (retval == SAF_TEST_UNKNOWN) {
		status = saHpiRptEntryGet(session,
					  SAHPI_FIRST_ENTRY,
					  &next_entry_id, &Report);

		if (status != SA_OK) {
			e_print(saHpiRptEntryGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			old_entity_path = Report.ResourceEntity;
			old_tag.DataType = Report.ResourceTag.DataType;
			old_tag.Language = Report.ResourceTag.Language;
			old_tag.DataLength = Report.ResourceTag.DataLength;
			memcpy(old_tag.Data,
			       Report.ResourceTag.Data,
			       sizeof(Report.ResourceTag.Data));
			res_id_domain1 = Report.ResourceId;

			//find the exist tag for resource in the 2nd domain
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
						old_tag_domain2.DataType =
						    Report.ResourceTag.DataType;
						old_tag_domain2.Language =
						    Report.ResourceTag.Language;
						old_tag_domain2.DataLength =
						    Report.ResourceTag.
						    DataLength;
						memcpy(old_tag_domain2.Data,
						       Report.ResourceTag.Data,
						       sizeof(Report.
							      ResourceTag.
							      Data));
						break;
					}

				}
			}

			if (!found_res)
				retval = SAF_TEST_FAIL;

			if (retval == SAF_TEST_UNKNOWN) {
				memset(&new_tag, 0, sizeof(new_tag));
				new_tag.DataType = SAHPI_TL_TYPE_BINARY;
				new_tag.Language = SAHPI_LANG_ENGLISH;
				new_tag.DataLength = sizeof(TEST_STR);
				memcpy(new_tag.Data, TEST_STR,
				       new_tag.DataLength);

				status = saHpiResourceTagSet(session,
							     res_id_domain1,
							     &new_tag);

				if (status != SA_OK) {
					e_print(saHpiResourceTagSet, SA_OK,
						status);
					retval = SAF_TEST_UNRESOLVED;
				}
			}
		}
	}
	//find the resource in the second domain and check whether the resource tag has been changed
	if (retval == SAF_TEST_UNKNOWN) {
		status = saHpiRptEntryGet(new_session,
					  entry_id_domain2,
					  &next_entry_id, &Report);

		if (status != SA_OK) {
			e_print(saHpiRptEntryGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			if (!tag_cmp(&Report.ResourceTag, &old_tag_domain2))
				retval = SAF_TEST_PASS;
			else {
				m_print
				    ("The resource tag for the resource in the second domain ");
				m_print
				    ("is different than the resource tag for the resource ");
				m_print
				    ("in the first domain. They should have been the same!");
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
			m_print("The old session failed to close properly!");
			e_print(saHpiSessionClose, SA_OK, status);
		}
	}

	if (new_session_open) {
		status = saHpiSessionClose(new_session);

		if (status != SA_OK) {
			m_print("The new session failed to close properly!");
			e_print(saHpiSessionClose, SA_OK, status);
		}
	}

	return retval;
}
