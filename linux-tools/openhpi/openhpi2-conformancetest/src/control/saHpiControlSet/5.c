/*
 * (C) University of New Hampshire 2005
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
 * Function:    saHpiControlSet
 * Description: 
 *      For a Text control, use a DataType that is not
 *      specified in the RDR.
 *      Expected return: SA_ERR_HPI_INVALID_DATA.
 * Line:        P96-27:P96-27
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * Test using a DataType different from that specified in the RDR.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
	SaHpiCtrlStateT ctrlState;

	if (isTextControl(ctrlRec) && canSetControlState(ctrlRec)) {

		setDefaultCtrlState(ctrlRec, &ctrlState);
		if (isTextDataType(ctrlRec)) {
			setDataType(&ctrlState, SAHPI_TL_TYPE_BINARY);
		} else {
			setDataType(&ctrlState, SAHPI_TL_TYPE_TEXT);
		}

		status = saHpiControlSet(sessionId, resourceId, ctrlNum,
					 SAHPI_CTRL_MODE_MANUAL, &ctrlState);

		if (status == SA_ERR_HPI_INVALID_DATA) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiControlSet, SA_ERR_HPI_INVALID_DATA,
				status);
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
