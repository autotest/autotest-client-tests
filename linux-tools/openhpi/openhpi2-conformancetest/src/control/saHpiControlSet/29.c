/* 
 * (C) Copyright University of New Hampshire 2005
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  This
 * file and program are licensed under a BSD style license.  See
 * the Copying file included with the OpenHPI distribution for
 * full licensing terms.
 *
 * Author(s):
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01                                  
 * Function:    saHpiControlSet
 * Description:
 *      Set a legal value for an Analog Control.
 *      Expected return: SA_OK.
 * Line:        P96-18:P96-18
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * Set a new value for the Analog control.
 *
 *************************************************************************/

SaErrorT setAnalogValue(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiCtrlRecT * ctrlRec, SaHpiCtrlStateAnalogT value)
{
	SaErrorT status;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlStateT newCtrlState;

	setDefaultCtrlState(ctrlRec, &newCtrlState);
	newCtrlState.StateUnion.Analog = value;
	status = saHpiControlSet(sessionId, resourceId, ctrlNum,
				 SAHPI_CTRL_MODE_MANUAL, &newCtrlState);
	if (status != SA_OK) {
		e_print(saHpiControlSet, SA_OK, status);
	}

	return status;
}

/*************************************************************************
 *
 * If we have an Analog control that we can set, try changing the value
 * to the min and max values.  This is a good test since we are testing
 * boundary values.
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

	if (!ctrlRec->WriteOnly && isAnalogControl(ctrlRec)
	    && canSetControlState(ctrlRec)) {

		status =
		    saHpiControlGet(sessionId, resourceId, ctrlNum, &ctrlMode,
				    &ctrlState);
		if (status != SA_OK) {
			e_print(saHpiControlGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			status = setAnalogValue(sessionId, resourceId, ctrlRec,
						ctrlRec->TypeUnion.Analog.Min);

			if (status != SA_OK) {
				retval = SAF_TEST_FAIL;
			} else {
				status =
				    setAnalogValue(sessionId, resourceId,
						   ctrlRec,
						   ctrlRec->TypeUnion.Analog.
						   Max);

				if (status != SA_OK) {
					retval = SAF_TEST_FAIL;
				} else {
					retval = SAF_TEST_PASS;
				}
			}

			// Restore original mode and state

			status =
			    saHpiControlSet(sessionId, resourceId, ctrlNum,
					    ctrlMode, &ctrlState);
			if (status != SA_OK) {
				e_print(saHpiControlSet, SA_OK, status);
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
