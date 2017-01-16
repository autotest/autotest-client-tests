/*
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005 by Intel Corp.
 * Copyright (c) 2005, University of New Hampshire
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  This
 * file and program are licensed under a BSD style license.  See
 * the Copying file included with the OpenHPI distribution for
 * full licensing terms.
 *
 * Authors:
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Ye Bo <bo.ye@intel.com>
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiControlTypeGet
 * Description: 
 *      Verify that the return Type is valid.
 *      Expected return: SA_OK.
 * Line:        P93-23:P93-24
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * Verify that saHpiControlTypeGet works properly when given
 * valid parameters.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	int retval;
	SaErrorT status;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlTypeT ctrlType;

	status = saHpiControlTypeGet(sessionId, resourceId, ctrlNum, &ctrlType);
	if (status != SA_OK) {
		retval = SAF_TEST_FAIL;
		e_print(saHpiControlTypeGet, SA_OK, status);
	} else if (isValidCtrlType(ctrlType)) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		m_print
		    ("saHpiControlType returned an invalid control type [0x%x]!",
		     ctrlType);
	}

	return retval;
}

/*************************************************************************
 *
 *  Process all Control RDRs.  The below macro expands to
 *  generate all of the generic code necessary to call the given
 *  function to process an RDR.
 *
 *************************************************************************/

processAllControlRdrs(processCtrlRdr)
