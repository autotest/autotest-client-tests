/*
 * (C) Copyright University of New Hampshire 2005
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
 * Authors:
 *     Donald A. Barre <dbarre@unh.edu>
 *     Zhao Zezhang <zezhang.zhao@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAnnunciatorDelete
 * Description:
 *   Attempt to delete an announcement for an Annunciatior that is in Auto Mode.
 *   Expected return: SA_ERR_HPI_READ_ONLY.
 * Line:        P128-31:P128-31
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Try deleting announcements for an Annunciator in Auto mode.
 *
 *************************************************************************/

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId, SaHpiAnnunciatorNumT a_num)
{
	SaErrorT status;
	int retval;

	status = saHpiAnnunciatorDelete(sessionId, resourceId, a_num,
					SAHPI_ENTRY_UNSPECIFIED,
					SAHPI_INFORMATIONAL);

	if (status == SA_ERR_HPI_READ_ONLY) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiAnnunciatorDelete, SA_ERR_HPI_READ_ONLY, status);
	}

	return retval;
}

/*************************************************************************
 *
 * In order to perform this test, the Annunciator must be in Auto mode.
 * If it is already in Auto mode, then we can just run the test.  If not
 * and if we can change it, then we will change the mode to Auto and then
 * run the test.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int retval;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiAnnunciatorModeT mode;

	status = getMode(sessionId, resourceId, a_num, &mode);
	if (status != SA_OK) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (mode == SAHPI_ANNUNCIATOR_MODE_AUTO) {
		retval = run_test(sessionId, resourceId, a_num);
	} else if (annunRec->ModeReadOnly) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {

		// Try changing the mode in order to perform the test.

		status =
		    setMode(sessionId, resourceId, a_num,
			    SAHPI_ANNUNCIATOR_MODE_AUTO);
		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {
			retval = run_test(sessionId, resourceId, a_num);
			setMode(sessionId, resourceId, a_num, mode);
		}
	}

	return retval;
}

/*************************************************************************
 *
 *  Process all Annunciator RDRs.  The below macro expands to
 *  generate all of the generic code necessary to call the given
 *  function to process an RDR.
 *
 *************************************************************************/

processAllAnnunciatorRdrs(processAnnunRdr)
