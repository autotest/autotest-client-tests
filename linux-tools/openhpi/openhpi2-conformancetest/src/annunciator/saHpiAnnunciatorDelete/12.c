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
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAnnunciatorDelete
 * Description:
 *   Attempt to delete announcements for a particular severity where
 *   there are no announcements of that severity level in the Annunciator.
 *   Expected return: SA_OK.
 * Line:        P129-1:P129-2
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Try deleting all announcements for a specific severity even though
 * there are NO announcements with that severity in the Annunciator.
 *
 *************************************************************************/

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId,
	     SaHpiAnnunciatorNumT a_num, SaHpiSeverityT severity)
{
	SaErrorT status;
	int retval;

	status = saHpiAnnunciatorDelete(sessionId, resourceId, a_num,
					SAHPI_ENTRY_UNSPECIFIED, severity);

	if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiAnnunciatorDelete, SA_OK, status);
	}

	return retval;
}

/*************************************************************************
 *
 * For this test, we must use a severity that isn't being used by any
 * of the announcements in the Annunciator.  If we can't find a severity
 * that isn't being used, then delete all announcements using INFORMATIONAL
 * and then used INFORMATIONAL for the test.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiAnnunciatorModeT mode;
	SaHpiSeverityT severity;
	SaHpiBoolT found;

	status = setWriteMode(sessionId, resourceId, annunRec, &mode);
	if (status == ANNUN_ERROR) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (status == ANNUN_READONLY) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {

		status = getUnusedSeverity(sessionId, resourceId, a_num,
					   SAHPI_TRUE, &severity, &found);
		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else if (found) {
			retval =
			    run_test(sessionId, resourceId, a_num, severity);
		} else {

			// If we get here, we couldn't find a severity that was
			// not being used in the Annunciator.  In this case,
			// delete all INFORMATIONAL announcements and then run
			// the test for INFORMATIONAL.

			status = saHpiAnnunciatorDelete(sessionId, resourceId,
							a_num,
							SAHPI_ENTRY_UNSPECIFIED,
							SAHPI_INFORMATIONAL);

			if (status == SA_OK) {
				retval =
				    run_test(sessionId, resourceId, a_num,
					     SAHPI_INFORMATIONAL);
			} else {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiAnnunciatorDelete, SA_OK, status);
			}
		}

		restoreMode(sessionId, resourceId, a_num, mode);
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
