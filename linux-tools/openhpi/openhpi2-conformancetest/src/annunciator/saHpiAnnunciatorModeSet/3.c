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
 * Function:    saHpiAnnunciatorModeSet
 * Description:
 *   Test setting the valid modes.
 *   Expected return: SA_OK.
 * Line:        P131-2:P131-4
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * If the Annunciator is not in Read-Only mode, then we should be able
 * to set it's mode to any of the three valid modes.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	int i;
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiAnnunciatorModeT savedMode;
	SaHpiAnnunciatorModeT mode[] = { SAHPI_ANNUNCIATOR_MODE_AUTO,
		SAHPI_ANNUNCIATOR_MODE_USER,
		SAHPI_ANNUNCIATOR_MODE_SHARED
	};
	int len = sizeof(mode) / sizeof(mode[0]);

	// If the Annunciator's mode is Read Only, then it is impossible
	// to change the mode.

	if (!annunRec->ModeReadOnly) {

		// Get the initial mode so we can restore it later.

		status = getMode(sessionId, resourceId, a_num, &savedMode);

		if (status != SA_OK) {
			e_trace();
			retval = SAF_TEST_UNRESOLVED;
		} else {

			retval = SAF_TEST_PASS;
			for (i = 0; i < len; i++) {
				status =
				    saHpiAnnunciatorModeSet(sessionId,
							    resourceId, a_num,
							    mode[i]);
				if (status != SA_OK) {
					retval = SAF_TEST_FAIL;
					e_print(saHpiModeSet, SA_OK, status);
					break;
				}
			}
			setMode(sessionId, resourceId, a_num, savedMode);
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
