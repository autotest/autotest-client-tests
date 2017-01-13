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
 * Function:    saHpiVersionGet
 * Description:   
 *   Match the test code verion to the HPI implementation version.
 *   Expected return:  Both versions match.
 * Line:        P31-9:P31-18
 */
#include <stdio.h>
#include "saf_test.h"

/**********************************************************
*
*   version test -- saHpiVersionGet/1.c
*   
*   Match the test code verion to the HPI implementation version
*
*   Expected return:  Both versions match
*
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successful
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main(int argc, char **argv)
{
	SaHpiVersionT version;
	int retval = SAF_TEST_UNKNOWN;

	//
	// Call saHpiVersionGet to get the version for the implementation.
	//
	version = saHpiVersionGet();

	//
	// Compare what is retrieved
	//
	if (version == SAHPI_INTERFACE_VERSION)	//32 bit uint compare
		retval = SAF_TEST_PASS;
	else {
		retval = SAF_TEST_FAIL;
		m_print("Function \"saHpiVersionGet\" works abnormally!");
		m_print("Failed to return the current version!");
		m_print("Return value: %x", version);
	}

	return retval;
}
