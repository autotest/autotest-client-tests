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
 *   Get all announcements of a specific severity.
 *   Expected return: SA_OK or SA_ERR_HPI_NOT_PRESENT.
 * Line:        P122-17:P122-18
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * This test is run if we can't add any announcements.  We have to
 * rely on any announcements that are currently in the table.  If we
 * able to retrieve at least one announcement for a particular severity,
 * then we will PASS.  If the table is empty, we will return NOTSUPPORT
 * since we really can't do the test.
 *
 *************************************************************************/

int run_test1(SaHpiSessionIdT sessionId,
	      SaHpiResourceIdT resourceId, SaHpiAnnunciatorNumT a_num)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	int count;
	int i;
	SaHpiSeverityT *severity;

	severity = getValidSeverities(&count);
	for (i = 0; i < count; i++) {
		status = getAnnouncementCount(sessionId, resourceId, a_num,
					      severity[i], SAHPI_FALSE, &count);
		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_FAIL;
			break;
		} else if (count > 0) {
			retval = SAF_TEST_PASS;
		}
	}

	return retval;
}

/*************************************************************************
 *
 * In this test, we can add announcements.  We will add a bunch of 
 * announcements using all of the various severities, i.e. 2 announcements
 * for each severity (acknowledged and unacknowledged).  We will then try 
 * reading the announcements for each of the valid severities.  There 
 * should be two or more announcements for each.  Keep in mind that there 
 * might already be announcements in the table.
 *
 *************************************************************************/

int run_test2(SaHpiSessionIdT sessionId,
	      SaHpiResourceIdT resourceId, SaHpiAnnunciatorNumT a_num)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	int count;
	int i;
	SaHpiSeverityT *severity;
	AnnouncementSet ackAnnouncementSet;
	AnnouncementSet unackAnnouncementSet;

	status = addTestAnnouncements(sessionId, resourceId, a_num,
				      &ackAnnouncementSet,
				      &unackAnnouncementSet);

	if (status != SA_OK) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else {
		severity = getValidSeverities(&count);
		for (i = 0; i < count; i++) {
			status =
			    getAnnouncementCount(sessionId, resourceId, a_num,
						 severity[i], SAHPI_FALSE,
						 &count);
			if (status != SA_OK) {
				e_trace();
				retval = SAF_TEST_FAIL;
				break;
			} else if (count >= 2) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				m_print
				    ("Did not read all announcements of severity %s!",
				     get_severity_str(severity[i]));
				break;
			}
		}

		deleteAnnouncements(sessionId, resourceId, a_num,
				    &ackAnnouncementSet);
		deleteAnnouncements(sessionId, resourceId, a_num,
				    &unackAnnouncementSet);
	}

	return retval;
}

/*************************************************************************
 *
 * Try retrieving announcements for a specific severity.
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

	status = setWriteMode(sessionId, resourceId, annunRec, &mode);
	if (status == ANNUN_ERROR) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (status == ANNUN_READONLY) {
		retval = run_test1(sessionId, resourceId, a_num);
	} else {
		retval = run_test2(sessionId, resourceId, a_num);
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
