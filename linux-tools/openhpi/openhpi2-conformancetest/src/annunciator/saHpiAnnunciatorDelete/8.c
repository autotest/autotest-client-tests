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
 * Function:    saHpiAnnunciatorDelete
 * Description:
 *   Attempt to delete an announcement with an EntryId that 
 *   is not contained in the Annunciator.
 *   Expected return: SA_ERR_HPI_NOT_PRESENT.
 * Line:        P128-29:P128-30
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * First, find an EntryId that does not exists in the Annunciator.
 * Then try to delete that EntryId.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int retval;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiEntryIdT bad_entryId;
	SaHpiAnnunciatorModeT mode;

	status = setWriteMode(sessionId, resourceId, annunRec, &mode);
	if (status == ANNUN_ERROR) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (status == ANNUN_READONLY) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {

		status =
		    getBadEntryId(sessionId, resourceId, a_num, &bad_entryId);
		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {
			status =
			    saHpiAnnunciatorDelete(sessionId, resourceId, a_num,
						   bad_entryId,
						   SAHPI_INFORMATIONAL);

			if (status == SA_ERR_HPI_NOT_PRESENT) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				e_print(saHpiAnnunciatorDelete,
					SA_ERR_HPI_NOT_PRESENT, status);
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
