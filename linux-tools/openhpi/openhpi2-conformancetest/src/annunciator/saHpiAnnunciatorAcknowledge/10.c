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
 *   Attempt to acknowledge all of the announcements with a specific
 *   severity and then verify that the Acknowledged field has been set to true.
 *   Expected return: SA_OK
 * Line:        P126-1:P126-2
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Acknowledge all announcements of a particular severity level.
 *
 *************************************************************************/

SaErrorT acknowledge_anouncements(SaHpiSessionIdT sessionId,
				  SaHpiResourceIdT resourceId,
				  SaHpiAnnunciatorNumT a_num,
				  SaHpiSeverityT severity)
{
	SaErrorT status;

	status = saHpiAnnunciatorAcknowledge(sessionId, resourceId, a_num,
					     SAHPI_ENTRY_UNSPECIFIED, severity);

	if (status != SA_OK) {
		e_print(saHpiAnnunciatorAcknowledge, SA_OK, status);
	}

	return status;
}

/*************************************************************************
 *
 * Check each announcement of a specific severity in the Annunciator Table 
 * to verify that it's Acknowledged field has been set to true.
 *
 *************************************************************************/

int check_announcements(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiAnnunciatorNumT a_num, SaHpiSeverityT severity)
{
	SaErrorT status = SA_OK;
	int retval = SAF_TEST_PASS;
	SaHpiAnnouncementT announcement;

	announcement.EntryId = SAHPI_FIRST_ENTRY;

	while (status == SA_OK) {

		status = saHpiAnnunciatorGetNext(sessionId, resourceId, a_num,
						 severity, SAHPI_FALSE,
						 &announcement);

		if (status == SA_OK) {
			if (!announcement.Acknowledged) {
				retval = SAF_TEST_FAIL;
				m_print
				    ("The Acknowledged field has not been set to true.");
				break;
			}
		} else if (status != SA_ERR_HPI_NOT_PRESENT) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiAnnunciatorGetNext,
				SA_OK | SA_ERR_HPI_NOT_PRESENT, status);
		}
	}

	return retval;
}

/*************************************************************************
 *
 * Run the actual test by first acknowledging all of the announcements
 * of a specific severity and then verifying that they actually were 
 * acknowledged.
 *
 *************************************************************************/

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId,
	     SaHpiAnnunciatorNumT a_num, SaHpiSeverityT severity)
{
	SaErrorT status;
	int retval;

	status =
	    acknowledge_anouncements(sessionId, resourceId, a_num, severity);
	if (status != SA_OK) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else {
		retval =
		    check_announcements(sessionId, resourceId, a_num, severity);
	}

	return retval;
}

/*************************************************************************
 *
 * Test each valid severity level.  Stop testing prematurely if any
 * failure occurs for any severity level.
 *
 *************************************************************************/

int run_all_tests(SaHpiSessionIdT sessionId,
		  SaHpiResourceIdT resourceId, SaHpiAnnunciatorNumT a_num)
{
	int i;
	int retval = SAF_TEST_PASS;
	int severityCount;
	SaHpiSeverityT *severity;

	severity = getValidSeverities(&severityCount);
	for (i = 0; i < severityCount; i++) {
		retval = run_test(sessionId, resourceId, a_num, severity[i]);
		if (retval == SAF_TEST_PASS) {
			break;
		}
	}

	return retval;
}

/*************************************************************************
 *
 * For a complete test, try to add five announcements, one for each
 * severity level.  Then acknowledge announcements based upon severity
 * level and verify that the announcement was acknowledged.
 *
 * For read-only Annunciator Tables, we cannot add any announcements, but
 * we can still try running the tests on any announcements that may be
 * there.  This test is not as comprehensive, but it is the best that can
 * be done for this case.
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
	AnnouncementSet announcementSet;

	status = setWriteMode(sessionId, resourceId, annunRec, &mode);
	if (status == ANNUN_ERROR) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (status == ANNUN_READONLY) {
		retval = run_all_tests(sessionId, resourceId, a_num);
	} else {

		status =
		    addSeverityAnnouncements(sessionId, resourceId, a_num,
					     &announcementSet);
		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {
			retval = run_all_tests(sessionId, resourceId, a_num);
		}

		deleteAnnouncements(sessionId, resourceId, a_num,
				    &announcementSet);
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
