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

#ifndef __WATCHDOG_TEST
#define __WATCHDOG_TEST

#include "saf_test.h"

/********************************************************************************
 *
 * Bad values used by the test programs.
 *
 ********************************************************************************/

#define BAD_SESSION_ID         0xDEADBEEF
#define BAD_RESOURCE_ID        0xDEADBEEF
#define BAD_WATCHDOG_NUM       0xDEADBEEF

/********************************************************************************
 *
 * Macro to generate the code to process each Watchdog Timer RDR.
 *
 ********************************************************************************/

#define processAllWatchdogRdrs(processWatchdogFunc)                              \
                                                                                 \
    int TestRdr(SaHpiSessionIdT   sessionId,                                     \
                SaHpiResourceIdT  resourceId,                                    \
                SaHpiRdrT         rdr)                                           \
    {                                                                            \
            int retval = SAF_TEST_NOTSUPPORT;                                    \
                                                                                 \
            if (rdr.RdrType == SAHPI_WATCHDOG_RDR) {                             \
                    retval = processWatchdogFunc(sessionId,                      \
                                                 resourceId,                     \
                                                 &rdr,                           \
                                                 &rdr.RdrTypeUnion.WatchdogRec); \
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
            if (hasWatchdogCapability(&report)) {                                \
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
 * Determine if the resource has the Watchdog Capability.
 *
 **************************************************************************/

static inline int hasWatchdogCapability(SaHpiRptEntryT  *report)
{
    return (report->ResourceCapabilities & SAHPI_CAPABILITY_WATCHDOG);
}

/********************************************************************************
 *
 * Initialize the watchdog fields.
 *
 ********************************************************************************/

static inline void initWatchdogFields(SaHpiWatchdogT *watchdog)
{
        watchdog->Log			= SAHPI_FALSE;
        watchdog->Running		= SAHPI_FALSE;
        watchdog->TimerUse		= SAHPI_WTU_NONE;
        watchdog->TimerAction		= SAHPI_WA_NO_ACTION;
        watchdog->PretimerInterrupt	= SAHPI_WPI_NONE;
        watchdog->PreTimeoutInterval	= 0;
        watchdog->TimerUseExpFlags	= 0;
        watchdog->InitialCount		= 0;
        watchdog->PresentCount		= 0;
};

/********************************************************************************
 *
 * Initialize the SMS watchdog fields.
 *
 ********************************************************************************/

static inline void initSmsWatchdogFields(SaHpiWatchdogT *watchdog)
{
        watchdog->Log			= SAHPI_FALSE;
        watchdog->Running		= SAHPI_TRUE;
        watchdog->TimerUse		= SAHPI_WTU_SMS_OS;
        watchdog->TimerAction		= SAHPI_WA_RESET;
        watchdog->PretimerInterrupt	= SAHPI_WPI_NONE;
        watchdog->PreTimeoutInterval	= 0;
        watchdog->TimerUseExpFlags	= SAHPI_WATCHDOG_EXP_SMS_OS;
        watchdog->InitialCount		= 900000; // 900 seconds
        watchdog->PresentCount		= 0;
};

/********************************************************************************
 *
 * Return true if this a valid watchdog timer action; otherwise false.
 *
 ********************************************************************************/

static inline SaHpiBoolT isValidWatchdogAction(SaHpiWatchdogActionT action)
{
        return (action == SAHPI_WA_NO_ACTION) ||
               (action == SAHPI_WA_RESET) ||
               (action == SAHPI_WA_POWER_DOWN) ||
               (action == SAHPI_WA_POWER_CYCLE);
}

/********************************************************************************
 *
 * Return true if this a valid watchdog pretimer interrupt; otherwise false.
 *
 ********************************************************************************/

static inline SaHpiBoolT isValidWatchdogPretimerInterrupt(SaHpiWatchdogPretimerInterruptT pretimer)
{
        return (pretimer == SAHPI_WPI_NONE) ||
               (pretimer == SAHPI_WPI_SMI) ||
               (pretimer == SAHPI_WPI_NMI) ||
               (pretimer == SAHPI_WPI_MESSAGE_INTERRUPT) ||
               (pretimer == SAHPI_WPI_OEM);
}

/********************************************************************************
 *
 * Return true if this a valid watchdog timer use; otherwise false.
 *
 ********************************************************************************/

static inline SaHpiBoolT isValidWatchdogTimerUse(SaHpiWatchdogTimerUseT timerUse)
{
        return (timerUse == SAHPI_WTU_NONE) ||
               (timerUse == SAHPI_WTU_BIOS_FRB2) ||
               (timerUse == SAHPI_WTU_BIOS_POST) ||
               (timerUse == SAHPI_WTU_OS_LOAD) ||
               (timerUse == SAHPI_WTU_SMS_OS) ||
               (timerUse == SAHPI_WTU_OEM) ||
               (timerUse == SAHPI_WTU_UNSPECIFIED);
}

#endif

