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
 *   Get all the unacknowledged announcements.
 *   Expected return: SA_OK or SA_ERR_HPI_NOT_PRESENT.
 * Line:        P122-19:P122-20
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Try retrieving all of the unacknowledged announcements.
 *
 * If we can add announcements, then add two sets of announcements of 
 * each severity.  Acknowledge one set of announcements.  This gives
 * us all possible combinations of severities and unack/acknowledged 
 * announcements.  While it would be nice to actually check that we did 
 * get the unacknowledged announcements that we added, the code is only 
 * checking to make sure we read at least one 6 announcements.  Not perfect, 
 * but probably good enough.
 *
 * If the annunciator is read-only, then simply retrieve any announcements
 * from the table that are already there.  If there are some announcements
 * then we will return PASS.  If we don't retrieve any announcements, then
 * return NOTSUPPORT.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int retval;
	int count = 0;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiAnnunciatorModeT mode;
	AnnouncementSet ackAnnouncementSet;
	AnnouncementSet unAckAnnouncementSet;

	status = setWriteMode(sessionId, resourceId, annunRec, &mode);
	if (status == ANNUN_ERROR) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (status == ANNUN_READONLY) {
		status = getAnnouncementCount(sessionId, resourceId, a_num,
					      SAHPI_ALL_SEVERITIES, SAHPI_TRUE,
					      &count);
		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_FAIL;
		} else if (count > 0) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_NOTSUPPORT;
		}
	} else {
		status = addTestAnnouncements(sessionId, resourceId, a_num,
					      &ackAnnouncementSet,
					      &unAckAnnouncementSet);

		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {
			status =
			    getAnnouncementCount(sessionId, resourceId, a_num,
						 SAHPI_ALL_SEVERITIES,
						 SAHPI_TRUE, &count);
			if (status != SA_OK) {
				e_trace();
				retval = SAF_TEST_FAIL;
			} else if (count >= SEVERITY_COUNT) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				m_print
				    ("Did not read all announcements of various severities!");
			}
		}

		deleteAnnouncements(sessionId, resourceId, a_num,
				    &ackAnnouncementSet);
		deleteAnnouncements(sessionId, resourceId, a_num,
				    &unAckAnnouncementSet);
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
