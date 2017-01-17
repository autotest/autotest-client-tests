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
 *   Attempt to acknowledge an announcement with a specific
 *   EntryId and an unmatched Severity.  The severity should
 *   be ignored.
 *   Expected return: SA_OK.
 * Line:        P126-8:P126-8
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Acknowledge an INFORMATIONAL announcement with a different severity 
 * level, i.e. CRITICAL.  The severity level should be ignored.
 *
 *************************************************************************/

int do_acknowledgement(SaHpiSessionIdT sessionId,
		       SaHpiResourceIdT resourceId,
		       SaHpiAnnunciatorNumT a_num,
		       SaHpiAnnouncementT * announcement)
{
	int retval;
	SaErrorT status;

	status = saHpiAnnunciatorAcknowledge(sessionId, resourceId, a_num,
					     announcement->EntryId,
					     SAHPI_CRITICAL);

	if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiAnnunciatiorAcknowledge, SA_OK, status);
	}

	return retval;
}

/*************************************************************************
 *
 * Add an INFORMATIONAL announcement and then try to explicity acknowledge
 * that announcement, but using a severity level of CRITICAL.  This is a 
 * valid operation since the severity must be ignored when a specific
 * announcement is being acknowledged.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
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
			retval =
			    do_acknowledgement(sessionId, resourceId, a_num,
					       &announcement);
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
