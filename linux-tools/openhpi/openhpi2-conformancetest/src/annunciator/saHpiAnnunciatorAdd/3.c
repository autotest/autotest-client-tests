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
 * Function:    saHpiAnnunciatorAdd
 * Description:   
 *   Add announcements to each Annunciator. 
 *   Expected return: SA_OK.
 * Line:        P127-2:P127-3
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * If the Annunciator is not in ReadOnly mode, then it will be possible
 * to add announcements.  Verify that announcements can be added okay.
 * Try all of the valid severities.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	int i;
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiAnnunciatorModeT mode;
	SaHpiAnnouncementT announcement;
	SaHpiSeverityT *severity;
	int severityCount;

	status = setWriteMode(sessionId, resourceId, annunRec, &mode);
	if (status == ANNUN_ERROR) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (status == ANNUN_READONLY) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {

		// Assume that all will go well.
		// If something goes wrong, then change the return value.

		retval = SAF_TEST_PASS;

		severity = getValidSeverities(&severityCount);
		for (i = 0; i < severityCount; i++) {
			status = addAnnouncement(sessionId, resourceId, a_num,
						 severity[i], &announcement);

			if (status == SA_OK) {
				deleteAnnouncement(sessionId, resourceId, a_num,
						   &announcement);
			} else if (status == SA_ERR_HPI_OUT_OF_SPACE) {
				retval = SAF_TEST_NOTSUPPORT;
				break;
			} else {
				e_trace();
				retval = SAF_TEST_FAIL;
				break;
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
