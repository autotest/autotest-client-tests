/*
 * (C) Copyright University of New Hampshire 2005
 * (C) Copyright 2005, Intel Corporation
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
 *     Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAnnunciatorModeGet
 * Description:
 *   Attempt to retrieve the mode from all of the annunciators.
 *   Verify that the mode is one of the three legal values: 
 *   Auto, User, or Shared.
 *   Expected return: SA_OK.
 * Line:        P130-2:P130-4
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Determine if the given mode is valid or not.
 *
 *************************************************************************/

int isValidMode(SaHpiAnnunciatorModeT mode)
{
	return ((mode == SAHPI_ANNUNCIATOR_MODE_AUTO) ||
		(mode == SAHPI_ANNUNCIATOR_MODE_USER) ||
		(mode == SAHPI_ANNUNCIATOR_MODE_SHARED));
}

/*************************************************************************
 *
 * Verify that we can obtain the mode and that the mode is valid.
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

	status = saHpiAnnunciatorModeGet(sessionId, resourceId, a_num, &mode);

	if (status != SA_OK) {
		retval = SAF_TEST_FAIL;
		e_print(saHpiAnnunciatorModeGet, SA_OK, status);
	} else if (!isValidMode(mode)) {
		retval = SAF_TEST_FAIL;
		m_print
		    ("saHpiAnnunciatorModeGet returned an invalid annunciator mode %d!\n",
		     mode);
	} else {
		retval = SAF_TEST_PASS;
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
