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
 * Function:    saHpiAnnunciatorGetNext
 * Description:
 *   Attempt to get the next announcement by passing in an announcement that
 *   was deleted.
 *   Expected return: SA_OK.
 * Line:        P123-6:P123-7
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Delete the first announcement that was added and then call
 * saHpiAnnunciatorGetNext which should return the next announcement.
 *
 * NOTE: Don't compare against the second announcement simply because
 *       due to race condition, another announcement might show up.
 *
 *************************************************************************/

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId,
	     SaHpiAnnunciatorNumT a_num, SaHpiAnnouncementT * announcement)
{
	int retval;
	SaErrorT status = SA_OK;

	status = deleteAnnouncement(sessionId, resourceId, a_num, announcement);
	if (status != SA_OK) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else {
		status = saHpiAnnunciatorGetNext(sessionId, resourceId, a_num,
						 SAHPI_INFORMATIONAL,
						 SAHPI_FALSE, announcement);
		if (status == SA_OK) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiAnnunciatorGetNext, SA_OK, status);
		}
	}

	return retval;
}

/*************************************************************************
 *
 * To test this case, we must add two announcements to the Annunciator.
 * The above test will then be run.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int retval;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiAnnouncementT announcement1;
	SaHpiAnnouncementT announcement2;
	SaHpiAnnunciatorModeT mode;

	status = setWriteMode(sessionId, resourceId, annunRec, &mode);
	if (status == ANNUN_ERROR) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (status == ANNUN_READONLY) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {

		status =
		    addInfoAnnouncement(sessionId, resourceId, a_num,
					&announcement1);

		if (status == SA_ERR_HPI_OUT_OF_SPACE) {
			retval = SAF_TEST_NOTSUPPORT;
		} else if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {
			status =
			    addInfoAnnouncement(sessionId, resourceId, a_num,
						&announcement2);

			if (status == SA_ERR_HPI_OUT_OF_SPACE) {
				retval = SAF_TEST_NOTSUPPORT;
				deleteAnnouncement(sessionId, resourceId, a_num,
						   &announcement1);
			} else if (status != SA_OK) {
				e_trace();
				retval = SAF_TEST_UNRESOLVED;
				deleteAnnouncement(sessionId, resourceId, a_num,
						   &announcement1);
			} else {
				retval =
				    run_test(sessionId, resourceId, a_num,
					     &announcement1);
				deleteAnnouncement(sessionId, resourceId, a_num,
						   &announcement2);
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
