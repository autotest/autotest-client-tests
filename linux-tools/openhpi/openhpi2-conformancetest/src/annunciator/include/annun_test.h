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
 */

#ifndef __ANNUN_TEST
#define __ANNUN_TEST

#include "saf_test.h"

/********************************************************************************
 *
 * Bad values used by the test programs.
 *
 ********************************************************************************/

#define INVALID_ANNUNCIATOR_NUM    INVALID_RDR_NUM
#define BAD_ANNUNCIATOR_MODE       0xFE

#define BAD_SEVERITY               (SAHPI_OK + 1)
#define BAD_STATUS_COND_TYPE       0xFF
#define BAD_ENTRY_ID               0xDEADBEEF

/********************************************************************************
 *
 * Annunciator Specific error codes
 *
 ********************************************************************************/

#define ANNUN_ERR_BASE 5000

#define ANNUN_ERROR    (SaErrorT) (ANNUN_ERR_BASE + 1)
#define ANNUN_READONLY (SaErrorT) (ANNUN_ERR_BASE + 2)

/********************************************************************************
 *
 * Macro to generate the code to process each Annunciator RDR.
 *
 ********************************************************************************/

#define processAllAnnunciatorRdrs(processRdrFunc)                                \
                                                                                 \
    int TestRdr(SaHpiSessionIdT   sessionId,                                     \
                SaHpiResourceIdT  resourceId,                                    \
                SaHpiRdrT         rdr)                                           \
    {                                                                            \
            int retval = SAF_TEST_NOTSUPPORT;                                    \
                                                                                 \
            if (rdr.RdrType == SAHPI_ANNUNCIATOR_RDR) {                          \
                    retval = processRdrFunc(sessionId,                           \
                                            resourceId,                          \
                                            &rdr,                                \
                                            &rdr.RdrTypeUnion.AnnunciatorRec);   \
            }                                                                    \
                                                                                 \
            return retval;                                                       \
    }                                                                            \
                                                                                 \
    int TestResource(SaHpiSessionIdT   sessionId,                                \
                     SaHpiRptEntryT    report,                                   \
                     callback2_t       func)                                     \
    {                                                                            \
            int retval = SAF_TEST_NOTSUPPORT;                                    \
                                                                                 \
            if (hasAnnunciatorCapability(&report)) {                             \
                    retval = do_resource(sessionId, report, func);               \
            }                                                                    \
                                                                                 \
            return retval;                                                       \
    }                                                                            \
                                                                                 \
    int main(int argc, char **argv)                                              \
    {                                                                            \
            return process_all_domains(TestResource, TestRdr, NULL);             \
    }


/********************************************************************************
 *
 * Define the INFO announcement that can be added to an
 * Annunciator table.
 *
 ********************************************************************************/

SaHpiAnnouncementT info_announcement = {
    .Severity = SAHPI_INFORMATIONAL,
    .Acknowledged = SAHPI_FALSE,
    .StatusCond = {
        .Type = SAHPI_STATUS_COND_TYPE_USER,
        .DomainId = SAHPI_UNSPECIFIED_DOMAIN_ID,
        .ResourceId = SAHPI_UNSPECIFIED_RESOURCE_ID,
        .Data = {
			.DataType = SAHPI_TL_TYPE_TEXT,
            .Language = SAHPI_LANG_ENGLISH,
            .DataLength = 0
		}
    }
};

/********************************************************************************
 *
 * Determine if the resource supports Annunciators.
 *
 ********************************************************************************/

static inline int hasAnnunciatorCapability(SaHpiRptEntryT  *report)
{
    return (report->ResourceCapabilities & SAHPI_CAPABILITY_ANNUNCIATOR);
}

/********************************************************************************
 *
 * The setWriteMode() function attempts to place the Annunciator
 * into either USER or SHARED mode.  If * the Annunciator is already in the USER 
 * or SHARED mode, then this method does nothing.  If the Annunciator is in AUTO 
 * mode, an attempt is made to change to SHARED mode.
 *
 * Return values:
 *     SA_OK: Annunciator is in a write mode (USER or SHARED).
 *     SA_ERR_HPI_READ_ONLY: Annunciator is in read-only mode and cannot be changed.
 *     SA_ERR_HPI_ERROR: an unexpected error occured with an HPI function invocation.
 *
 * Upon success (SA_OK), the "mode" contains the original mode which
 * can be later restored with the restoreMode() function.
 *
 ********************************************************************************/

