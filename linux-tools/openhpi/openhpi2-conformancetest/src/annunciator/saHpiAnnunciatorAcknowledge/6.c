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
 *   Acknowledge an announcement with an EntryId
 *   that does not exist in the Annunciator Table.
 *   Expected return: SA_ERR_HPI_NOT_PRESENT.
 * Line:        P125-26:P125-26
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Attempt to acknowledge an announcement with an invalid EntryId, i.e.
 * one that doesn't correspond to entry in the Annunciator Table.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiEntryIdT badEntryId;

	// Find an Entry id that does not exist in the Annunciator Table.

	status = getBadEntryId(sessionId, resourceId, a_num, &badEntryId);
	if (status != SA_OK) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else {

		status = saHpiAnnunciatorAcknowledge(sessionId, resourceId,
						     a_num, badEntryId,
						     SAHPI_INFORMATIONAL);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiAnnunciatorAcknowledge,
				SA_ERR_HPI_NOT_PRESENT, status);
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
