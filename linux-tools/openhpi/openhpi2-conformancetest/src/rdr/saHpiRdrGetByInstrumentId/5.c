/*
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005, Intel Corporation
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
 * Author(s):
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Wang Jing <jing.j.wang@intel.com>
 *      Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiRdrGetByInstrumentId 
 * Description:   
 *   Call saHpiRdrGetByInstrumentId passing a unsupported RdrType.
 *   Expected return: SA_ERR_HPI_CAPABILITY.
 * Line:        P76-25:P76-26
 */

#include <stdio.h>
#include "saf_test.h"

int CheckUnsupportedType(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
			 SaHpiRdrTypeT CheckType)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEntryIdT CurrRdr, NextRdr;
	SaHpiRdrT Rdr, newRdr;
	SaHpiRdrTypeT Type;

	NextRdr = SAHPI_FIRST_ENTRY;
	while (NextRdr != SAHPI_LAST_ENTRY) {
		CurrRdr = NextRdr;
		status = saHpiRdrGet(session_id,
				     rpt_entry.ResourceId,
				     CurrRdr, &NextRdr, &Rdr);
		if (status != SA_OK) {
			e_print(saHpiRdrGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
			break;
		}

		if ((Type = Rdr.RdrType) == SAHPI_NO_RECORD) {
			m_print("No Rdr Record found.");
			retval = SAF_TEST_UNRESOLVED;
			break;
		}

		if (Type != SAHPI_NO_RECORD && Type != CheckType) {
			status = saHpiRdrGetByInstrumentId(session_id,
							   rpt_entry.ResourceId,
							   CheckType,
							   0, &newRdr);

			if (status != SA_ERR_HPI_CAPABILITY) {
				e_print(saHpiRdrGetByInstrumentId,
					SA_ERR_HPI_CAPABILITY, status);
				retval = SAF_TEST_FAIL;
				break;
			}
			//else{
			//      retval = SAF_TEST_PASS_AND_EXIT;
			//      break;
			//}                             
		}
	}			//while rdr in resource
	if (retval == SAF_TEST_UNKNOWN)
		retval = SAF_TEST_PASS;

	return retval;

}

SaHpiBoolT isOkay(int retval)
{
	return (retval == SAF_TEST_PASS) ||
	    (retval == SAF_TEST_NOTSUPPORT) || (retval == SAF_TEST_UNKNOWN);
}

int Test_Resource(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
		  callback2_t func)
{
	int retval = SAF_TEST_NOTSUPPORT;

	if (!(rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_RDR)) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {
		if (!
		    (rpt_entry.
		     ResourceCapabilities & SAHPI_CAPABILITY_WATCHDOG)) {
			retval =
			    CheckUnsupportedType(session_id, rpt_entry,
						 SAHPI_WATCHDOG_RDR);
		}

		if (isOkay(retval) &&
		    !(rpt_entry.
		      ResourceCapabilities & SAHPI_CAPABILITY_CONTROL)) {
			retval =
			    CheckUnsupportedType(session_id, rpt_entry,
						 SAHPI_CTRL_RDR);
		}

		if (isOkay(retval) &&
		    !(rpt_entry.
		      ResourceCapabilities & SAHPI_CAPABILITY_SENSOR)) {
			retval =
			    CheckUnsupportedType(session_id, rpt_entry,
						 SAHPI_SENSOR_RDR);
		}

		if (isOkay(retval) &&
		    !(rpt_entry.
		      ResourceCapabilities & SAHPI_CAPABILITY_INVENTORY_DATA)) {
			retval =
			    CheckUnsupportedType(session_id, rpt_entry,
						 SAHPI_INVENTORY_RDR);
		}

		if (isOkay(retval) &&
		    !(rpt_entry.
		      ResourceCapabilities & SAHPI_CAPABILITY_ANNUNCIATOR)) {
			retval =
			    CheckUnsupportedType(session_id, rpt_entry,
						 SAHPI_ANNUNCIATOR_RDR);
		}
	}

	return retval;
}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(Test_Resource, NULL, NULL);

	return ret;
}
