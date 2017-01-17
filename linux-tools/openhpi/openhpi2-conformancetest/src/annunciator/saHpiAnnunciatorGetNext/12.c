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
 *   Attempt to get the next announcement where the passed
 *   announcement does not match the timestamp of that announcement.
 *   Expected return: SA_ERR_INVALID_DATA.
 * Line:        P122-37:P122-38
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Get the first announcement and modify its Timestamp before
 * retrieving the second announcement.  This should result in an
 * error.
 *
 *************************************************************************/

int run_mismatch(SaHpiSessionIdT sessionId,
		 SaHpiResourceIdT resourceId, SaHpiAnnunciatorNumT a_num)
{
	SaErrorT status;
	int retval;
	SaHpiAnnouncementT announcement;

	// Get the first announcement.

	announcement.EntryId = SAHPI_FIRST_ENTRY;
	status = saHpiAnnunciatorGetNext(sessionId, resourceId, a_num,
					 SAHPI_ALL_SEVERITIES, SAHPI_FALSE,
					 &announcement);
	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiAnnunciatorGetNext, SA_OK, status);
	} else {

		// Increment the Timestamp to create the mismatch and
		// try retrieving another announcement.  This should
		// result in an error condition.

		announcement.Timestamp++;
		status = saHpiAnnunciatorGetNext(sessionId, resourceId, a_num,
						 SAHPI_ALL_SEVERITIES,
						 SAHPI_FALSE, &announcement);

		if (status == SA_ERR_HPI_INVALID_DATA) {
			retval = SAF_TEST_PASS;
		} else {
			e_print(saHpiAnnunciatorGetNext,
				SA_ERR_HPI_INVALID_DATA, status);
			retval = SAF_TEST_FAIL;
		}
	}

	return retval;
}

/*************************************************************************
 *
 * Add a couple of INFORMATIONAL announcements and then run the 
 * above test.
 *
 *************************************************************************/

int add_and_run_mismatch(SaHpiSessionIdT sessionId,
			 SaHpiResourceIdT resourceId,
			 SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	SaHpiAnnouncementT announcement1;
	SaHpiAnnouncementT announcement2;
	SaHpiAnnunciatorModeT mode;
	int retval;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;

	status = setWriteMode(sessionId, resourceId, annunRec, &mode);
	if (status == ANNUN_ERROR) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (status == ANNUN_READONLY) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {

		status = addInfoAnnouncement(sessionId, resourceId, a_num,
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
			} else if (status != SA_OK) {
				e_trace();
				retval = SAF_TEST_UNRESOLVED;
			} else {
				retval =
				    run_mismatch(sessionId, resourceId, a_num);
				deleteAnnouncement(sessionId, resourceId, a_num,
						   &announcement2);
			}
			deleteAnnouncement(sessionId, resourceId, a_num,
					   &announcement1);
		}
		restoreMode(sessionId, resourceId, a_num, mode);
	}

	return retval;
}

/*************************************************************************
 *
 * If we have at least two announcements in the Annunciator, then we can
 * simply run the test.  If not, then we will need to add some 
 * announcements.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int retval;
	int count;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;

	status = getAnnouncementCount(sessionId, resourceId, a_num,
				      SAHPI_ALL_SEVERITIES, SAHPI_FALSE,
				      &count);
	if (status != SA_OK) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (count >= 2) {
		retval = run_mismatch(sessionId, resourceId, a_num);
	} else {
		retval = add_and_run_mismatch(sessionId, resourceId, annunRec);
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
