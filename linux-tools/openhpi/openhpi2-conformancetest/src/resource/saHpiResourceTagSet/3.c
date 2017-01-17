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
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiResourceTagSet
 * Description:
 *      Call the function with valid parameters.
 *      Expected return value: SA_OK.
 * Line:        P44-14:P44-14
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

int Test_Resource(SaHpiSessionIdT session_id,
		  SaHpiRptEntryT rpt_entry, callback2_t funcm)
{
	SaHpiResourceIdT resource_id;
	SaHpiTextBufferT tag, tag_old;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	resource_id = rpt_entry.ResourceId;
	tag_old = rpt_entry.ResourceTag;

	memset(&tag, 0, sizeof(tag));
	tag.DataType = SAHPI_TL_TYPE_BINARY;
	tag.Language = SAHPI_LANG_ENGLISH;
	tag.DataLength = sizeof(TEST_STR);
	memcpy(tag.Data, TEST_STR, tag.DataLength);

	val = saHpiResourceTagSet(session_id, resource_id, &tag);

	if (val != SA_OK) {
		e_print(saHpiResourceTagSet, SA_OK, val);
		val = SAF_TEST_FAIL;
	} else {
		val = saHpiRptEntryGetByResourceId(session_id,
						   rpt_entry.ResourceId,
						   &rpt_entry);
		if (val != SA_OK) {
			e_print(saHpiRptEntryGetByResourceId, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
		}
	}

	if (ret == SAF_TEST_UNKNOWN) {
		// Compare
		if (tag_cmp(&rpt_entry.ResourceTag, &tag)) {
			m_print("  Does not conform the expected behaviors!");
			m_print("  Set tag of RPT function is invalid!");
			ret = SAF_TEST_FAIL;
		} else {
			ret = SAF_TEST_PASS;
		}
	}
	//Clean up
	val = saHpiResourceTagSet(session_id, resource_id, &tag_old);

	if (val != SA_OK) {
		e_print(saHpiResourceTagSet, SA_OK, val);
		ret = SAF_TEST_FAIL;
	}

	return ret;
}

int main()
{
	int ret = SAF_TEST_PASS;

	ret = process_all_domains(Test_Resource, NULL, NULL);

	return ret;
}
