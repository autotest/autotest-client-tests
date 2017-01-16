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
 * Function:        saHpiAnnunciatorDelete
 * Description:
 *   Attempt to delete all of the announcements in the Annunciator table
 *   by setting the EntryId to SAHPI_ENTRY_UNSPECIFIED and Severity to
 *   SAHPI_ALL_SEVERITIES.
 *   Expected return: SA_OK.
 * Line:        P128-36:P128-38
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Delete ALL of the announcements in the Annunciator.  To really test
 * things, add one announcement of each severity.  It is expected that
 * all will be deleted.  Also, verify that all announcements have actually
 * been deleted.
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
	SaHpiBoolT empty;
	AnnouncementSet announcementSet;

	status = setWriteMode(sessionId, resourceId, annunRec, &mode);
	if (status == ANNUN_ERROR) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (status == ANNUN_READONLY) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {

		status =
		    addSeverityAnnouncements(sessionId, resourceId, a_num,
					     &announcementSet);

		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {
			status = saHpiAnnunciatorDelete(sessionId, resourceId,
							a_num,
							SAHPI_ENTRY_UNSPECIFIED,
							SAHPI_ALL_SEVERITIES);

			if (status != SA_OK) {
				retval = SAF_TEST_FAIL;
				e_print(saHpiAnnunciatorDelete, SA_OK, status);
			} else {
				status =
				    isEmpty(sessionId, resourceId, a_num,
					    &empty);
				if (status != SA_OK) {
					e_trace();
					retval = SAF_TEST_UNRESOLVED;
				} else if (empty) {
					retval = SAF_TEST_PASS;
				} else {
					retval = SAF_TEST_FAIL;
					m_print
					    ("saHpiAnnunciatorDelete failed to remove all announcements!");
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
