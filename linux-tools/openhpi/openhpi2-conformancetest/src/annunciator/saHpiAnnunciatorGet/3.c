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
 * Function:    saHpiAnnunciatorGet
 * Description:
 *   Attempt to retrieve a specific announcement using a valid EntryId.
 *   Expected return: SA_OK.
 * Line:        P124-19:P124-19
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Use saHpiAnnunciatorGetNext to traverse the entire Annunciator Table.
 * For each announcement, use it's EntryId to directly read that 
 * announcement using saHpiAnnunciatorGet.  If we don't encounter any
 * errors and we found at least one announcement in the table, then
 * this test passes.
 *
 *************************************************************************/

int run_test1(SaHpiSessionIdT sessionId,
	      SaHpiResourceIdT resourceId, SaHpiAnnunciatorNumT a_num)
{
	SaErrorT status = SA_OK;
	SaHpiAnnouncementT announcement;
	SaHpiAnnouncementT getAnnouncement;
	int retval = SAF_TEST_NOTSUPPORT;
	int count = 0;

	announcement.EntryId = SAHPI_FIRST_ENTRY;

	while (status != SA_ERR_HPI_NOT_PRESENT
	       && retval == SAF_TEST_NOTSUPPORT) {

		status = saHpiAnnunciatorGetNext(sessionId, resourceId, a_num,
						 SAHPI_ALL_SEVERITIES,
						 SAHPI_FALSE, &announcement);

		if (status == SA_OK) {

			count++;
			status =
			    saHpiAnnunciatorGet(sessionId, resourceId, a_num,
						announcement.EntryId,
						&getAnnouncement);
			if (status != SA_OK) {
				retval = SAF_TEST_FAIL;
				e_print(saHpiAnnunciatorGet, SA_OK, status);
			}

			if (memcmp
			    (&getAnnouncement, &announcement,
			     sizeof(SaHpiAnnouncementT)) != 0) {
				m_print("Announcement mismatch! ");
				retval = SAF_TEST_FAIL;
			}

		} else if (status != SA_ERR_HPI_NOT_PRESENT) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiAnnunciatorGetNext,
				SA_OK | SA_ERR_HPI_NOT_PRESENT, status);
		}
	}

	if (retval == SAF_TEST_NOTSUPPORT && count > 0) {
		retval = SAF_TEST_PASS;
	}

	return retval;
}

/*************************************************************************
 *
 * In this test, if we are able to write to the Annunciator Table, we will
 * add an announcement.  We will then have an EntryId that we can use to
 * get that announcement via saHpiAnnunciatorGet.  
 *
 *************************************************************************/

int run_test2(SaHpiSessionIdT sessionId,
	      SaHpiResourceIdT resourceId, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int retval;
	SaHpiAnnouncementT announcement;
	SaHpiAnnunciatorModeT mode;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;

	status = setWriteMode(sessionId, resourceId, annunRec, &mode);
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
			status = saHpiAnnunciatorGet(sessionId, resourceId,
						     a_num,
						     announcement.EntryId,
						     &announcement);

			if (status == SA_OK) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				e_print(saHpiAnnunciatorGet, SA_OK, status);
			}
			deleteAnnouncement(sessionId, resourceId, a_num,
					   &announcement);
		}
		restoreMode(sessionId, resourceId, a_num, mode);
	}

	return retval;
}

/*************************************************************************
 *
 * Try using test 1 first since we that doesn't require us to change the
 * contents of the Annunciator Table.  We only require that there be one
 * or more announcements already in the table.  If the table is empty, then
 * we must try test 2 that will add an announcement and then try to read
 * it back.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	int retval;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;

	retval = run_test1(sessionId, resourceId, a_num);
	if (retval == SAF_TEST_NOTSUPPORT) {
		retval = run_test2(sessionId, resourceId, annunRec);
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
