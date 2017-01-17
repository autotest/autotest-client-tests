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
 * Function:    saHpiAnnunciatorAcknowledge
 * Description:
 *   Acknowledge announcements by passing in SAHPI_ENTRY_UNSPECIFIED
 *   as the EntryId and a Severity that is out-of-range.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P125-27:P125-28
 *
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Test acknowledgement with a bad severity.
 *
 *************************************************************************/

int runTest(SaHpiSessionIdT sessionId,
	    SaHpiResourceIdT resourceId,
	    SaHpiAnnunciatorNumT a_num, SaHpiSeverityT bad_severity)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;

	status = saHpiAnnunciatorAcknowledge(sessionId, resourceId, a_num,
					     SAHPI_ENTRY_UNSPECIFIED,
					     bad_severity);

	if (status == SA_ERR_HPI_INVALID_PARAMS) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiAnnunciatorAcknowledge, SA_ERR_HPI_INVALID_PARAMS,
			status);
		m_print("Severity = %s", get_severity_str(bad_severity));
	}

	return retval;
}

/*************************************************************************
 *
 * Try an invalid severity.
 *
 * NOTE: Using a loop allows us to easily add new invalid severities.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	int i;
	int retval = SAF_TEST_PASS;
	SaHpiSeverityT bad_severity[] = { BAD_SEVERITY };

	for (i = 0; i < 1; i++) {
		retval = runTest(sessionId, resourceId,
				 annunRec->AnnunciatorNum, bad_severity[i]);
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
