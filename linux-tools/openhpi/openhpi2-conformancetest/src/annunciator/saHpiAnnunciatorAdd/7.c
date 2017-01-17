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
 * Function:    saHpiAnnunciatorAdd
 * Description:   
 *   Add an announcement using an invalid StatusCond.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P127-25:P127-25
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Try adding an announcement with an invalid StatusCond Type. 
 *
 *************************************************************************/

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId,
	     SaHpiAnnunciatorNumT a_num, SaHpiStatusCondTypeT invalidCondType)
{
	SaErrorT status;
	int retval;

	info_announcement.StatusCond.Type = invalidCondType;

	status =
	    saHpiAnnunciatorAdd(sessionId, resourceId, a_num,
				&info_announcement);

	if (status == SA_ERR_HPI_INVALID_PARAMS) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiAnnunciatorAdd, SA_ERR_HPI_INVALID_PARAMS, status);
	}

	return retval;
}

/*************************************************************************
 *
 * The only valid StatusCond Type is USER when adding an announcement.  
 * Thus, try some invalid ones and verify that the appropriate error 
 * return code is returned.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	SaErrorT status;
	int i;
	int retval;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiAnnunciatorModeT mode;
	SaHpiStatusCondTypeT invalidCondType[] =
	    { SAHPI_STATUS_COND_TYPE_SENSOR,
		SAHPI_STATUS_COND_TYPE_RESOURCE,
		SAHPI_STATUS_COND_TYPE_OEM,
		BAD_STATUS_COND_TYPE
	};

	status = setWriteMode(sessionId, resourceId, annunRec, &mode);
	if (status == ANNUN_ERROR) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (status == ANNUN_READONLY) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {

		for (i = 0; i < 4; i++) {
			retval =
			    run_test(sessionId, resourceId, a_num,
				     invalidCondType[i]);
			if (retval != SAF_TEST_PASS) {
				break;
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
