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
 *   Call saHpiRdrGetByInstrumentId to retrieve all Rdr in each resource.
 *   Expected return: SA_OK.
 * Line:        P76-34:P76-36
 */
#include <stdio.h>
#include "saf_test.h"

SaHpiBoolT isSameRdr(SaHpiRdrT * rdr1, SaHpiRdrT * rdr2)
{
	if (rdr1->RecordId != rdr2->RecordId) {
		return SAHPI_FALSE;
	} else if (rdr1->RdrType != rdr2->RdrType) {
		return SAHPI_FALSE;
	} else if (rdr1->RdrType == SAHPI_CTRL_RDR) {
		if (rdr1->RdrTypeUnion.CtrlRec.Num !=
		    rdr2->RdrTypeUnion.CtrlRec.Num) {
			return SAHPI_FALSE;
		}
	} else if (rdr1->RdrType == SAHPI_SENSOR_RDR) {
		if (rdr1->RdrTypeUnion.SensorRec.Num !=
		    rdr2->RdrTypeUnion.SensorRec.Num) {
			return SAHPI_FALSE;
		}
	} else if (rdr1->RdrType == SAHPI_INVENTORY_RDR) {
		if (rdr1->RdrTypeUnion.InventoryRec.IdrId !=
		    rdr2->RdrTypeUnion.InventoryRec.IdrId) {
			return SAHPI_FALSE;
		}
	} else if (rdr1->RdrType == SAHPI_WATCHDOG_RDR) {
		if (rdr1->RdrTypeUnion.WatchdogRec.WatchdogNum !=
		    rdr2->RdrTypeUnion.WatchdogRec.WatchdogNum) {
			return SAHPI_FALSE;
		}
	} else if (rdr1->RdrType == SAHPI_ANNUNCIATOR_RDR) {
		if (rdr1->RdrTypeUnion.AnnunciatorRec.AnnunciatorNum !=
		    rdr2->RdrTypeUnion.AnnunciatorRec.AnnunciatorNum) {
			return SAHPI_FALSE;
		}
	}

	return SAHPI_TRUE;
}

int check_rdr(SaHpiRdrT * pRdr)
{
	int ret = 0;
	if (pRdr->RdrType <= SAHPI_NO_RECORD
	    || pRdr->RdrType > SAHPI_ANNUNCIATOR_RDR) {
		m_print("rdr.RdrType invalid = %d", pRdr->RdrType);
		ret = -1;
	}

	switch (pRdr->RdrType) {
	case SAHPI_SENSOR_RDR:
		{
			SaHpiSensorRecT *sensorRec;
			sensorRec = &(pRdr->RdrTypeUnion.SensorRec);
			if (sensorRec->Type < SAHPI_TEMPERATURE
			    || sensorRec->Type > SAHPI_OEM_SENSOR) {
				m_print
				    ("Rdr->RdrTypeUnion.SensorRec.Type illegal, %d",
				     sensorRec->Type);
				ret = -1;
			}
			if (sensorRec->Type > SAHPI_OPERATIONAL
			    && sensorRec->Type < SAHPI_OEM_SENSOR) {
				m_print
				    ("Rdr->RdrTypeUnion.SensorRec.Type illegal, %d",
				     sensorRec->Type);
				ret = -1;
			}
			if (sensorRec->Type > SAHPI_BATTERY
			    && sensorRec->Type < SAHPI_OPERATIONAL) {
				m_print
				    ("Rdr->RdrTypeUnion.SensorRec.Type illegal, %d",
				     sensorRec->Type);
				ret = -1;
			}
			if (sensorRec->Type > SAHPI_OPERATIONAL
			    && sensorRec->Type < SAHPI_OEM_SENSOR) {
				m_print
				    ("Rdr->RdrTypeUnion.SensorRec.Type illegal, %d",
				     sensorRec->Type);
				ret = -1;
			}
			if (sensorRec->EventCtrl < SAHPI_SEC_PER_EVENT
			    || sensorRec->EventCtrl > SAHPI_SEC_READ_ONLY) {
				m_print
				    ("Rdr->RdrTypeUnion.SensorRec.EventCtrl illegal, %d",
				     sensorRec->EventCtrl);
				ret = -1;
			}
			break;
		}
	case SAHPI_CTRL_RDR:
		{
			SaHpiCtrlRecT *ctrlRec;
			ctrlRec = &(pRdr->RdrTypeUnion.CtrlRec);
			if (ctrlRec->Type < SAHPI_CTRL_TYPE_DIGITAL
			    || ctrlRec->Type > SAHPI_CTRL_TYPE_OEM) {
				m_print
				    ("Rdr->RdrTypeUnion.CtrlRec.Type illegal, %d",
				     ctrlRec->Type);
				ret = -1;
			}
			if (ctrlRec->Type > SAHPI_CTRL_TYPE_TEXT
			    && ctrlRec->Type < SAHPI_CTRL_TYPE_OEM) {
				m_print
				    ("Rdr->RdrTypeUnion.CtrlRec.Type illegal, %d",
				     ctrlRec->Type);
				ret = -1;
			}

			if (ctrlRec->OutputType < SAHPI_CTRL_GENERIC
			    || ctrlRec->OutputType > SAHPI_CTRL_OEM) {
				m_print
				    ("Rdr->RdrTypeUnion.CtrlRec.OutputType illegal, %d",
				     ctrlRec->OutputType);
				ret = -1;
			}
			if (ctrlRec->DefaultMode.Mode < SAHPI_CTRL_MODE_AUTO
			    || ctrlRec->DefaultMode.Mode >
			    SAHPI_CTRL_MODE_MANUAL) {
				m_print
				    ("Rdr->RdrTypeUnion.CtrlRec.DefaultMode.Mode illegal, %d",
				     ctrlRec->DefaultMode.Mode);
				ret = -1;
			}
			break;
		}
	case SAHPI_INVENTORY_RDR:
		{
			SaHpiInventoryRecT *invRec;
			invRec = &(pRdr->RdrTypeUnion.InventoryRec);
			break;
		}
	case SAHPI_WATCHDOG_RDR:
		{
			SaHpiWatchdogRecT *wtdRec;
			wtdRec = &(pRdr->RdrTypeUnion.WatchdogRec);
			break;
		}
	case SAHPI_ANNUNCIATOR_RDR:
		{
			SaHpiAnnunciatorRecT *annRec;
			annRec = &(pRdr->RdrTypeUnion.AnnunciatorRec);
			if (annRec->AnnunciatorType < SAHPI_ANNUNCIATOR_TYPE_LED
			    || annRec->AnnunciatorType >
			    SAHPI_ANNUNCIATOR_TYPE_OEM) {
				m_print
				    ("Rdr->RdrTypeUnion.annRec.AnnunciatorType illegal, %d",
				     annRec->AnnunciatorType);
				ret = -1;
			}
			break;
		}
	case SAHPI_NO_RECORD:
		break;
	}
	return ret;
}

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
				m_print("No Rdr Record found. Return value: %s",
					get_error_string(status));
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
								   Type, Id,
								   &newRdr);
				if (status != SA_OK) {
					e_print(saHpiRdrGetByInstrumentId,
						SA_OK, status);
					retval = SAF_TEST_FAIL;
					break;
				}
				if (!isSameRdr(&newRdr, &Rdr)) {
					m_print
					    ("New get Rdr is different from original one.");
					retval = SAF_TEST_FAIL;
					break;
				}
				if (check_rdr(&newRdr) < 0) {
					m_print("check_rdr failed!");
					retval = SAF_TEST_FAIL;
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
