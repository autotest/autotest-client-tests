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
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Xiaowei Yang <xiaowei.yang@intel.com>
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSubscribe
 * Description:   
 *   Call saHpiSubscribe passing in a bad SessionId
 *   Expected return:  call returns with an error
 * Line:        P29-47:P29-49
 */

#include <stdio.h>
#include "saf_test.h"

/**********************************************************
*
*   Test_Resource
*
*   Call saHpiSubscribe passing in a bad SessionId
*
*   Expected return:  call returns with an error
*
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successfull
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main(int argc, char **argv)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	status = saHpiSubscribe(INVALID_SESSION_ID);

	if (status == SA_ERR_HPI_INVALID_SESSION) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiSubscribe, SA_OK, status);
	}

	return (retval);
}
