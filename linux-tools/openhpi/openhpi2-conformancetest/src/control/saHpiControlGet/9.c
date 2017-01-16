/*      -*- linux-c -*-
 *
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005 by Intel Corp.
 * Copyright (c) 2005, University of New Hampshire
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  This
 * file and program are licensed under a BSD style license.  See
 * the Copying file included with the OpenHPI distribution for
 * full licensing terms.
 *
 * Author(s):
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Ye Bo <bo.ye@intel.com>
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01                                  
 * Function:    saHpiControlGet()
 * Description: 
 *      Use SAHPI_TLN_ALL_LINES to read as much of the
 *      text as possible.  Then read each text line individually
 *      to verify that the text buffer obtained via SAHPI_TLN_ALL_LINES
 *      is correct.
 *      Expected return: SA_OK.
 * Line:        P95-1:P95-4
 */

#include <stdio.h>
#include "../include/control_test.h"

/*************************************************************************
 *
 * Verify that the Text data obtained via TLN_ALL_LINES corresponds to
 * the text data that can be obtained by reading one line at a time.
 *
 * This algorithm is tricky.  First, consider what happens when lines are
 * concatenated for TLN_ALL_LINES.  Trailing blanks are not removed.  For
 * example, if the MaxChars per line is 100, but a line only has 10 chars,
 * there will be 90 blanks in the text buffer BEFORE the next line that
 * is concatenated on.
 *
 * Secondly, because a text buffer can only store 255 bytes, it may be
 * that the last line that is concatenated is trimmed.
 *
 * Because UNICODE requires 2 bytes per character, the below algorithm
 * computes everything using bytes only.
 *
 * The below algorithm takes the approach of comparing a each individual
 * line of text data to a portion of the ALL LINES text data.  The "nextIndex"
 * is the index of where the comparison must begin.  Note that "nextIndex"
 * is incremented by "maxBytes" to skip over blanks.
 *
 *************************************************************************/

int verifyTextData(SaHpiSessionIdT sessionId,
           SaHpiResourceIdT resourceId,
           SaHpiCtrlRecT * ctrlRec, SaHpiCtrlStateT * ctrlStateAllLines)
{
    SaErrorT status;
    int retval = SAF_TEST_PASS;
    int i;
    int index;
    int lineNum = 1;
    int nextIndex = 0;
    int maxBytes = getMaxBytes(ctrlRec);
    SaHpiCtrlModeT ctrlMode;
    SaHpiCtrlStateT ctrlState;
    SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
    SaHpiTextBufferT *textBuffer;
    SaHpiTextBufferT *allLinesTextBuffer =
        &(ctrlStateAllLines->StateUnion.Text.Text);

    while (retval == SAF_TEST_PASS
           && nextIndex < allLinesTextBuffer->DataLength) {

        ctrlState.StateUnion.Text.Line = lineNum;
        status = saHpiControlGet(sessionId, resourceId, ctrlNum,
                     &ctrlMode, &ctrlState);
        if (status != SA_OK) {
            retval = SAF_TEST_UNRESOLVED;
            e_print(saHpiControlGet, SA_OK, status);
        } else {

            textBuffer = &(ctrlState.StateUnion.Text.Text);

            for (i = 0, index = nextIndex;
                 i < textBuffer->DataLength
                 && index < allLinesTextBuffer->DataLength;
                 i++, index++) {
                if (textBuffer->Data[i] !=
                    allLinesTextBuffer->Data[index]) {

                    retval = SAF_TEST_FAIL;
                    m_print("Text Buffers do not match!");
                    break;
                }
            }

        }

        nextIndex += maxBytes;
        lineNum++;
    }

    return retval;
}

/*************************************************************************
 *
 * If we have a Text control that we can read, then try reading all of 
 * the text data via TLN_ALL_LINES.  If successful, verify that the text
 * data corresponds to reading the data one line at a time.
 *
 * This test will be limited to controls in MANUAL mode.  This is because
 * we can get a race condition in AUTO mode.  For example, after getting 
 * all of the lines in one call, the text lines could then be automatically
 * changed.  The test would then fail since the data has changed.
 *
 *************************************************************************/

int processCtrlRdr(SaHpiSessionIdT sessionId,
           SaHpiResourceIdT resourceId,
           SaHpiRdrT * rdr, SaHpiCtrlRecT * ctrlRec)
{
    SaErrorT status;
    int retval = SAF_TEST_NOTSUPPORT;
    SaHpiCtrlNumT ctrlNum = ctrlRec->Num;
    SaHpiCtrlModeT ctrlMode;
    SaHpiCtrlStateT ctrlStateAllLines;
    ControlData controlData;
    int i;

    if (!ctrlRec->WriteOnly && isTextControl(ctrlRec)) {

        ctrlStateAllLines.StateUnion.Text.Line = SAHPI_TLN_ALL_LINES;

        status = saHpiControlGet(sessionId, resourceId, ctrlNum,
                     &ctrlMode, &ctrlStateAllLines);

        if (status != SA_OK) {
            retval = SAF_TEST_FAIL;
            e_print(saHpiControlGet, SA_OK, status);
        } else if (ctrlMode == SAHPI_CTRL_MODE_MANUAL) {
            retval =
                verifyTextData(sessionId, resourceId, ctrlRec,
                       &ctrlStateAllLines);
        } else if (!ctrlRec->DefaultMode.ReadOnly) {

			// When we change to manual mode, we are going to write back 
			// the same data that was there when the mode was auto.

            status = readControlData(sessionId, resourceId, ctrlRec, &controlData);
            if (status != SA_OK) {
                retval = SAF_TEST_UNRESOLVED;
            } else {
                for (i = 0; i < controlData.Size; i++) {
                        status = saHpiControlSet(sessionId, resourceId, ctrlNum,
                                                 SAHPI_CTRL_MODE_MANUAL,
                                                 &(controlData.State[i]));
                        if (status != SA_OK) {
                                e_print(saHpiControlSet, SA_OK, status);
                                retval = SAF_TEST_UNRESOLVED;
                                break;
                        }
                }

                if (retval != SAF_TEST_UNRESOLVED) {
                    retval = verifyTextData(sessionId, resourceId, ctrlRec,
                                            &ctrlStateAllLines);
                }

                restoreControlData(sessionId, resourceId, ctrlNum, &controlData);
            }
        }
    }

    return retval;
}

/*************************************************************************
 *
 *  Process all Control RDRs.  The below macro expands to
 *  generate all of the generic code necessary to call the given
 *  function to process an RDR.
 *
 *************************************************************************/

processAllControlRdrs(processCtrlRdr)

