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
 * Function:    saHpiAnnunciatorAcknowledge
 * Description:
 *   Attempt to acknowledge an announcement and then
 *   verify that the Acknowledged flag is set to true.
 *   Expected return: SA_OK.
 * Line:        P125-34:P125-34
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Get the announcement and determine if it its Acknowledged field
 * is set to true as expected.
 *
 *************************************************************************/

int check_acknowledgement(SaHpiSessionIdT sessionId,
			  SaHpiResourceIdT resourceId,
			  SaHpiAnnunciatorNumT a_num, SaHpiEntryIdT entryId)
{
	SaErrorT status;
	int retval;
	SaHpiAnnouncementT announcement;

	status = saHpiAnnunciatorGet(sessionId, resourceId, a_num,
				     entryId, &announcement);
	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiAnnunciatorAcknowledge, SA_OK, status);
	} else if (announcement.Acknowledged) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		m_print("The Acknowledged field was not set to true.");
	}

	return retval;
}

/*************************************************************************
 *
 * Add an announcement and then acknowledge it.  After acknowledging it,
 * check to see if it's Acknowledged field is set to true as it is expected.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int retval;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiAnnouncementT announcement;
	SaHpiAnnunciatorModeT old_mode;

	status = setWriteMode(sessionId, resourceId, annunRec, &old_mode);
	if (status == ANNUN_ERROR) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (status == ANNUN_READONLY) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {
		status =
		    addInfoAnnouncement(sessionId, resourceId, a_num,
					&announcement);

		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {
			status = acknowledgeAnnouncement(sessionId, resourceId,
							 a_num, &announcement);

			if (status != SA_OK) {
				e_trace();
				retval = SAF_TEST_UNRESOLVED;
			} else {
				retval =
				    check_acknowledgement(sessionId, resourceId,
							  a_num,
							  announcement.EntryId);
			}

			deleteAnnouncement(sessionId, resourceId, a_num,
					   &announcement);
		}
		restoreMode(sessionId, resourceId, a_num, old_mode);
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
