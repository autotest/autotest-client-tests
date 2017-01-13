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
 *   Call saHpiRdrGetByInstrumentId passing a not-present InstrumentId.
 *   Expected return: SA_ERR_HPI_NOT_PRESENT.
 * Line:        P76-27:P76-28
 */
#include <stdio.h>
#include "saf_test.h"

#define UNLIKELY_INSTRUMENT_ID 0xDEADBEEF

int Test_Resource(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
		  callback2_t func)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEntryIdT CurrRdr, NextRdr;
	SaHpiRdrT Rdr, newRdr;
	SaHpiInstrumentIdT Id;
	SaHpiRdrTypeT Type;
	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_RDR) {
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

			switch (Type) {
			case SAHPI_SENSOR_RDR:
				Id = (SaHpiInstrumentIdT) Rdr.RdrTypeUnion.
				    SensorRec.Num;
				break;
			case SAHPI_CTRL_RDR:
				Id = (SaHpiInstrumentIdT) Rdr.RdrTypeUnion.
				    CtrlRec.Num;
				break;
			case SAHPI_INVENTORY_RDR:
				Id = (SaHpiInstrumentIdT) Rdr.RdrTypeUnion.
				    InventoryRec.IdrId;
				break;
			case SAHPI_WATCHDOG_RDR:
				Id = (SaHpiInstrumentIdT) Rdr.RdrTypeUnion.
				    WatchdogRec.WatchdogNum;
				break;
			case SAHPI_ANNUNCIATOR_RDR:
				Id = (SaHpiInstrumentIdT) Rdr.RdrTypeUnion.
				    AnnunciatorRec.AnnunciatorNum;
				break;
			default:
				break;
			}

			if (Type != SAHPI_NO_RECORD) {
				status = saHpiRdrGetByInstrumentId(session_id,
								   rpt_entry.
								   ResourceId,
								   Type,
								   UNLIKELY_INSTRUMENT_ID,
								   &newRdr);
				if (status != SA_ERR_HPI_NOT_PRESENT) {
					e_print(saHpiRdrGetByInstrumentId,
						SA_ERR_HPI_NOT_PRESENT, status);
					retval = SAF_TEST_FAIL;
					break;
				} else {
					retval = SAF_TEST_PASS;
					break;
				}

			}
		}
		if (retval == SAF_TEST_UNKNOWN)
			retval = SAF_TEST_PASS;
	} else			//Resource Does not support RDR's
		retval = SAF_TEST_NOTSUPPORT;
	return (retval);

}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(Test_Resource, NULL, NULL);

	return ret;
}