static inline SaErrorT setWriteMode(SaHpiSessionIdT         sessionId,
                                    SaHpiResourceIdT        resourceId, 
                                    SaHpiAnnunciatorRecT    *annunRec,
                                    SaHpiAnnunciatorModeT   *mode)
{
        SaErrorT                status;
        SaHpiAnnunciatorNumT    a_num = annunRec->AnnunciatorNum;

        status = saHpiAnnunciatorModeGet(sessionId, resourceId, a_num, mode);
        if (status != SA_OK) {
                status = ANNUN_ERROR;
                e_print(saHpiAnnunciatorModeSet, SA_OK, status);
        } else if (*mode == SAHPI_ANNUNCIATOR_MODE_AUTO) {
                if (annunRec->ModeReadOnly) {
                        status = ANNUN_READONLY;
                } else {
                        status = saHpiAnnunciatorModeSet(sessionId, resourceId, a_num,
                                                         SAHPI_ANNUNCIATOR_MODE_SHARED);
                        if (status != SA_OK) {
                                status = ANNUN_ERROR;
                                e_print(saHpiAnnunciatorModeSet, SA_OK, status);
                        }
                }
        }

        return status;
}

/********************************************************************************
 *
 * The restoreMode() function works in conjunction with the setWriteMode()
 * function.  It actually only restores the mode if the mode was changed from
 * AUTO to SHARED by the setWriteMode() function.
 *
 ********************************************************************************/

static inline SaErrorT restoreMode(SaHpiSessionIdT         sessionId,
                                   SaHpiResourceIdT        resourceId, 
                                   SaHpiAnnunciatorNumT    a_num,
                                   SaHpiAnnunciatorModeT   mode)
{
        SaErrorT status = SA_OK;

        if (mode == SAHPI_ANNUNCIATOR_MODE_AUTO) {
                status = saHpiAnnunciatorModeSet(sessionId, resourceId, a_num, mode);
                if (status != SA_OK) {
                        e_print(saHpiAnnunciatorModeSet, SA_OK, status);
                }
        }
        return status;
}

/********************************************************************************
 *
 * Return the current mode of the Annunciator.
 *
 ********************************************************************************/

static inline SaErrorT getMode(SaHpiSessionIdT         sessionId,
                               SaHpiResourceIdT        resourceId, 
                               SaHpiAnnunciatorNumT    a_num,
                               SaHpiAnnunciatorModeT   *mode)
{
        SaErrorT status = SA_OK;
        
        status = saHpiAnnunciatorModeGet(sessionId, resourceId, a_num, mode);
        if (status != SA_OK) {
                e_print(saHpiAnnunciatorModeGet, SA_OK, status);
        }
        return status;
}

/********************************************************************************
 *
 * Set the mode of the Annunciator.  The mode can be USER, SHARED, or AUTO.
 *
 ********************************************************************************/

static inline SaErrorT setMode(SaHpiSessionIdT         sessionId,
                               SaHpiResourceIdT        resourceId, 
                               SaHpiAnnunciatorNumT    a_num,
                               SaHpiAnnunciatorModeT   mode)
{
        SaErrorT status = SA_OK;
        
        status = saHpiAnnunciatorModeSet(sessionId, resourceId, a_num, mode);
        if (status != SA_OK) {
                e_print(saHpiAnnunciatorModeSet, SA_OK, status);
        }
        return status;
}

/********************************************************************************
 *
 * Add an announcement to an Annunciator table.
 *
 ********************************************************************************/

