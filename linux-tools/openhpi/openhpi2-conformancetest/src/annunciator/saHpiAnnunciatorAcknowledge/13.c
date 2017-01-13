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
 *   Acknowledge all announcements of a specific severity, 
 *   but there are not such announcements of that severity.
 *   Expected return: SA_OK
 * Line:        P126-9:P126-10
 */

#include <stdio.h>
#include "../include/annun_test.h"

/*************************************************************************
 *
 * Start by finding all of the severities that are not being used by
 * any of the announcements in the Annunciator Table.  If we can find one
 * or more, then then we can try to acknowledge all announcements of 
 * those severities.  
 *
 * FUTURE: A possible improvement to this test is with regard to when
 *         we can't find an unused severity.  Perhaps delete all 
 *         informational announcements and then run the test.
 *
 *************************************************************************/

int processAnnunRdr(SaHpiSessionIdT sessionId,
		    SaHpiResourceIdT resourceId,
		    SaHpiRdrT * rdr, SaHpiAnnunciatorRecT * annunRec)
{
	int i;
	SaErrorT status;
	int retval;
	SaHpiAnnunciatorNumT a_num = annunRec->AnnunciatorNum;
	SaHpiSeverityT severity[SEVERITY_COUNT];
	int count;

	status = getUnusedSeverities(sessionId, resourceId, a_num,
				     SAHPI_FALSE, severity, &count);
	if (status != SA_OK) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (count == 0) {
		retval = SAF_TEST_NOTSUPPORT;	// can't find an unused severity
	} else {
		retval = SAF_TEST_PASS;
		for (i = 0; i < count; i++) {
			status =
			    saHpiAnnunciatorAcknowledge(sessionId, resourceId,
							a_num,
							SAHPI_ENTRY_UNSPECIFIED,
							severity[i]);

			if (status != SA_OK) {
				e_print(saHpiAnnunciatiorAcknowledge, SA_OK,
					status);
				m_print("Severity = %s",
					get_severity_str(severity[i]));
				retval = SAF_TEST_FAIL;
				break;
			}
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
