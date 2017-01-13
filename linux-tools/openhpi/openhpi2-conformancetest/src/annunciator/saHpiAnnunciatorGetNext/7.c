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
 *   Test an invalid severity.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P122-27:P122-27
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Test the given invalid severity.
 *
 *************************************************************************/

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId,
	     SaHpiAnnunciatorNumT a_num, SaHpiSeverityT invalidSeverity)
{
	SaErrorT status;
	int retval;
	SaHpiAnnouncementT announcement;

	announcement.EntryId = SAHPI_FIRST_ENTRY;

	status = saHpiAnnunciatorGetNext(sessionId, resourceId, a_num,
					 invalidSeverity, SAHPI_FALSE,
					 &announcement);

	if (status == SA_ERR_HPI_INVALID_PARAMS) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiAnnunciatorGetNext, SA_ERR_HPI_INVALID_PARAMS,
			status);
	}

	return retval;
}

/*************************************************************************
 *
 * Test an invalid severity.  
 *
 * NOTE: Using a loop makes it easy to add new invalid severities
 *       in the future.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	int i;
	int retval;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiSeverityT invalidSeverity[] = { BAD_SEVERITY };

	for (i = 0; i < (sizeof(invalidSeverity) / sizeof(SaHpiSeverityT)); i++) {
		retval =
		    run_test(sessionId, resourceId, a_num, invalidSeverity[i]);
		if (retval != SAF_TEST_PASS) {
			break;
		}
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
