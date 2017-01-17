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
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Xiaowei Yang <xiaowei.yang@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiDomainTagSet
 * Description:   
 *   Set a new Domain Tag in each domain and see if it takes effect.
 * Line:        P38-22:38-24
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STRING "Test Tag"
#define TEST_STRING_SIZE 8

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

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiDomainInfoT DomainInfo, Old_DomainInfo;
	SaHpiTextBufferT NewTag;
	SaErrorT status;
	int ret;

	// set up the test Tag to write into the DomainTag
	NewTag.DataType = SAHPI_TL_TYPE_TEXT;
	NewTag.Language = SAHPI_LANG_ENGLISH;
	NewTag.DataLength = TEST_STRING_SIZE;
	strncpy(NewTag.Data, TEST_STRING, TEST_STRING_SIZE);

	// Retrieve the current DomainTag
	status = saHpiDomainInfoGet(session_id, &Old_DomainInfo);

	if (status != SA_OK) {
		e_print(saHpiDomainInfoGet, SA_OK, status);
		return SAF_TEST_UNRESOLVED;
	}
	// Set the new Tag
	status = saHpiDomainTagSet(session_id, &NewTag);
	if (status != SA_OK) {
		e_print(saHpiDomainTagSet, SA_OK, status);
		return SAF_TEST_UNRESOLVED;
	}

	status = saHpiDomainInfoGet(session_id, &DomainInfo);

	if (status != SA_OK) {
		e_print(saHpiDomainInfoGet, SA_OK, status);
		ret = SAF_TEST_UNRESOLVED;
	} else if (tag_cmp(&DomainInfo.DomainTag, &NewTag)) {
		m_print("  Does not conform the expected behaviors!");
		m_print("  Set tag of RPT function is invalid!");
		ret = SAF_TEST_FAIL;
	} else {
		ret = SAF_TEST_PASS;
	}

	// Restore the Domain Tag to what it previously was.
	status = saHpiDomainTagSet(session_id, &Old_DomainInfo.DomainTag);

	if (status != SA_OK) {
		m_print("Domain tag was not restored to its previous value!");
		e_print(saHpiDomainTagSet, SA_OK, status);
	}

	return ret;
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
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(NULL, NULL, Test_Domain);

	return (retval);
}
