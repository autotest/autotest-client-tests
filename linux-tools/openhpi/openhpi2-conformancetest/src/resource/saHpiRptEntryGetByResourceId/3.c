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
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiRptEntryGetByResourceId
 * Description:  
 *      Call the function passing valid paramaters.
 *      Expected return: SA_OK.
 * Line:        P42-15:P42-15
 */
#include <stdio.h>
#include "saf_test.h"


int cmpEntity(SaHpiEntityPathT *a, SaHpiEntityPathT *b)
{
	int i;

	for (i = 0; i < SAHPI_MAX_ENTITY_PATH; i++)
	{
		if (a->Entry[i].EntityType != b->Entry[i].EntityType ||
		    a->Entry[i].EntityLocation != b->Entry[i].EntityLocation)
			return 1;

		if (a->Entry[i].EntityType == SAHPI_ENT_ROOT)
			break;
	}

	return 0;
}

SaHpiBoolT isSameRptEntry(SaHpiRptEntryT * rpt_entry,
			  SaHpiRptEntryT * rpt_entry2)
{
	if (rpt_entry->EntryId != rpt_entry2->EntryId) {
		m_print("Mismatched EntryId");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceId != rpt_entry2->ResourceId) {
		m_print("Mismatched ResourceId");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceInfo.ResourceRev !=
		   rpt_entry2->ResourceInfo.ResourceRev) {
		m_print("Mismatched ResourceInfo.ResourceRev");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceInfo.SpecificVer !=
		   rpt_entry2->ResourceInfo.SpecificVer) {
		m_print("Mismatched ResourceInfo.SpecificVer");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceInfo.DeviceSupport !=
		   rpt_entry2->ResourceInfo.DeviceSupport) {
		m_print("Mismatched ResourceInfo.DeviceSupport");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceInfo.ManufacturerId !=
		   rpt_entry2->ResourceInfo.ManufacturerId) {
		m_print("Mismatched ResourceInfo.ManufacturerId");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceInfo.ProductId !=
		   rpt_entry2->ResourceInfo.ProductId) {
		m_print("Mismatched ResourceInfo.ProductId");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceInfo.FirmwareMajorRev !=
		   rpt_entry2->ResourceInfo.FirmwareMajorRev) {
		m_print("Mismatched ResourceInfo.FirmwareMajorRev");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceInfo.FirmwareMinorRev !=
		   rpt_entry2->ResourceInfo.FirmwareMinorRev) {
		m_print("Mismatched ResourceInfo.FirmwareMinorRev");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceInfo.AuxFirmwareRev !=
		   rpt_entry2->ResourceInfo.AuxFirmwareRev) {
		m_print("Mismatched ResourceInfo.AuxFirmwareRev");
		return SAHPI_FALSE;
	} else if (memcmp(&rpt_entry->ResourceInfo.Guid,
		   &rpt_entry2->ResourceInfo.Guid,
		   sizeof(rpt_entry->ResourceInfo.Guid))) {
		m_print("Mismatched ResourceInfo.Guid");
		return SAHPI_FALSE;
	} else if (cmpEntity(&rpt_entry->ResourceEntity.Entry,
		   &rpt_entry2->ResourceEntity.Entry)) {
		m_print("Mismatched ResourceEntity.Entry");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceCapabilities !=
		   rpt_entry2->ResourceCapabilities) {
		m_print("Mismatched ResourceCapabilities");
		return SAHPI_FALSE;
	} else if (rpt_entry->HotSwapCapabilities !=
		   rpt_entry2->HotSwapCapabilities) {
		m_print("Mismatched HotSwapCapabilities");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceSeverity != rpt_entry2->ResourceSeverity) {
		m_print("Mismatched ResourceSeverity");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceFailed != rpt_entry2->ResourceFailed) {
		m_print("Mismatched ResourceFailed");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceTag.DataType !=
		   rpt_entry2->ResourceTag.DataType) {
		m_print("Mismatched ResourceTag.DataType");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceTag.Language !=
		   rpt_entry2->ResourceTag.Language) {
		m_print("Mismatched ResourceTag.Language");
		return SAHPI_FALSE;
	} else if (rpt_entry->ResourceTag.DataLength !=
		   rpt_entry2->ResourceTag.DataLength) {
		m_print("Mismatched ResourceTag.DataLength");
		return SAHPI_FALSE;
	} else if (memcmp(rpt_entry->ResourceTag.Data, 
			  rpt_entry2->ResourceTag.Data,
			  rpt_entry->ResourceTag.DataLength)) {
		m_print("Mismatched ResourceTag.Data");
		return SAHPI_FALSE;
	} else {
		return SAHPI_TRUE;
	}
}

int Test_Resource(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
		  callback2_t func)
{
	SaHpiRptEntryT rpt_entry2;
	SaErrorT val;
	int ret = SAF_TEST_PASS;

	val =
	    saHpiRptEntryGetByResourceId(session_id, rpt_entry.ResourceId,
					 &rpt_entry2);

	if (val != SA_OK) {
		e_print(saHpiRptEntryGetByResourceId, SA_OK, val);
		ret = SAF_TEST_FAIL;
	}

	if (!(isSameRptEntry(&rpt_entry, &rpt_entry2))) {
		m_print
		    ("The rpt_entry passed as a parameter to Test_Resource ");
		m_print
		    ("is not equal to the rpt_entry returned from the call ");
		m_print
		    ("to saHpiRptEntryGetByResourceId. They should be the same!");
		ret = SAF_TEST_FAIL;
	}

	return ret;
}

int main()
{
	int ret = SAF_TEST_PASS;

	ret = process_all_domains(Test_Resource, NULL, NULL);

	return ret;
}
