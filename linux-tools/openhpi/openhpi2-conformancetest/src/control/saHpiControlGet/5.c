/*
 * (C) Copyright 2005 University of New Hampshire
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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiControlGet
 * Description: 
 *      Invoke on a write-only control.
 *      Expected return: SA_ERR_HPI_INVALID_CMD.
 * Line:        P94-21:P94-22
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * Test on a write-only control. 
 *
 * To be comprehensive, we will try all four combinations for the
 * ctrlMode and ctrlState parameters which may be NULL.  We should expect
 * to get INVALID_CMD every time.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlModeT ctrlMode;
	SaHpiCtrlStateT ctrlState;

	if (ctrlRec->WriteOnly) {

		status =
		    saHpiControlGet(sessionId, resourceId, ctrlNum, &ctrlMode,
				    &ctrlState);

		if (status != SA_ERR_HPI_INVALID_CMD) {
			retval = SAF_TEST_FAIL;
			e_print(saHpiControlGet, SA_ERR_HPI_INVALID_CMD,
				status);
		} else {
			status =
			    saHpiControlGet(sessionId, resourceId, ctrlNum,
					    &ctrlMode, NULL);
			if (status != SA_ERR_HPI_INVALID_CMD) {
				retval = SAF_TEST_FAIL;
				e_print(saHpiControlGet, SA_ERR_HPI_INVALID_CMD,
					status);
			} else {
				status =
				    saHpiControlGet(sessionId, resourceId,
						    ctrlNum, NULL, &ctrlState);
				if (status != SA_ERR_HPI_INVALID_CMD) {
					retval = SAF_TEST_FAIL;
					e_print(saHpiControlGet,
						SA_ERR_HPI_INVALID_CMD, status);
				} else {
					status =
					    saHpiControlGet(sessionId,
							    resourceId, ctrlNum,
							    NULL, NULL);
					if (status != SA_ERR_HPI_INVALID_CMD) {
						retval = SAF_TEST_FAIL;
						e_print(saHpiControlGet,
							SA_ERR_HPI_INVALID_CMD,
							status);
					} else {
						retval = SAF_TEST_PASS;
					}
				}
			}
		}
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
