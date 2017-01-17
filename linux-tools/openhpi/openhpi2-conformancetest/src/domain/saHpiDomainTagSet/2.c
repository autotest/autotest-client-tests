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
 *   Set a new Domain Tag in each domain and restore it.
 *   Expected return: SA_OK.
 * Line:        P38-13:P38-13
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STRING "Test Tag"
#define TEST_STRING_SIZE 8

int testUnicodeTag(SaHpiSessionIdT sessionId)
{
	SaErrorT status;
	int retval;
	SaHpiTextBufferT NewTag;

	NewTag.DataType = SAHPI_TL_TYPE_UNICODE;
	NewTag.Language = SAHPI_LANG_ENGLISH;
	NewTag.DataLength = 2;
	NewTag.Data[0] = 0x0;
	NewTag.Data[1] = 0x41;

	status = saHpiDomainTagSet(sessionId, &NewTag);

	if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiDomainTagSet, SA_OK, status);
	}

	return retval;
}

int testBCDPlusTag(SaHpiSessionIdT sessionId)
{
	SaErrorT status;
	int retval;
	SaHpiTextBufferT NewTag;

	NewTag.DataType = SAHPI_TL_TYPE_BCDPLUS;
	NewTag.Language = SAHPI_LANG_ZULU;
	NewTag.DataLength = 1;
	NewTag.Data[0] = '0';

	status = saHpiDomainTagSet(sessionId, &NewTag);

	if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiDomainTagSet, SA_OK, status);
	}

	return retval;
}

int testAscii6Tag(SaHpiSessionIdT sessionId)
{
	SaErrorT status;
	int retval;
	SaHpiTextBufferT NewTag;

	NewTag.DataType = SAHPI_TL_TYPE_ASCII6;
	NewTag.Language = SAHPI_LANG_ZULU;
	NewTag.DataLength = 2;
	NewTag.Data[0] = 0x20;
	NewTag.Data[1] = 0x5F;

	status = saHpiDomainTagSet(sessionId, &NewTag);

	if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiDomainTagSet, SA_OK, status);
	}

	return retval;
}

int testTextTag(SaHpiSessionIdT sessionId)
{
	SaErrorT status;
	int retval;
	SaHpiTextBufferT NewTag;

	NewTag.DataType = SAHPI_TL_TYPE_TEXT;
	NewTag.Language = SAHPI_LANG_ZULU;
	NewTag.DataLength = TEST_STRING_SIZE;
	strncpy(NewTag.Data, TEST_STRING, TEST_STRING_SIZE);

	status = saHpiDomainTagSet(sessionId, &NewTag);

	if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiDomainTagSet, SA_OK, status);
	}

	return retval;
}

int testBinaryTag(SaHpiSessionIdT sessionId)
{
	SaErrorT status;
	int retval;
	SaHpiTextBufferT NewTag;

	NewTag.DataType = SAHPI_TL_TYPE_BINARY;
	NewTag.Language = SAHPI_LANG_ZULU;
	NewTag.DataLength = 1;
	NewTag.Data[0] = 'a';

	status = saHpiDomainTagSet(sessionId, &NewTag);

	if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiDomainTagSet, SA_OK, status);
	}

	return retval;
}

int Test_Domain(SaHpiSessionIdT sessionId)
{
	SaErrorT status;
	int retval;
	SaHpiDomainInfoT DomainInfo;

	// Retrieve the current DomainTag
	status = saHpiDomainInfoGet(sessionId, &DomainInfo);
	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiDomainInfoGet, SA_OK, status);
	} else {
		retval = testTextTag(sessionId);
		if (retval == SAF_TEST_PASS) {
			retval = testUnicodeTag(sessionId);
			if (retval == SAF_TEST_PASS) {
				retval = testBCDPlusTag(sessionId);
				if (retval == SAF_TEST_PASS) {
					retval = testAscii6Tag(sessionId);
					if (retval == SAF_TEST_PASS) {
						retval =
						    testBinaryTag(sessionId);
					}
				}
			}
		}
		//restore the Domain Tag to what it previously was.
		status = saHpiDomainTagSet(sessionId, &DomainInfo.DomainTag);
		if (status != SA_OK) {
			e_print(saHpiDomainInfoGet, SA_OK, status);
		}
	}

	return retval;
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