static inline SaErrorT addAnnouncement(SaHpiSessionIdT         sessionId,
                                       SaHpiResourceIdT        resourceId, 
                                       SaHpiAnnunciatorNumT    a_num,
                                       SaHpiSeverityT          severity,
                                       SaHpiAnnouncementT      *announcement)
{
        SaErrorT status;

        announcement->Severity = severity;
        announcement->Acknowledged = SAHPI_FALSE;
        announcement->StatusCond.Type = SAHPI_STATUS_COND_TYPE_USER;
        announcement->StatusCond.DomainId = SAHPI_UNSPECIFIED_DOMAIN_ID;
        announcement->StatusCond.ResourceId = SAHPI_UNSPECIFIED_RESOURCE_ID;
        announcement->StatusCond.Data.DataType = SAHPI_TL_TYPE_TEXT;
        announcement->StatusCond.Data.Language = SAHPI_LANG_ENGLISH;
        announcement->StatusCond.Data.DataLength = 0;

        status = saHpiAnnunciatorAdd(sessionId, resourceId, a_num, announcement);

        if (status != SA_OK) {
                e_print(saHpiAnnunciatorAdd, SA_OK, status);
        }

        return status;
}

/********************************************************************************
 *
 * Add an INFORMATIONAL announcement to an Annunciator table.
 *
 ********************************************************************************/

static inline SaErrorT addInfoAnnouncement(SaHpiSessionIdT         sessionId,
                                           SaHpiResourceIdT        resourceId, 
                                           SaHpiAnnunciatorNumT    a_num,
                                           SaHpiAnnouncementT      *announcement)
{
        return addAnnouncement(sessionId, resourceId, a_num, 
                               SAHPI_INFORMATIONAL, announcement);
}

/********************************************************************************
 *
 * Delete the given announcement from the Annunciator table.
 *
 ********************************************************************************/

static inline SaErrorT deleteAnnouncement(SaHpiSessionIdT        sessionId,
                                          SaHpiResourceIdT       resourceId, 
                                          SaHpiAnnunciatorNumT   a_num,
                                          SaHpiAnnouncementT     *announcement)
{
        SaErrorT status;

        status = saHpiAnnunciatorDelete(sessionId, resourceId, a_num,
                                        announcement->EntryId, SAHPI_INFORMATIONAL);

        if (status != SA_OK) {
                e_print(saHpiAnnunciatorDelete, SA_OK, status);
        }

        return status;
}

/********************************************************************************
 *
 * Determine if the given EntryId is contained in the Annunciator.
 *
 ********************************************************************************/

static inline SaErrorT containsAnnouncement(SaHpiSessionIdT        sessionId,
                                            SaHpiResourceIdT       resourceId, 
                                            SaHpiAnnunciatorNumT   a_num,
                                            SaHpiEntryIdT          entryId,
                                            SaHpiBoolT             *found)
{
        SaErrorT            status;
        SaHpiAnnouncementT  announcement;

        status = saHpiAnnunciatorGet(sessionId, resourceId, a_num, entryId, &announcement);
        if (status == SA_OK) {
                *found = SAHPI_TRUE;
        } else if (status == SA_ERR_HPI_NOT_PRESENT) {
                *found = SAHPI_FALSE;
                status = SA_OK;
        }

        return status;
}

/********************************************************************************
 *
 * Acknowledges an announcement in an Annunciator table.
 *
 ********************************************************************************/

static inline SaErrorT acknowledgeAnnouncement(SaHpiSessionIdT       sessionId,
                                               SaHpiResourceIdT      resourceId, 
                                               SaHpiAnnunciatorNumT  a_num,
                                               SaHpiAnnouncementT    *announcement)
{
        SaErrorT status;

        status = saHpiAnnunciatorAcknowledge(sessionId, resourceId, a_num,
                                             announcement->EntryId, 
                                             announcement->Severity);

        if (status != SA_OK) {
                e_print(saHpiAnnunciatorAcknowledge, SA_OK, status);
        }

        return status;
}

/********************************************************************************
 *
 * Structure to hold set of announcements.
 *
 ********************************************************************************/

#define SEVERITY_COUNT 6

typedef struct {
    SaHpiAnnouncementT  Announcement[SEVERITY_COUNT];
    int                 Count;
} AnnouncementSet;

/********************************************************************************
 *
 * Return the valid severities.
 *
 ********************************************************************************/

SaHpiSeverityT *getValidSeverities(int *count) 
{
        static SaHpiSeverityT severity[] = { SAHPI_OK, SAHPI_MINOR, 
                                             SAHPI_MAJOR, SAHPI_CRITICAL, 
                                             SAHPI_INFORMATIONAL, SAHPI_DEBUG };

        *count = SEVERITY_COUNT;
        return severity;
}

