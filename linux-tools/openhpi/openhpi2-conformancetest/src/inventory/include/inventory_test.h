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

#ifndef __INVENTORY_TEST
#define __INVENTORY_TEST

#include "saf_test.h"

/********************************************************************************
 *
 * Bad values used by the test programs.
 *
 ********************************************************************************/

#define INVALID_INVENTORY_ID  0xDEADBEEF
#define INVALID_AREA_ID       0xDEADBEEF
#define INVALID_FIELD_ID      0xDEADBEEF

#define INVALID_AREA_TYPE     (SAHPI_IDR_AREATYPE_PRODUCT_INFO + 1)
#define INVALID_FIELD_TYPE    (SAHPI_IDR_FIELDTYPE_CUSTOM + 1)

/********************************************************************************
 *
 * Macro to generate the code to process each Inventory RDR.
 *
 ********************************************************************************/

#define processAllInventoryRdrs(processRdrFunc)                                  \
                                                                                 \
    int TestRdr(SaHpiSessionIdT   sessionId,                                     \
                SaHpiResourceIdT  resourceId,                                    \
                SaHpiRdrT         rdr)                                           \
    {                                                                            \
            int retval = SAF_TEST_NOTSUPPORT;                                    \
                                                                                 \
            if (rdr.RdrType == SAHPI_INVENTORY_RDR) {                            \
                    retval = processRdrFunc(sessionId,                           \
                                            resourceId,                          \
                                            &rdr,                                \
                                            &rdr.RdrTypeUnion.InventoryRec);     \
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
            if (hasInventoryCapability(&report)) {                               \
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
 * Determine if the resource supports Inventory Data Repositories.
 *
 ********************************************************************************/

static inline int hasInventoryCapability(SaHpiRptEntryT  *report)
{
    return (report->ResourceCapabilities & SAHPI_CAPABILITY_INVENTORY_DATA);
}

/********************************************************************************
 *
 * Is this a valid Idr Area Type?
 *
 ********************************************************************************/

static inline SaHpiBoolT isValidAreaType(SaHpiIdrAreaTypeT  areaType)
{
    return ((areaType == SAHPI_IDR_AREATYPE_INTERNAL_USE) ||
            (areaType == SAHPI_IDR_AREATYPE_CHASSIS_INFO) ||
            (areaType == SAHPI_IDR_AREATYPE_BOARD_INFO)   ||
            (areaType == SAHPI_IDR_AREATYPE_PRODUCT_INFO) ||
            (areaType == SAHPI_IDR_AREATYPE_OEM));
}

/********************************************************************************
 *
 * Is this a valid Idr Field Type?
 *
 ********************************************************************************/

static inline SaHpiBoolT isValidFieldType(SaHpiIdrFieldTypeT  fieldType)
{
    return ((fieldType == SAHPI_IDR_FIELDTYPE_CHASSIS_TYPE)    ||
            (fieldType == SAHPI_IDR_FIELDTYPE_MFG_DATETIME)    ||
            (fieldType == SAHPI_IDR_FIELDTYPE_MANUFACTURER)    ||
            (fieldType == SAHPI_IDR_FIELDTYPE_PRODUCT_NAME)    ||
            (fieldType == SAHPI_IDR_FIELDTYPE_PRODUCT_VERSION) ||
            (fieldType == SAHPI_IDR_FIELDTYPE_SERIAL_NUMBER)   ||
            (fieldType == SAHPI_IDR_FIELDTYPE_PART_NUMBER)     ||
            (fieldType == SAHPI_IDR_FIELDTYPE_FILE_ID)         ||
            (fieldType == SAHPI_IDR_FIELDTYPE_ASSET_TAG)       ||
            (fieldType == SAHPI_IDR_FIELDTYPE_CUSTOM));
}

/********************************************************************************
 *
 * Delete an Area.
 *
 ********************************************************************************/

static inline SaErrorT deleteArea(SaHpiSessionIdT     sessionId,
                                  SaHpiResourceIdT    resourceId,
                                  SaHpiIdrIdT         idrId,
                                  SaHpiEntryIdT       areaId)
{
        SaErrorT  status;

        status = saHpiIdrAreaDelete(sessionId, resourceId, idrId, areaId);
        if (status != SA_OK) {
                e_print(saHpiIdrAreaDelete, SA_OK, status);
        }

        return status;
}

/********************************************************************************
 *
 * Find an Area Type that isn't being used.  Actually, we will
 * only look for CHASSSIS, BOARD, and PRODUCT area types that are
 * not being used.
 *
 ********************************************************************************/

static inline SaErrorT getUnusedAreaType(SaHpiSessionIdT     sessionId,
                                         SaHpiResourceIdT    resourceId,
                                         SaHpiIdrIdT         idrId,
                                         SaHpiIdrAreaTypeT   *areaType,
                                         SaHpiBoolT          *foundUnusedArea)
{
        SaErrorT                status = SA_OK;
        SaHpiEntryIdT           NextAreaId, AreaId;
        SaHpiIdrAreaHeaderT     Header;
        SaHpiBoolT              found[3];
        int                     i;

        // We haven't found an unused AreaType yet.

        *foundUnusedArea = SAHPI_FALSE;
        for (i = 0; i < 3; i++) {
                found[i] = SAHPI_FALSE;
        }

        // Go through the IDR.  For each area type we find,
        // set a mark to indicate that we found it.

        NextAreaId = SAHPI_FIRST_ENTRY;
        while ((NextAreaId != SAHPI_LAST_ENTRY) && (status == SA_OK)) {

                AreaId = NextAreaId;

                status = saHpiIdrAreaHeaderGet(sessionId, resourceId, idrId,
                                               SAHPI_IDR_AREATYPE_UNSPECIFIED,
                                               AreaId,
                                               &NextAreaId,
                                               &Header);

                if (status == SA_ERR_HPI_NOT_PRESENT) {
                        // do nothing
                } else if (status != SA_OK) {
                        e_print(saHpiIdrAreaHeaderGet, SA_OK, status);
                } else if (Header.Type == SAHPI_IDR_AREATYPE_CHASSIS_INFO) {
                        found[0] = SAHPI_TRUE;
                } else if (Header.Type == SAHPI_IDR_AREATYPE_BOARD_INFO) {
                        found[1] = SAHPI_TRUE;
                } else if (Header.Type == SAHPI_IDR_AREATYPE_PRODUCT_INFO) {
                        found[2] = SAHPI_TRUE;
                }
        }

        if (status == SA_ERR_HPI_NOT_PRESENT) {
                status = SA_OK;
        }

        // Check for an AreaType that wasn't found.

        if (!found[0]) {
            *foundUnusedArea = SAHPI_TRUE;
            *areaType = SAHPI_IDR_AREATYPE_CHASSIS_INFO;
        } else if (!found[1]) {
            *foundUnusedArea = SAHPI_TRUE;
            *areaType = SAHPI_IDR_AREATYPE_BOARD_INFO;
        } else if (!found[2]) {
            *foundUnusedArea = SAHPI_TRUE;
            *areaType = SAHPI_IDR_AREATYPE_PRODUCT_INFO;
        } 

        return status;
}

/********************************************************************************
 *
 * Find an Area Type that is being used.  Actually, we will
 * only look for CHASSSIS, BOARD, PRODUCT and OEM area types that are
 * being used.
 *
 ********************************************************************************/

static inline SaErrorT getUsedAreaType(SaHpiSessionIdT      sessionId,
                                        SaHpiResourceIdT    resourceId,
                                        SaHpiIdrIdT         idrId,
                                        SaHpiIdrAreaTypeT   *areaType,
                                        SaHpiBoolT          *foundArea)
{
        SaErrorT                status = SA_OK;
        SaHpiEntryIdT           NextAreaId, AreaId;
        SaHpiIdrAreaHeaderT     Header;

        // We haven't found an unused AreaType yet.

        *foundArea = SAHPI_FALSE;

        // Go through the IDR.  For each area type we find,
        // set a mark to indicate that we found it.

        NextAreaId = SAHPI_FIRST_ENTRY;
        while ((NextAreaId != SAHPI_LAST_ENTRY) && 
               (status == SA_OK) && !(*foundArea)) {

                AreaId = NextAreaId;

                status = saHpiIdrAreaHeaderGet(sessionId, resourceId, idrId,
                                               SAHPI_IDR_AREATYPE_UNSPECIFIED,
                                               AreaId,
                                               &NextAreaId,
                                               &Header);

                if (status == SA_ERR_HPI_NOT_PRESENT) {
                        // do nothing
                } else if (status != SA_OK) {
                        e_print(saHpiIdrAreaHeaderGet, SA_OK, status);
                } else if (Header.Type == SAHPI_IDR_AREATYPE_CHASSIS_INFO) {
                        *foundArea = SAHPI_TRUE;
                        *areaType = SAHPI_IDR_AREATYPE_CHASSIS_INFO;
                } else if (Header.Type == SAHPI_IDR_AREATYPE_BOARD_INFO) {
                        *foundArea = SAHPI_TRUE;
                        *areaType = SAHPI_IDR_AREATYPE_BOARD_INFO;
                } else if (Header.Type == SAHPI_IDR_AREATYPE_PRODUCT_INFO) {
                        *foundArea = SAHPI_TRUE;
                        *areaType = SAHPI_IDR_AREATYPE_PRODUCT_INFO;
                } else if (Header.Type == SAHPI_IDR_AREATYPE_OEM) {
                        *foundArea = SAHPI_TRUE;
                        *areaType = SAHPI_IDR_AREATYPE_OEM;
                }
        }

        if (status == SA_ERR_HPI_NOT_PRESENT) {
                status = SA_OK;
        }

        return status;
}

/*************************************************************************
 *
 * Get a Field.  If we can't find any, return NOTSUPPORT.
 *
 *************************************************************************/

static inline int getField(SaHpiSessionIdT   sessionId,
                           SaHpiResourceIdT  resourceId,
                           SaHpiIdrIdT       IdrId,
                           SaHpiEntryIdT     AreaId,
                           SaHpiIdrFieldT    *Field)
{
        SaErrorT         status;
        int              retval;
        SaHpiEntryIdT    NextFieldId;

        status = saHpiIdrFieldGet(sessionId,
                                  resourceId,
                                  IdrId,
                                  AreaId,
                                  SAHPI_IDR_FIELDTYPE_UNSPECIFIED,
                                  SAHPI_FIRST_ENTRY,
                                  &NextFieldId,
                                  Field);

        if (status == SA_ERR_HPI_NOT_PRESENT) {
                retval = SAF_TEST_NOTSUPPORT;
        } else if (status == SA_OK) {
                retval = SAF_TEST_PASS;
        } else {
                retval = SAF_TEST_FAIL;
                e_print(saHpiIdrFieldGet, SA_OK, status);
        }

        return retval;
}

/*************************************************************************
 *
 * Find a Field that is ReadOnly.  If we can't find any, return NOTSUPPORT.
 *
 *************************************************************************/

static inline int findReadOnlyField(SaHpiSessionIdT   sessionId,
                                    SaHpiResourceIdT  resourceId,
                                    SaHpiIdrIdT       IdrId,
                                    SaHpiEntryIdT     AreaId,
                                    SaHpiIdrFieldT    *Field)
{
        SaErrorT         status;
        int              retval = SAF_TEST_NOTSUPPORT;
        SaHpiEntryIdT    FieldId, NextFieldId;

        NextFieldId = SAHPI_FIRST_ENTRY;
        while ((NextFieldId != SAHPI_LAST_ENTRY) &&
               (retval == SAF_TEST_NOTSUPPORT)) {

                FieldId = NextFieldId;
                status = saHpiIdrFieldGet(sessionId,
                                          resourceId,
                                          IdrId,
                                          AreaId,
                                          SAHPI_IDR_FIELDTYPE_UNSPECIFIED,
                                          FieldId,
                                          &NextFieldId,
                                          Field);

                if (status == SA_ERR_HPI_NOT_PRESENT) {
                        // do nothing
                } else if (status != SA_OK) {
                        retval = SAF_TEST_FAIL;
                        e_print(saHpiIdrFieldGet, SA_OK, status);
                } else if (Field->ReadOnly) {
                        retval = SAF_TEST_PASS;
                }
        }

        return retval;
}

/*************************************************************************
 *
 * Add a new Custom Field.
 *
 *************************************************************************/

static inline SaErrorT addCustomField(SaHpiSessionIdT   sessionId,
                                      SaHpiResourceIdT  resourceId,
                                      SaHpiIdrIdT       IdrId,
                                      SaHpiEntryIdT     AreaId,
                                      SaHpiIdrFieldT    *Field)
{
        SaErrorT  status;

        Field->Field.Data[0] = 'a';
        Field->Field.DataLength = 1;
        Field->Field.DataType = SAHPI_TL_TYPE_TEXT;
        Field->FieldId = 0;
        Field->Field.Language = SAHPI_LANG_ENGLISH;
        Field->AreaId = AreaId;
        Field->ReadOnly = SAHPI_FALSE;
        Field->Type = SAHPI_IDR_FIELDTYPE_CUSTOM;

        status = saHpiIdrFieldAdd(sessionId, resourceId, IdrId, Field);

        return status;
}


#endif
