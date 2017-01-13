/*
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005, Intel Corporation
 * Copyright (c) 2005, University of New Hampshire
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
 *     Donald Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogEntryAdd
 * Description: Add entries to all of the the event logs. 
 * saHpiEventLogEntryAdd() returns SA_OK.
 * Line:        P51-16:P51-16
 */

#include <stdio.h>
#include <string.h>
#include "saf_test.h"

SaHpiBoolT sameUserEventData(SaHpiEventT * event1, SaHpiEventT * event2)
{
    int i;
    SaHpiBoolT isSame = SAHPI_TRUE;

    SaHpiTextBufferT *buf1 =
        &(event1->EventDataUnion.UserEvent.UserEventData);
    SaHpiTextBufferT *buf2 =
        &(event2->EventDataUnion.UserEvent.UserEventData);

    if (buf1->DataType != buf2->DataType) {
        isSame = SAHPI_FALSE;
    } else if (buf1->Language != buf2->Language) {
        isSame = SAHPI_FALSE;
    } else if (buf1->DataLength != buf2->DataLength) {
        isSame = SAHPI_FALSE;
    } else {
        for (i = 0; i < buf1->DataLength && !isSame; i++) {
            if (buf1->Data[i] != buf2->Data[i]) {
                isSame = SAHPI_FALSE;
            }
        }
    }

    return isSame;
}

SaHpiBoolT sameUserEvent(SaHpiEventT * event1, SaHpiEventT * event2)
{
    SaHpiBoolT isSame = SAHPI_TRUE;

    if (event1->Source != event2->Source) {
        isSame = SAHPI_FALSE;
    } else if (event1->EventType != event2->EventType) {
        isSame = SAHPI_FALSE;
    } else if (event1->Severity != event2->Severity) {
        isSame = SAHPI_FALSE;
    } else if (event1->Timestamp != event2->Timestamp) {
        isSame = SAHPI_FALSE;
    } else {
        isSame = sameUserEventData(event1, event2);
    }

    return isSame;
}

#define TEST_STR  "Event log test str"

int testEventLog(SaHpiSessionIdT session_id, SaHpiResourceIdT resourceId, char *name)
{
    SaHpiEventLogEntryIdT prev_entry_id;
    SaHpiEventLogEntryIdT next_entry_id;
    SaHpiEventLogEntryT entry_get;
    SaHpiEventT entry_add;
    SaHpiRdrT rdr;
    SaHpiRptEntryT rpt_entry;
    SaHpiBoolT enable_old;
    SaHpiBoolT temporarly_disabled = SAHPI_FALSE;
    SaErrorT error;
    int retval = SAF_TEST_UNKNOWN;
    SaHpiEventLogInfoT info;

    /* Disable event log state, to ensure entry is newest eventlog entry */
    error = saHpiEventLogStateGet(session_id, resourceId, &enable_old);
    if (error != SA_OK) {
        retval = SAF_TEST_UNRESOLVED;
        e_print(saHpiEventLogStateGet, SA_OK, error);
    } else {
        if (enable_old) {
            error = saHpiEventLogStateSet(session_id, resourceId, SAHPI_FALSE);
            if (error == SA_OK) {
                temporarly_disabled = SAHPI_TRUE;
            } else {
                retval = SAF_TEST_UNRESOLVED;
                e_print(saHpiEventLogStateSet, SA_OK, error);
            }
        }

        if (retval == SAF_TEST_UNKNOWN) {
            error = saHpiEventLogInfoGet(session_id, resourceId, &info);
            if (error != SA_OK) {
                retval = SAF_TEST_UNRESOLVED;
                e_print(saHpiEventLogInfoGet, SA_OK, error);
            } else {
                if (info.Entries >= info.Size) {
                    // If the event log is full
                    error = saHpiEventLogClear(session_id, rpt_entry.ResourceId);
                    if (error != SA_OK) {
                        retval = SAF_TEST_UNRESOLVED;
                        e_print(saHpiEventLogInfoGet, SA_OK, error);
                    }
                }

                if (retval == SAF_TEST_UNKNOWN) {
                    entry_add.Source = SAHPI_UNSPECIFIED_RESOURCE_ID;
                    entry_add.EventType = SAHPI_ET_USER;
                    entry_add.Timestamp = SAHPI_TIME_UNSPECIFIED;
                    entry_add.Severity = SAHPI_OK;
                    memcpy(entry_add.EventDataUnion.UserEvent.UserEventData.Data,
                                       TEST_STR, sizeof(TEST_STR));
                    entry_add.EventDataUnion.UserEvent.UserEventData.DataType =
                        SAHPI_TL_TYPE_TEXT;
                    entry_add.EventDataUnion.UserEvent.UserEventData.Language =
                        SAHPI_LANG_ENGLISH;
                    entry_add.EventDataUnion.UserEvent.UserEventData.DataLength =
                        (SaHpiUint8T) sizeof(TEST_STR);

                    error = saHpiEventLogEntryAdd(session_id, resourceId, &entry_add);
                    if (error != SA_OK) {
                        retval = SAF_TEST_FAIL;
                        e_print(saHpiEventLogStateSet, SA_OK, error);
                    } else {
                        error = saHpiEventLogEntryGet(session_id, resourceId,
                                                      SAHPI_NEWEST_ENTRY, &prev_entry_id,
                                                      &next_entry_id, &entry_get, &rdr,
                                                      &rpt_entry);
                        if (error != SA_OK) {
                            retval = SAF_TEST_FAIL;
                            e_print(saHpiEventLogEntryGet, SA_OK, error);
                        } else if (!sameUserEvent(&entry_add, &entry_get.Event)) {
                            retval = SAF_TEST_FAIL;
                            m_print("Added event log entry is invalid! (%s)!", name);
                       } else {
                            retval = SAF_TEST_PASS;
                       }
                   }
                }
            }
        }

        // Clean-up
        if (temporarly_disabled) {
            error = saHpiEventLogStateSet(session_id, resourceId, enable_old);
            if (error != SA_OK) {
                e_print(saHpiEventLogStateSet, SA_OK, error);
            }
        }
    }

    return retval;
}

int Test_Domain(SaHpiSessionIdT sessionId)
{
    return testEventLog(sessionId, SAHPI_UNSPECIFIED_RESOURCE_ID, "Domain");
}

int Test_Resource(SaHpiSessionIdT sessionId, SaHpiRptEntryT rpt_entry,
          callback2_t func)
{
    int retval = SAF_TEST_NOTSUPPORT;
    char name[200];

    if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_EVENT_LOG) {
        sprintf(name, "Resource 0x%X", rpt_entry.ResourceId);
        retval = testEventLog(sessionId, rpt_entry.ResourceId, name);
    }

    return retval;
}

int main()
{
    int ret = SAF_TEST_UNKNOWN;

    ret = process_all_domains(Test_Resource, NULL, Test_Domain);

    return ret;
}
