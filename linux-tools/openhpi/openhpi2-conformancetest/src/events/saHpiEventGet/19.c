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
 *     Xiaowei Yang <xiaowei.yang@intel.com>
 *     Qun Li <qun.li@intel.com>
 *     Donald Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventGet
 * Description:
 *      Call the function while another thread called saHpiUnsubscribe
 *      Check if the return code is SA_ERR_HPI_INVALID_REQUEST
 * Line:        P63-28:P63-30
 */

#include <pthread.h>
#include <sys/select.h>
#include <stdio.h>
#include "saf_test.h"
#include <unistd.h>
#include <stdlib.h>

/*****************************************************************************
 * Constants
 *****************************************************************************/

#define MAX_REPEAT 8
#define MAX_PRE_EVENTS 128
#define UNSUBSCRIBE_TIME 2 /* seconds */
#define TIMEOUT  6000000000LL  /* 6 seconds */

/*****************************************************************************
 * Global variables
 *****************************************************************************/

SaHpiSessionIdT sessionId;
SaHpiBoolT runTimerThread;
long timerCounter;

/*****************************************************************************
 * Sleep for a given number of seconds
 *
 * Since sleep() can have side effects due to system signals, use this
 * method to sleep for a given period of seconds.
 *****************************************************************************/

static void mySleep(unsigned int seconds) {
    struct timeval timeout;

    timeout.tv_sec = seconds;
    timeout.tv_usec = 0;

    select( 0, NULL, NULL, NULL, & timeout );
}

/*****************************************************************************
 * Set the timer.  To prevent an event from being added to the system,
 * set the "timerCounter" to a negative value.  NOTE: Do not use zero due
 * to a possible race condition.
 *****************************************************************************/

static void setTimer(long seconds) {
    timerCounter = seconds;
}

/*****************************************************************************
 * Timer Thread function.
 *
 * Keep running until "runTimerThread" becomes false.  After sleeping for
 * one second, decrement the "timerCounter".  When it reaches zero, add an
 * event.  Note that if the "timerCounter" gets set to a negative value in
 * the above setTimer() function, no event will ever be added.  
 *****************************************************************************/

static void *timerThread(void *ptr) {

    while (runTimerThread) {
        mySleep(1);
        timerCounter--;
        if (timerCounter == 0) {
            m_print("Unsubscribe from a separate thread.");
            saHpiUnsubscribe(sessionId);
        }
    }

    return NULL;
}

/*****************************************************************************
 * Clear the Event Queue.
 *****************************************************************************/

static int clearEventQueue(SaHpiSessionIdT sessionId) {
    int retval = SAF_TEST_UNKNOWN;
    int i = 0;
    SaHpiEventT event;
    SaErrorT error;

    /* Clear the event queue */
    while (i++ < MAX_PRE_EVENTS) {
        error = saHpiEventGet(sessionId, SAHPI_TIMEOUT_IMMEDIATE,
                              &event, NULL, NULL, NULL);
        if (error == SA_ERR_HPI_TIMEOUT) {
            break;
        } else if (error != SA_OK) {
            retval = SAF_TEST_UNRESOLVED;
            e_print(saHpiEventGet, SA_OK, error);
            break;
        }
    }

    if (retval == SAF_TEST_UNKNOWN && i >= MAX_PRE_EVENTS) {
        retval = SAF_TEST_UNRESOLVED;
        m_print("Failed to clear event queue");
    }

    return retval;
}

/*****************************************************************************
 * Start the Timer Thread. 
 *****************************************************************************/

static void startTimerThread() {
    pthread_t thread1;
    pthread_attr_t tattr;

    // We will create a detached thread to add an event
    // to the HPI system.

    pthread_attr_init(&tattr);
    pthread_attr_setdetachstate(&tattr, PTHREAD_CREATE_DETACHED);

    runTimerThread = SAHPI_TRUE;
    timerCounter = -1;

    pthread_create(&thread1, &tattr, timerThread, NULL);
}

/*****************************************************************************
 * Stop the Timer Thread.
 *****************************************************************************/

static void stopTimerThread() {
    runTimerThread = SAHPI_FALSE;
}

/*****************************************************************************
 * Main Program
 *****************************************************************************/

int main() {

    SaHpiEventT event;
    SaErrorT error;
    int retval = SAF_TEST_UNKNOWN;
    int i = 0;

    error = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &sessionId, NULL);
    if (error != SA_OK) {
        retval = SAF_TEST_UNRESOLVED;
        e_print(saHpiSessionOpen, SA_OK, error);
    } else {
        error = saHpiSubscribe(sessionId);
        if (error != SA_OK) {
            retval = SAF_TEST_UNRESOLVED;
            e_print(saHpiSubscribe, SA_OK, error);
        } else {

            startTimerThread();

            /* Let's try the test a max of MAX_REPEAT times in case
             * we encounter some unwanted events.  Essentially, we
             * wait for in saHpiEventGet() for 6 seconds, but after
             * 2 seconds we will unsubscribe for events from a separate
             * thread.  If we can go 2 seconds without an unwanted
             * event, then we should get an INVALID_REQUEST error code
             * returned. 
             */

            i = 0;
            while (i++ < MAX_REPEAT) {

                retval = clearEventQueue(sessionId);
                if (retval != SAF_TEST_UNKNOWN) {
                    break;
                } else {
                    setTimer(UNSUBSCRIBE_TIME);

                    error = saHpiEventGet(sessionId, TIMEOUT,
                                          &event, NULL, NULL, NULL);

                    setTimer(-1);

                    if (error == SA_ERR_HPI_INVALID_REQUEST) {
                        retval = SAF_TEST_PASS;
                        break;
                    } else if (error != SA_OK) {
                        retval = SAF_TEST_FAIL;
                        e_print(saHpiEventGet, SA_ERR_HPI_INVALID_SESSION | SA_OK, error);
                        break;
                    }
                }
            }

            stopTimerThread();

            if (retval == SAF_TEST_UNKNOWN) {
                retval = SAF_TEST_UNRESOLVED;
                m_print("Too many system events occurred during the test.");
            }

            error = saHpiUnsubscribe(sessionId);
        }
        error = saHpiSessionClose(sessionId);
    }

    return retval;
}

