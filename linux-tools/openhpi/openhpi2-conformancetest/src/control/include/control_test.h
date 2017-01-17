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

#ifndef __CONTROL_TEST
#define __CONTROL_TEST

#include "saf_test.h"

/********************************************************************************
 *
 * Bad values used by the test programs.
 *
 ********************************************************************************/

#define INVALID_SESSION_ID         0xDEADBEEF
#define INVALID_RESOURCE_ID        0xDEADBEEF
#define INVALID_CONTROL_NUM        0xDEADBEEF
#define BAD_SEVERITY           (SAHPI_OK + 1)
#define BAD_CTRL_MODE          (SAHPI_CTRL_MODE_MANUAL + 1)
#define BAD_DIGITAL_VALUE      (SAHPI_CTRL_STATE_PULSE_ON + 1)
#define BAD_CTRL_TYPE          (SAHPI_CTRL_TYPE_TEXT + 1)

/********************************************************************************
 *
 * Character data that can be used for testing.  Since BCDPLUS is the most
 * restrictive, we must use characters that are supported by BCDPLUS.
 *
 ********************************************************************************/

#define BYTE_VALUE_1 '1'
#define BYTE_VALUE_2 '2'

/********************************************************************************
 *
 * Macro to generate the code to process each Control RDR.
 *
 ********************************************************************************/

