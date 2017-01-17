/*      -*- linux-c -*-
 *
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
 * Author(s):
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Ye Bo <bo.ye@intel.com>
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01                                  
 * Function:    saHpiControlSet
 * Description: 
 *      Call saHpiControlSet() to set MID of OEM control. 
 *      Check whether the MID is ignored.
 * Line:        P97-26:P97-27
 */

#include <stdio.h>
#include "saf_test.h"

/**********************************************************
*
*   Test Case
*
*   Call saHpiControlSet() to set MID of OEM control.
*   Check whether the MID is ignored.
*
*   Expected return:  call returns SA_OK
*
*       returns: SAF_TEST_PASS when MID was ignored
*                SAF_TEST_FAIL when MID was not ignored
*************************************************************/

int TestCase_Rdr(SaHpiSessionIdT session,
		 SaHpiResourceIdT resourceId, SaHpiRdrT rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiCtrlNumT c_num = 0;
	SaHpiCtrlModeT CtrlMode;
	SaHpiCtrlModeT CtrlOldMode;
	SaHpiCtrlStateT CtrlState;
	SaHpiCtrlStateT CtrlSetState;
	SaHpiCtrlStateT CtrlOldState;

	if (rdr.RdrType == SAHPI_CTRL_RDR) {
		if (rdr.RdrTypeUnion.CtrlRec.WriteOnly != SAHPI_FALSE) {
			retval = SAF_TEST_NOTSUPPORT;
		}
	} else {
		// Non-Control RDR
		retval = SAF_TEST_NOTSUPPORT;
	}
	if (retval == SAF_TEST_UNKNOWN) {
		c_num = rdr.RdrTypeUnion.CtrlRec.Num;
		//
		// Find out if this Control is a Text
		//
		status = saHpiControlGet(session,
					 resourceId,
					 c_num, &CtrlOldMode, &CtrlState);
		if (status == SA_OK) {
			if (CtrlState.Type != SAHPI_CTRL_TYPE_OEM) {
				// This Control is not a OEM Type
				retval = SAF_TEST_NOTSUPPORT;
			} else if (CtrlOldMode == SAHPI_CTRL_MODE_AUTO
				   && rdr.RdrTypeUnion.CtrlRec.DefaultMode.
				   ReadOnly == SAHPI_TRUE) {
				retval = SAF_TEST_NOTSUPPORT;
			}
		} else {
			// Control Get didn't work to get information
			retval = SAF_TEST_UNRESOLVED;
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		CtrlMode = SAHPI_CTRL_MODE_MANUAL;
		CtrlOldState = CtrlSetState = CtrlState;
		CtrlSetState.StateUnion.Oem.MId = 12;
		status = saHpiControlSet(session,
					 resourceId,
					 c_num, CtrlMode, &CtrlSetState);
		if (status != SA_OK) {
			e_print(saHpiControlSet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
			return retval;
		}

		status = saHpiControlGet(session,
					 resourceId,
					 c_num, &CtrlMode, &CtrlState);
		if (status != SA_OK) {
			e_print(saHpiControlGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else if (CtrlState.StateUnion.Oem.MId == 12) {
			m_print
			    ("ManufacturerId field of an OEM is not ignored.");
			retval = SAF_TEST_FAIL;
		}
		// restore
		saHpiControlSet(session,
				resourceId, c_num, CtrlOldMode, &CtrlOldState);
		retval = SAF_TEST_PASS;
	}
	return (retval);
}

/************************************************************
*  Test_Resource
*
*   Returns HPI_TEST return codes: PASS, FAIL, UNKNOWN, NOTSUPPORT
*
*   Expected return:  call returns SA_OK.
*
*
************************************************************/

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_CONTROL) {
		retval = do_resource(session, report, func);
	} else			//Resource Does not support Sensors
	{
		retval = SAF_TEST_NOTSUPPORT;
	}
	return (retval);
}

/**********************************************************
*   Main Function
*      takes no arguments
*      
*       returns: HPI_TEST_PASS when successfull
*                HPI_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main(int argc, char **argv)
{
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(Test_Resource, TestCase_Rdr, NULL);

	return (retval);
}