/********************************************************************************
 *
 * Acknowledge all of the announcements in the given set.
 *
 ********************************************************************************/

static inline SaErrorT ackAnnouncements(SaHpiSessionIdT       sessionId,
                                        SaHpiResourceIdT      resourceId, 
                                        SaHpiAnnunciatorNumT  a_num,
                                        AnnouncementSet       *announcementSet)
{
        SaErrorT     keep_status = SA_OK;
        SaErrorT     status;
        int          i;

        for (i = 0; i < announcementSet->Count; i++) {
                status = acknowledgeAnnouncement(sessionId, resourceId, a_num, 
                                                 &announcementSet->Announcement[i]);
                if (status != SA_OK) {
                        keep_status = status;
                }
        }

        return keep_status;
}

/********************************************************************************
 *
 * Add one announcement for each valid severity.
 *
 * WARNING: Be careful when using this function along with deleteAnnouncements().
 *          Even if an error is returned, one or more announcements could still
 *          be added, and thus need to be deleted.  Structure the code as follows:
 *
 *                status = addSeverityAnnouncements(..);
 *                if (status != SA_OK) {
 *                        .
 *                } else {
 *                        .  
 *                }
 *                deleteAnnouncements(..);
 *
 ********************************************************************************/

static inline SaErrorT addSeverityAnnouncements(SaHpiSessionIdT       sessionId,
                                                SaHpiResourceIdT      resourceId, 
                                                SaHpiAnnunciatorNumT  a_num,
                                                AnnouncementSet       *announcementSet)
{
        SaErrorT        status;
        int             i;
        int             severityCount;
        SaHpiSeverityT  *severity;

        announcementSet->Count = 0;
        severity = getValidSeverities(&severityCount);

        for (i = 0; i < severityCount; i++) {
                status = addAnnouncement(sessionId, resourceId, a_num, 
                                         severity[i], &announcementSet->Announcement[i]);
                if (status != SA_OK) {
                        e_trace();
                        break;
                }
                announcementSet->Count++;
        }

        return status;
}

/********************************************************************************
 *
 * Add a bunch of announcements for test purposes.  There are two sets, one
 * that is unacknowledged and the other is acknowledged.  Each has one announcement
 * for each severity level.
 *
 ********************************************************************************/

static inline SaErrorT addTestAnnouncements(SaHpiSessionIdT       sessionId,
                                            SaHpiResourceIdT      resourceId, 
                                            SaHpiAnnunciatorNumT  a_num,
                                            AnnouncementSet       *ackAnnouncementSet,
                                            AnnouncementSet       *unackAnnouncementSet)
{
        SaErrorT  status;

        ackAnnouncementSet->Count = 0;
        unackAnnouncementSet->Count = 0;

        status = addSeverityAnnouncements(sessionId, resourceId, 
                                          a_num, unackAnnouncementSet);
        if (status == SA_OK) {
                status = addSeverityAnnouncements(sessionId, resourceId, 
                                                   a_num, ackAnnouncementSet);
                if (status == SA_OK) {
                        status = ackAnnouncements(sessionId, resourceId, 
                                                   a_num, ackAnnouncementSet);
                }
        }

        return status;
}

/********************************************************************************
 *
 * Delete all of the announcements in the given set.
 *
 ********************************************************************************/

static inline SaErrorT deleteAnnouncements(SaHpiSessionIdT       sessionId,
                                           SaHpiResourceIdT      resourceId, 
                                           SaHpiAnnunciatorNumT  a_num,
                                           AnnouncementSet       *announcementSet)
{
        SaErrorT     keep_status = SA_OK;
        SaErrorT     status;
        int          i;

        for (i = 0; i < announcementSet->Count; i++) {
                status = deleteAnnouncement(sessionId, resourceId, a_num, 
                                            &announcementSet->Announcement[i]);
                if (status != SA_OK) {
                        keep_status = status;
                }
        }

        return keep_status;
}

/********************************************************************************
 *
 * Does the announcement's severity equal the given severity.  Not that
 * announcement's severity will always match SAHPI_ALL_SEVERITIES.
 *
 ********************************************************************************/