#define processAllControlRdrs(processCtrlFunc)                                   \
                                                                                 \
    int TestRdr(SaHpiSessionIdT   sessionId,                                     \
                SaHpiResourceIdT  resourceId,                                    \
                SaHpiRdrT         rdr)                                           \
    {                                                                            \
            int retval = SAF_TEST_NOTSUPPORT;                                    \
                                                                                 \
            if (rdr.RdrType == SAHPI_CTRL_RDR) {                                 \
                    retval = processCtrlFunc(sessionId,                          \
                                             resourceId,                         \
                                             &rdr,                               \
                                             &rdr.RdrTypeUnion.CtrlRec);         \
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
            if (hasControlCapability(&report)) {                                 \
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


/**************************************************************************
 *
 * Determine if the resource has the Controls Capability.
 *
 **************************************************************************/

static inline int hasControlCapability(SaHpiRptEntryT  *report)
{
    return (report->ResourceCapabilities & SAHPI_CAPABILITY_CONTROL);
}

/*************************************************************************
 *
 * Return true is this is a Text Contorl; otherwise false.
 *
 *************************************************************************/

static inline SaHpiBoolT isTextControl(SaHpiCtrlRecT *ctrlRec)
{
        return (ctrlRec->Type == SAHPI_CTRL_TYPE_TEXT);
}

/*************************************************************************
 *
 * Return true is this is a Analog Contorl; otherwise false.
 *
 *************************************************************************/

static inline SaHpiBoolT isAnalogControl(SaHpiCtrlRecT *ctrlRec)
{
        return (ctrlRec->Type == SAHPI_CTRL_TYPE_ANALOG);
}

/*************************************************************************
 *
 * Return true is this is Digital Contorl; otherwise false.
 *
 *************************************************************************/

static inline SaHpiBoolT isDigitalControl(SaHpiCtrlRecT *ctrlRec)
{
        return (ctrlRec->Type == SAHPI_CTRL_TYPE_DIGITAL);
}

/*************************************************************************
 *
 * Return true is this is Discrete Contorl; otherwise false.
 *
 *************************************************************************/

static inline SaHpiBoolT isDiscreteControl(SaHpiCtrlRecT *ctrlRec)
{
        return (ctrlRec->Type == SAHPI_CTRL_TYPE_DISCRETE);
}

/*************************************************************************
 *
 * Return true is this is Stream Contorl; otherwise false.
 *
 *************************************************************************/

static inline SaHpiBoolT isStreamControl(SaHpiCtrlRecT *ctrlRec)
{
        return (ctrlRec->Type == SAHPI_CTRL_TYPE_STREAM);
}

/*************************************************************************
 *
 * Can the control state be set using saHpiControlSet()?
 *
 * The only situation where we can't set the control is when the
 * the default mode is AUTO and the mode is ReadOnly.
 *
 *************************************************************************/

static inline SaHpiBoolT canSetControlState(SaHpiCtrlRecT *ctrlRec)
{
        return (!((ctrlRec->DefaultMode.Mode == SAHPI_CTRL_MODE_AUTO) && 
                  (ctrlRec->DefaultMode.ReadOnly)));
}

/*************************************************************************
 *
 * Return the default mode.
 *
 *************************************************************************/

static inline SaHpiCtrlModeT getDefaultMode(SaHpiCtrlRecT *ctrlRec)
{
        return ctrlRec->DefaultMode.Mode;
}

/*************************************************************************
 *
 * Return true if the mode is read-only; otherwise false.
 *
 *************************************************************************/

static inline SaHpiBoolT isReadOnlyMode(SaHpiCtrlRecT *ctrlRec)
{
        return ctrlRec->DefaultMode.ReadOnly;
}

/*************************************************************************
 *
 * Return true if this is a valid mode; otherwise false.
 *
 *************************************************************************/

static inline SaHpiBoolT isValidCtrlMode(SaHpiCtrlModeT mode)
{
        return (mode == SAHPI_CTRL_MODE_AUTO) || 
               (mode == SAHPI_CTRL_MODE_MANUAL);
}

/*************************************************************************
 *
 * Return true if this is a valid control type; otherwise false.
 *
 *************************************************************************/

static inline SaHpiBoolT isValidCtrlType(SaHpiCtrlTypeT ctrlType)
{
        return ((ctrlType == SAHPI_CTRL_TYPE_DIGITAL) ||
                (ctrlType == SAHPI_CTRL_TYPE_DISCRETE) ||
                (ctrlType == SAHPI_CTRL_TYPE_ANALOG) ||
                (ctrlType == SAHPI_CTRL_TYPE_STREAM) ||
                (ctrlType == SAHPI_CTRL_TYPE_TEXT) ||
                (ctrlType == SAHPI_CTRL_TYPE_OEM));
}

/*************************************************************************
 *
 * Set the Control's mode and state.
 *
 *************************************************************************/

static inline SaErrorT setControl(SaHpiSessionIdT   sessionId,
                                  SaHpiResourceIdT  resourceId,
                                  SaHpiCtrlNumT     ctrlNum,
                                  SaHpiCtrlModeT    ctrlMode,
                                  SaHpiCtrlStateT   *ctrlState)
{
        SaErrorT  status;

        status = saHpiControlSet(sessionId, resourceId, ctrlNum,
                                 ctrlMode, ctrlState);
        if (status != SA_OK) {
                e_print(saHpiControlSet, SA_OK, status);
        }

        return status;
}

/*************************************************************************
 *
 * Return true if this Text control uses UNICODE; otherwise false.
 *
 *************************************************************************/

static inline SaHpiBoolT isUnicodeDataType(SaHpiCtrlRecT *ctrlRec)
{
        return (ctrlRec->TypeUnion.Text.DataType == SAHPI_TL_TYPE_UNICODE);
}

/*************************************************************************
 *
 * Return true if this Text control uses the TEXT data type; otherwise false.
 *
 *************************************************************************/

static inline SaHpiBoolT isTextDataType(SaHpiCtrlRecT *ctrlRec)
{
        return (ctrlRec->TypeUnion.Text.DataType == SAHPI_TL_TYPE_TEXT);
}

/*************************************************************************
 *
 * Return true if this Text control uses the ASCII6 data type; otherwise false.
 *
 *************************************************************************/

static inline SaHpiBoolT isAscii6DataType(SaHpiCtrlRecT *ctrlRec)
{
        return (ctrlRec->TypeUnion.Text.DataType == SAHPI_TL_TYPE_ASCII6);
}

/*************************************************************************
 *
 * Return true if this Text control uses the BCDPLUS data type; otherwise false.
 *
 *************************************************************************/

static inline SaHpiBoolT isBcdPlusDataType(SaHpiCtrlRecT *ctrlRec)
{
        return (ctrlRec->TypeUnion.Text.DataType == SAHPI_TL_TYPE_BCDPLUS);
}

/*************************************************************************
 *
 * Set the data type.
 *
 *************************************************************************/

static inline void setDataType(SaHpiCtrlStateT   *ctrlState, 
                               SaHpiTextTypeT    dataType)
{
        ctrlState->StateUnion.Text.Text.DataType = dataType;
}

/*************************************************************************
 *
 * Return the language used by the Text Control.
 *
 *************************************************************************/

static inline SaHpiLanguageT getLanguage(SaHpiCtrlRecT *ctrlRec)
{
        return ctrlRec->TypeUnion.Text.Language;
}

/*************************************************************************
 *
 * Set the language used by the Text Control.
 *
 *************************************************************************/

static inline void setLanguage(SaHpiCtrlStateT *ctrlState, SaHpiLanguageT language)
{
        ctrlState->StateUnion.Text.Text.Language = language;
}

/*************************************************************************
 *
 * Get the maximum number of bytes that can be stored in a Text control
 * line.  This is different from the maximum number of characters.  When
 * the data type UNICODE, it takes 2 bytes to store one character.
 *
 *************************************************************************/

static inline SaHpiUint8T getMaxBytes(SaHpiCtrlRecT *ctrlRec)
{
        int numBytes;

        numBytes = ctrlRec->TypeUnion.Text.MaxChars;
        if (isUnicodeDataType(ctrlRec)) {
                numBytes *= 2;
        }

        return numBytes;
}

/*************************************************************************
 *
 * When setting a Text Control state, the Type, DataType, and Language
 * must be set to correspond to what is in the RDR.
 *
 *************************************************************************/

static inline void setDefaultCtrlState(SaHpiCtrlRecT    *ctrlRec,
                                       SaHpiCtrlStateT  *ctrlState)
{
        ctrlState->Type = ctrlRec->Type;
        if (ctrlRec->Type == SAHPI_CTRL_TYPE_DIGITAL) {
                ctrlState->StateUnion.Digital = ctrlRec->TypeUnion.Digital.Default;

        } else if (ctrlRec->Type == SAHPI_CTRL_TYPE_DISCRETE) {
                ctrlState->StateUnion.Discrete = ctrlRec->TypeUnion.Discrete.Default;

        } else if (ctrlRec->Type == SAHPI_CTRL_TYPE_ANALOG) {
                ctrlState->StateUnion.Analog = ctrlRec->TypeUnion.Analog.Default;

        } else if (ctrlRec->Type == SAHPI_CTRL_TYPE_STREAM) {
                ctrlState->StateUnion.Stream = ctrlRec->TypeUnion.Stream.Default;

        } else if (ctrlRec->Type == SAHPI_CTRL_TYPE_TEXT) {
                ctrlState->StateUnion.Text = ctrlRec->TypeUnion.Text.Default;
                ctrlState->StateUnion.Text.Line = 1;

        } else if (ctrlRec->Type == SAHPI_CTRL_TYPE_OEM) {
                ctrlState->StateUnion.Oem = ctrlRec->TypeUnion.Oem.Default;
        }
}

/*************************************************************************
 *
 * The Control Data is used to store the mode and the state(s) for a
 * control.  Most control types have only one state, but a Text control
 * can have many states, one for each line.
 * 
 *************************************************************************/

typedef struct {
    SaHpiCtrlModeT   Mode;   
    SaHpiCtrlStateT  *State;
    int              Size;    /* Number of states */
} ControlData;

/*************************************************************************
 *
 * Read all of the Control Data for later restoration.
 * 
 *************************************************************************/
 
static inline SaErrorT readControlData(SaHpiSessionIdT     sessionId,
                                       SaHpiResourceIdT    resourceId,
                                       SaHpiCtrlRecT       *ctrlRec,
                                       ControlData         *controlData)
{
        SaErrorT            status = SA_OK;
        SaHpiCtrlNumT       ctrlNum = ctrlRec->Num;
        int                 i;
        int                 maxLines = ctrlRec->TypeUnion.Text.MaxLines;

        if (!isTextControl(ctrlRec)) {

                controlData->Size = 1;
                controlData->State = (SaHpiCtrlStateT *) malloc(sizeof(SaHpiCtrlStateT));
                if (controlData->State == 0) {
                        m_print("Unable to allocate memory!");
                        status = SA_ERR_HPI_OUT_OF_SPACE;
                } else {

                        status = saHpiControlGet(sessionId, resourceId, ctrlNum,
                                                 &(controlData->Mode), &(controlData->State[0]));
                        if (status != SA_OK) {
                                e_print(saHpiControlGet, SA_OK, status);
                                controlData->Size = 0;
                                free(controlData->State);
                                controlData->State = NULL;
                        }
                }

        } else {

                controlData->Size = maxLines;
                controlData->State = (SaHpiCtrlStateT *) malloc(maxLines * sizeof(SaHpiCtrlStateT));
                if (controlData->State == 0) {
                        m_print("Unable to allocate memory!");
                        status = SA_ERR_HPI_OUT_OF_SPACE;
                } else {

                        for (i = 0; i < maxLines; i++) {

                                controlData->State[i].StateUnion.Text.Line = i + 1;
                                status = saHpiControlGet(sessionId, resourceId, ctrlNum,
                                                 &(controlData->Mode), &(controlData->State[i]));
                                if (status != SA_OK) {
                                        e_print(saHpiControlGet, SA_OK, status);
                                        controlData->Size = 0;
                                        free(controlData->State);
                                        controlData->State = NULL;
                                        break;
                                }
                        }
                }
        }

        return status;
}

/*************************************************************************
 *
 * Restore all of the original Control Data.
 *
 *************************************************************************/

static inline void restoreControlData(SaHpiSessionIdT     sessionId,
                                      SaHpiResourceIdT    resourceId,
                                      SaHpiCtrlNumT       ctrlNum,
                                      ControlData         *controlData)
{
        SaErrorT     status;
        int          i;

        for (i = 0; i < controlData->Size; i++) {
                status = saHpiControlSet(sessionId, resourceId, ctrlNum,
                                         controlData->Mode, &(controlData->State[i]));
                if (status != SA_OK) {
                        e_print(saHpiControlSet, SA_OK, status);
                        break; // prevent more errors from printing
                }
        }

        free(controlData->State);
}

/*************************************************************************
 *
 * Set the text for first line in a Text Control.  The text
 * will be the given byte value repeated "numBytes" times.
 *
 *************************************************************************/

static inline SaErrorT setControlTextBuffer(SaHpiSessionIdT     sessionId,
                                            SaHpiResourceIdT    resourceId,
                                            SaHpiCtrlRecT       *ctrlRec,
                                            SaHpiTxtLineNumT    lineNum,
                                            SaHpiUint8T         numBytes,
                                            SaHpiUint8T         byteValue)
{
        SaErrorT         status;
        int              i;
        SaHpiCtrlStateT  ctrlState;
        SaHpiCtrlNumT    ctrlNum = ctrlRec->Num;

        setDefaultCtrlState(ctrlRec, &ctrlState);
        ctrlState.StateUnion.Text.Line = lineNum;
        ctrlState.StateUnion.Text.Text.DataLength = numBytes;
        for (i = 0; i < numBytes; i++) {
                ctrlState.StateUnion.Text.Text.Data[i] = byteValue;
        }

        status = saHpiControlSet(sessionId, resourceId, ctrlNum,
                                 SAHPI_CTRL_MODE_MANUAL, &ctrlState);

        if (status != SA_OK) {
                e_print(saHpiControlSet, SA_OK, status);
        }

        return status;
}

/*************************************************************************
 *
 * Set the text for first line in a Text Control.  The text
 * will be the given byte value repeated "numBytes" times.
 *
 *************************************************************************/

static inline SaErrorT setControlAllTextBuffers(SaHpiSessionIdT     sessionId,
                                                SaHpiResourceIdT    resourceId,
                                                SaHpiCtrlRecT       *ctrlRec,
                                                SaHpiUint8T         byteValue)
{
        SaErrorT    status;
        int         lineNum;
        int         maxLines = ctrlRec->TypeUnion.Text.MaxLines;
        int         maxBytes = getMaxBytes(ctrlRec);

        for (lineNum = 1; lineNum <= maxLines; lineNum++) {
                status = setControlTextBuffer(sessionId, resourceId, ctrlRec,
                                              lineNum, maxBytes, byteValue);
                if (status != SA_OK) {
                        break;
                }
        }

        return status;
}

/*************************************************************************
 *
 * Determine if the remaining bytes in the text buffer are blanks
 * or not.  Since the specification is unclear as to what a blank is,
 * we cannot look for specific byte values.  Rather, if the sequence
 * of bytes are all the same, we will assume it is a sequence of blanks.
 * NOTE: For Unicode, a character is two bytes.  Therefore we need
 * verify that everyone two bytes in the sequence are the same.
 *
 *************************************************************************/

static inline SaHpiBoolT isBlanks(SaHpiTextBufferT  *buffer, 
                                  int               startIndex,
                                  int               endIndex)
{
        int            i;
        SaHpiUint8T    blank, blank2;

        if (endIndex > startIndex) {
                if (buffer->DataType == SAHPI_TL_TYPE_UNICODE) {
                        blank = buffer->Data[startIndex];
                        blank2 = buffer->Data[startIndex+1];
                        for (i = startIndex + 2; i < endIndex; i += 2) {
                                if ((buffer->Data[i] != blank) || 
                                    (buffer->Data[i+1] != blank2)) {
                                        return SAHPI_FALSE;
                                }
                        }
                } else {
                        blank = buffer->Data[startIndex];
                        for (i = startIndex + 1; i < endIndex; i++) {
                                if (buffer->Data[i] != blank) {
                                        return SAHPI_FALSE;
                                }
                        }
                }
        }

        return SAHPI_TRUE;
}

/*************************************************************************
 *
 * Check the text buffer to verify that it is what we expected.  We
 * would have changed the text buffer and we are checking that it is
 * what it should be.
 *
 *************************************************************************/

static inline SaHpiBoolT matchesTextBuffer(SaHpiTextBufferT  *buffer, 
                                           SaHpiUint8T       maxBytes, 
                                           SaHpiUint8T       byteValue,
                                           SaHpiUint8T       numBytes)
{
        int         i;
        SaHpiBoolT  matches = SAHPI_TRUE;

        if (buffer->DataLength != numBytes && buffer->DataLength != maxBytes) {
                matches = SAHPI_FALSE;
                m_print("Text DataLength is wrong [%d]!", buffer->DataLength);
        } else {
                for (i = 0; i < numBytes; i++) {
                        if (buffer->Data[i] != byteValue ) {
                                matches = SAHPI_FALSE;

                                // NOTE: Invalid data might not be a printable character,
                                //       use it's decimal value.

                                m_print("Text has invalid data [%d]!", buffer->Data[i]);
                                break;
                        }
                }

                if (matches && maxBytes > numBytes) {
                        if (!isBlanks(buffer, numBytes, maxBytes)) {
                                matches = SAHPI_FALSE;
                                m_print("Text Buffer has invalid blanks!");
                        }
                }
        }

        return matches;
}


#endif

