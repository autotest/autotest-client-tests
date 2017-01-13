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
 *     Wang Jing <jing.j.wang@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAnnunciatorGetNext
 * Description:
 *   Attempt to get unacknowledged announcements of a specific severity from 
 *   an Annunciator table that doesn't have any unacknowledged announcements of
 *   that severity.
 *   Expected return: SA_ERR_HPI_NOT_PRESENT.
 * Line:        P122-33:P122-35
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * If there are no unacknowledged announcements in the Annunciator with 
 * a given severity, then the first call to saHpiAnnunciatorGetNext() should 
 * return NOT_PRESENT.
 *
 *************************************************************************/

int run_test1(SaHpiSessionIdT sessionId,
	      SaHpiResourceIdT resourceId,
	      SaHpiAnnunciatorNumT a_num, SaHpiSeverityT severity)
{
	int retval;
	SaErrorT status;
	SaHpiAnnouncementT announcement;

	announcement.EntryId = SAHPI_FIRST_ENTRY;
	status = saHpiAnnunciatorGetNext(sessionId, resourceId, a_num,
					 severity, SAHPI_TRUE, &announcement);

	if (status == SA_ERR_HPI_NOT_PRESENT) {
		retval = SAF_TEST_PASS;
	} else {
		e_print(saHpiAnnunciatorGetNext, SA_ERR_HPI_NOT_PRESENT,
			status);
		retval = SAF_TEST_FAIL;
	}

	return retval;
}

/*************************************************************************
 *
 * If we didn't find a severity that is unused, then we need to delete
 * all announcements that are INFORMATIONAL and then we can run test 1
 * with INFORMATIONAL.
 *
 *************************************************************************/

int run_test2(SaHpiSessionIdT sessionId,
	      SaHpiResourceIdT resourceId,
	      SaHpiAnnunciatorRecT * annunRec, SaHpiSeverityT severity)
{
	SaErrorT status;
	int retval;
	SaHpiAnnunciatorModeT mode;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;

	status = setWriteMode(sessionId, resourceId, annunRec, &mode);
	if (status == ANNUN_ERROR) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (status == ANNUN_READONLY) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {
		status = saHpiAnnunciatorDelete(sessionId, resourceId, a_num,
						SAHPI_ENTRY_UNSPECIFIED,
						severity);

		if (status == SA_OK) {
			retval =
			    run_test1(sessionId, resourceId, a_num, severity);
		} else {
			e_print(saHpiAnnunciatorDelete, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		}

		restoreMode(sessionId, resourceId, a_num, mode);
	}

	return retval;
}

/*************************************************************************
 *
 * For this test, we need to find a severity that isn't used by any of 
 * the unacknowledged announcements in the Annunciator.  If we find one, 
 * then use it for test 1.  If we don't find one, then we will run test 2.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiSeverityT severity;
	SaHpiBoolT found;

	status = getUnusedSeverity(sessionId, resourceId, a_num,
				   SAHPI_TRUE, &severity, &found);

	if (status != SA_OK) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (found) {
		retval = run_test1(sessionId, resourceId, a_num, severity);
	} else {
		retval = run_test2(sessionId, resourceId, annunRec, SAHPI_INFORMATIONAL);
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