static inline SaHpiBoolT hasSeverity(SaHpiAnnouncementT  *announcement, 
                                     SaHpiSeverityT severity)
{
        if (severity == SAHPI_ALL_SEVERITIES) {
                return SAHPI_TRUE;
        } else {
                return (announcement->Severity == severity);
        }
}

/********************************************************************************
 *
 * Return the number of announcements in the Annunciator table with the 
 * given severity and acknowledgement.  Note the ANNUN_ERROR is returned
 * if an announcement is retrieved that doesn't match the given parameters.
 *
 ********************************************************************************/

static inline SaErrorT getAnnouncementCount(SaHpiSessionIdT        sessionId,
                                            SaHpiResourceIdT       resourceId, 
                                            SaHpiAnnunciatorNumT   a_num,
                                            SaHpiSeverityT         severity,
                                            SaHpiBoolT             unacknowledgedOnly,
                                            int                    *count)
{
        SaErrorT              status = SA_OK;
        SaHpiAnnouncementT    announcement;

        *count = 0;
        announcement.EntryId = SAHPI_FIRST_ENTRY;

        while (status == SA_OK) {
                status = saHpiAnnunciatorGetNext(sessionId, resourceId,
                                                 a_num, severity, 
                                                 unacknowledgedOnly,
                                                 &announcement);
                if (status == SA_OK) {
                        
                        if (!hasSeverity(&announcement, severity)) {
                                status = ANNUN_ERROR;
                                m_print("Retrieved announcement with non-matching severity!");
                        } else if (unacknowledgedOnly && announcement.Acknowledged) {
                                status = ANNUN_ERROR;
                                m_print("Retrieved announcement with non-matching acknowledgement!");
                        } else {
                                (*count)++;
                        }
                } else if (status != SA_ERR_HPI_NOT_PRESENT) {
                        e_print(saHpiAnnunciatorGetNext, 
                                SA_OK | SA_ERR_HPI_NOT_PRESENT, status);
                }
        }

        // if we successfully examined the entire table, return OK to the caller.

        if (status == SA_ERR_HPI_NOT_PRESENT) {
                status = SA_OK;
        }

        return status;
}

/********************************************************************************
 *
 * Find a severity level that is NOT being used by any of the announcements
 * in Annunciator table.  If all of the severity levels are being used, then 
 * use INFORMATIONAL by default.  The "found" argument indicates whether 
 * an unused severity was found or not.
 *
 ********************************************************************************/

static inline SaErrorT getUnusedSeverity(SaHpiSessionIdT        sessionId,
                                         SaHpiResourceIdT       resourceId, 
                                         SaHpiAnnunciatorNumT   a_num,
                                         SaHpiBoolT             unacknowledgedOnly,
                                         SaHpiSeverityT         *severity,
                                         SaHpiBoolT             *found)
{
        SaHpiSeverityT   severities[] = { SAHPI_INFORMATIONAL, SAHPI_MINOR, 
                                          SAHPI_MAJOR, SAHPI_CRITICAL, 
                                          SAHPI_OK, SAHPI_DEBUG }; 
        SaErrorT         status = SA_OK;
        int              i;
        int              count;

        *found = SAHPI_FALSE;
        *severity = SAHPI_INFORMATIONAL;

        for (i = 0; i < SEVERITY_COUNT; i++) {
                status = getAnnouncementCount(sessionId, resourceId, 
                                              a_num, severities[i], 
                                              unacknowledgedOnly, &count);
                if (status != SA_OK) {
                        break;
                } else if (count == 0) {
                        *severity = severities[i];
                        *found = SAHPI_TRUE;
                        break;
                }
        }

        return status;
}

/********************************************************************************
 *
 * Find all of the severity levels that are NOT being used by any of the 
 * announcements in Annunciator table.  
 *
 ********************************************************************************/

