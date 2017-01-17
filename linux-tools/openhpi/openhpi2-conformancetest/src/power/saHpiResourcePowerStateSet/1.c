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
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiResourcePowerStateSet
 * Description:   
 *   Call saHpiResourcePowerStateSet to set power state of the resources.
 *   Expected return:  call returns SA_OK 
 * Line:        P159-2:P159-4
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

#define HPI_TEST_RETRY_COUNT  8

int check_powerstate(SaHpiPowerStateT state)
{
        int ret = 0;
        if (state < SAHPI_POWER_OFF || state > SAHPI_POWER_ON) {
                printf("  power state is out of range = %d\n", state);
                ret = -1;
        }
        return ret;
}

int Test_Resource(SaHpiSessionIdT session_id,
                  SaHpiRptEntryT rpt_entry, callback2_t func)
{
        SaHpiResourceIdT resource_id;
        SaHpiPowerStateT state, state_old;
        SaErrorT val;
        int ret = SAF_TEST_UNKNOWN;
        int retry;

        resource_id = rpt_entry.ResourceId;
        if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_POWER) {
                for (retry = 0; retry < HPI_TEST_RETRY_COUNT; retry++) {
                        val = saHpiResourcePowerStateGet(session_id,
                                                         resource_id,
                                                         &state_old);
                        if (val != SA_ERR_HPI_BUSY) {
                                if (val != SA_OK) {
                                        e_print(saHpiResourcePowerStateGet,
                                                SA_OK, val);
                                        ret = SAF_TEST_UNRESOLVED;
                                        goto out;
                                }
                                break;
                        }
                        sleep(1);
                }
                if (retry >= HPI_TEST_RETRY_COUNT) {
                        printf
                            ("  Function \"saHpiResourcePowerStateGet\" works abnormally!\n");
                        printf("  Timeout on getting power status!\n");
                        printf("  Return value: %s \n", get_error_string(val));
                        ret = SAF_TEST_UNRESOLVED;
                        goto out;
                }
                state =
                    ((state_old ==
                      SAHPI_POWER_ON) ? SAHPI_POWER_OFF : SAHPI_POWER_ON);
                for (retry = 0; retry < HPI_TEST_RETRY_COUNT; retry++) {
                        val = saHpiResourcePowerStateSet(session_id,
                                                         resource_id, state);
                        if (val != SA_ERR_HPI_BUSY) {
                                if (val != SA_OK) {
                                        e_print(saHpiResourcePowerStateSet,
                                                SA_OK, val);
                                        ret = SAF_TEST_FAIL;
                                        goto out1;
                                }
                                break;
                        }
                        sleep(1);
                }

                if (retry >= HPI_TEST_RETRY_COUNT) {
                        printf
                            ("  Function \"saHpiResourcePowerStateGet\" works abnormally!\n");
                        printf("  Timeout on power cycle!\n");
                        printf("  Return value: %s \n", get_error_string(val));
                        ret = SAF_TEST_FAIL;
                        goto out;
                }

              out1:
                for (retry = 0; retry < HPI_TEST_RETRY_COUNT; retry++) {
                        val = saHpiResourcePowerStateSet(session_id,
                                                         resource_id,
                                                         state_old);
                        if (val != SA_ERR_HPI_BUSY) {
                                if (val != SA_OK) {
                                        e_print(saHpiResourcePowerStateSet,
                                                SA_OK, val);
                                        ret = SAF_TEST_FAIL;
                                }
                                break;
                        }
                        sleep(1);
                }

              out:
                if (ret == SAF_TEST_UNKNOWN)
                        ret = SAF_TEST_PASS;
        } else {
                // Resource Does not support Power Management
                ret = SAF_TEST_NOTSUPPORT;
        }

        return ret;
}

int main()
{
        int ret = SAF_TEST_UNKNOWN;

        ret = process_all_domains(Test_Resource, NULL, NULL);

        return ret;
}
