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
 *   Use NULL for the Announcement parameter.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P124-25:P124-25
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * In test 1, we will attempt to use any announcement that is already
 * in the Annunciator Table.  In order to test the NULL parameter for
 * announcement, we must use a valid EntryId.  
 *
 *************************************************************************/

int run_test1(SaHpiSessionIdT sessionId,
	      SaHpiResourceIdT resourceId, SaHpiAnnunciatorNumT a_num)
{
	SaErrorT status;
	SaHpiAnnouncementT announcement;
	int retval = SAF_TEST_NOTSUPPORT;

	// Retrieve only the first entry in the Annunciator Table.

	announcement.EntryId = SAHPI_FIRST_ENTRY;
	status = saHpiAnnunciatorGetNext(sessionId, resourceId, a_num,
					 SAHPI_ALL_SEVERITIES, SAHPI_FALSE,
					 &announcement);

	if (status == SA_OK) {

		// If we found an announcement, use that announcement's    
		// EntryId to perform the actual test of a NULL parameter. 

		status = saHpiAnnunciatorGet(sessionId, resourceId, a_num,
					     announcement.EntryId, NULL);

		if (status == SA_ERR_HPI_INVALID_PARAMS) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiAnnunciatorGet, SA_ERR_HPI_INVALID_PARAMS,
				status);
		}
	} else if (status != SA_ERR_HPI_NOT_PRESENT) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiAnnunciatorGet, SA_OK | SA_ERR_HPI_NOT_PRESENT,
			status);
	}

	return retval;
}

/*************************************************************************
 *
 * In test 2, if we are able to, an announcement is added to the 
 * Annunciator Table.  We can then use that announcement's EntryId to
 * test a NULL parameter.  
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
		status = addInfoAnnouncement(sessionId, resourceId, a_num,
					     &announcement);
		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {
			status = saHpiAnnunciatorGet(sessionId, resourceId,
						     a_num,
						     announcement.EntryId,
						     NULL);

			if (status == SA_ERR_HPI_INVALID_PARAMS) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				e_print(saHpiAnnunciatorGet,
					SA_ERR_HPI_INVALID_PARAMS, status);
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
 * To test a NULL parameter for the announcement, we need to be sure that
 * all of the other parameters are correct, including a valid EntryId.
 * Test 1 will attempt to use an EntryId of an existing annoucement in
 * the Annunciator Table.  If the table is empty, then we try test 2
 * which will attempt to add an announcement for which we will then have
 * a valid EntryId.
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