static inline SaErrorT getUnusedSeverities(SaHpiSessionIdT        sessionId,
                                           SaHpiResourceIdT       resourceId, 
                                           SaHpiAnnunciatorNumT   a_num,
                                           SaHpiBoolT             unacknowledgedOnly,
                                           SaHpiSeverityT         severity[],
                                           int                    *scount)
{
        SaErrorT         status = SA_OK;
        int              i;
        int              count;
        int              severityCount;
        SaHpiSeverityT   *severities;

        *scount = 0;
        severities = getValidSeverities(&severityCount);

        for (i = 0; i < severityCount; i++) {
                status = getAnnouncementCount(sessionId, resourceId, 
                                              a_num, severities[i], 
                                              unacknowledgedOnly, &count);
                if (status != SA_OK) {
                        break;
                } else if (count == 0) {
                        severity[*scount] = severities[i];
                        (*scount)++;
                }
        }

        return status;
}

/********************************************************************************
 *
 * Determine if the given entryId is found in the Annunciator table or not.
 *
 ********************************************************************************/

static inline SaErrorT containsEntryId(SaHpiSessionIdT       sessionId,
                                       SaHpiResourceIdT      resourceId,
                                       SaHpiAnnunciatorNumT  a_num,
                                       SaHpiEntryIdT         entryId,
                                       SaHpiBoolT            *contains)
{
        SaErrorT            status = SA_OK;
        SaHpiAnnouncementT  announcement;

        *contains = SAHPI_FALSE;
        announcement.EntryId = SAHPI_FIRST_ENTRY;

        while (status == SA_OK) {
                status = saHpiAnnunciatorGetNext(sessionId, resourceId, a_num,
                                                 SAHPI_ALL_SEVERITIES, SAHPI_FALSE,
                                                 &announcement);
                if (status == SA_OK) {
                        if (announcement.EntryId == entryId) {
                                *contains = SAHPI_TRUE;
                                break;
                        }
                } else if (status != SA_ERR_HPI_NOT_PRESENT) {
                        e_print(saHpiAnnunciatorGetNext, SA_OK | SA_ERR_HPI_NOT_PRESENT, status);
                }
        }

        return status;
}

/********************************************************************************
 *
 * Find a Bad Entry ID, i.e. an entry id that does not correspond to any of
 * the announcements in the Annunciator Table.
 *
 ********************************************************************************/

static inline SaErrorT getBadEntryId(SaHpiSessionIdT        sessionId,
                                     SaHpiResourceIdT       resourceId,
                                     SaHpiAnnunciatorNumT   a_num,
                                     SaHpiEntryIdT          *entryId)
{
        SaErrorT    status;
        SaHpiBoolT  contains;

        // Start with a random Entry ID that probably isn't used by any
        // announcements.  If it is being used, then subtract 100 from the id
        // and keep trying until we find an id that isn't being used.

        *entryId = BAD_ENTRY_ID;
        status = containsEntryId(sessionId, resourceId, a_num, *entryId, &contains);
        while (status == SA_OK && contains) {
                *entryId -= 100;
                if (*entryId == SAHPI_ENTRY_UNSPECIFIED) {
                        (*entryId)--;
                }
                status = containsEntryId(sessionId, resourceId, a_num, 
                                         *entryId, &contains);
        }
        if (status == SA_OK)
		status = SA_ERR_HPI_NOT_PRESENT;
        return status;
}

/********************************************************************************
 *
 * Determine if the Annunciator table is empty or not.
 *
 ********************************************************************************/

static inline SaErrorT isEmpty(SaHpiSessionIdT        sessionId,
                               SaHpiResourceIdT       resourceId,
                               SaHpiAnnunciatorNumT   a_num,
                               SaHpiBoolT             *empty)
{
        SaErrorT            status;
        SaHpiAnnouncementT  announcement;

        announcement.EntryId = SAHPI_FIRST_ENTRY;

        status = saHpiAnnunciatorGetNext(sessionId, resourceId, a_num,
                                         SAHPI_ALL_SEVERITIES, SAHPI_FALSE,
                                         &announcement);
        if (status == SA_OK) {
                *empty = SAHPI_FALSE;
        } else if (status == SA_ERR_HPI_NOT_PRESENT) {
                *empty = SAHPI_TRUE;
                status = SA_OK;
        } else {
                e_print(saHpiAnnunciatorGetNext, SA_OK | SA_ERR_HPI_NOT_PRESENT, status);
        }

        return status;
}

#endif
