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
 *   Attempt to delete announcements using only a valid Severity.
 *   Expected return: SA_OK.
 * Line:        P128-2:P128-4
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Try to delete all announcements with a specific severity.  In an
 * attempt to be non-destructive, we will add an announcement with a
 * severity level that isn't used by any of the other announcements.
 * If a severity cannot be found, INFORMATIONAL will be used. 
 *
 * Verify that the announcement was actually removed the Annunciator.
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
	SaHpiAnnouncementT announcement;
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
		} else {

			status = addAnnouncement(sessionId, resourceId, a_num,
						 severity, &announcement);

			if (status != SA_OK) {
				e_trace();
				retval = SAF_TEST_UNRESOLVED;
			} else {
				status =
				    saHpiAnnunciatorDelete(sessionId,
							   resourceId, a_num,
							   SAHPI_ENTRY_UNSPECIFIED,
							   severity);

				if (status != SA_OK) {
					retval = SAF_TEST_FAIL;
					e_print(saHpiAnnunciatorDelete, SA_OK,
						status);
				} else {
					status =
					    containsAnnouncement(sessionId,
								 resourceId,
								 a_num,
								 announcement.
								 EntryId,
								 &found);
					if (status != SA_OK) {
						e_trace();
						retval = SAF_TEST_UNRESOLVED;
					} else if (!found) {
						retval = SAF_TEST_PASS;
					} else {
						retval = SAF_TEST_FAIL;
						m_print
						    ("saHpiAnnunciatorDelete failed to remove announcement!");
					}
				}
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
