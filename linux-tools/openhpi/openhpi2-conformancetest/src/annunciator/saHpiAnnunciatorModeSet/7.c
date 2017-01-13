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
 * Function:    saHpiAnnunciatorModeSet
 * Description:
 *   Attempt to change the mode for a Read Only Annunciator.
 *   Expected return: SA_ERR_HPI_READ_ONLY.
 * Line:        P131-30:P131-30
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Try setting the mode for an Annunciator whose mode is Read-Only.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;

	if (annunRec->ModeReadOnly) {

		status = saHpiAnnunciatorModeSet(sessionId, resourceId,
						 a_num,
						 SAHPI_ANNUNCIATOR_MODE_SHARED);

		if (status == SA_ERR_HPI_READ_ONLY) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiAnnunciatorModeSet, SA_ERR_HPI_READ_ONLY,
				status);
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
