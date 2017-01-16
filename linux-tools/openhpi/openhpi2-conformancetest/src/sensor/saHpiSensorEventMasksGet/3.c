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
 *     Carl McAdams <carlmc@us.ibm.com>
 *     Xiaowei Yang <xiaowei.yang@intel.com>
 *     Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSensorEventMasksGet
 * Description:   
 *   Call saHpiSensorEventMasksGet passing in valid parameters
 * Line:        P89-20:P89-20
 */
#include <stdio.h>
#include "saf_test.h"

static __inline__ int __mask_is_ok(SaHpiEventStateT rdrmask,
				   SaHpiEventStateT getmask)
{
	return ((~rdrmask) & getmask) == 0;
}

int Test_Rdr(SaHpiSessionIdT session, SaHpiResourceIdT resource, SaHpiRdrT rdr)
{
	int retval = SAF_TEST_UNKNOWN;
	SaErrorT status;
	SaHpiSensorNumT s_num;
	SaHpiEventStateT Assertsaved, Deassertsaved;
	SaHpiEventStateT rdrmask;

	if (rdr.RdrType == SAHPI_SENSOR_RDR) {
		s_num = rdr.RdrTypeUnion.SensorRec.Num;
		rdrmask = rdr.RdrTypeUnion.SensorRec.Events;

		status = saHpiSensorEventMasksGet(session,
						  resource,
						  s_num,
						  &Assertsaved, &Deassertsaved);
		if (status != SA_OK) {
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
			retval = SAF_TEST_FAIL;
			goto out;
		}

		if (!(__mask_is_ok(rdrmask, Assertsaved) &&
		      __mask_is_ok(rdrmask, Deassertsaved))) {
			m_print("Should only set bits that can be set.");
			retval = SAF_TEST_FAIL;
			goto out;
		}

		status = saHpiSensorEventMasksGet(session,
						  resource,
						  s_num, &Assertsaved, NULL);
		if (status != SA_OK) {
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
			retval = SAF_TEST_FAIL;
			goto out;
		}

		if (!(__mask_is_ok(rdrmask, Assertsaved))) {
			m_print("Should only set bits that can be set.");
			retval = SAF_TEST_FAIL;
			goto out;
		}

		status = saHpiSensorEventMasksGet(session,
						  resource,
						  s_num, NULL, &Deassertsaved);
		if (status != SA_OK) {
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
			retval = SAF_TEST_FAIL;
			goto out;
		}

		if (!(__mask_is_ok(rdrmask, Deassertsaved))) {
			m_print("Should only set bits that can be set.");
			retval = SAF_TEST_FAIL;
			goto out;
		}

		status = saHpiSensorEventMasksGet(session,
						  resource, s_num, NULL, NULL);
		if (status != SA_OK) {
			e_print(saHpiSensorEventMasksGet, SA_OK, status);
			retval = SAF_TEST_FAIL;
			goto out;
		}
		retval = SAF_TEST_PASS;
	} else
		retval = SAF_TEST_NOTSUPPORT;
      out:
	return retval;
}

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_SENSOR)
		retval = do_resource(session, report, func);
	else			//Resource Does not support Sensors
		retval = SAF_TEST_NOTSUPPORT;
	return (retval);
}

/**********************************************************
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successfull
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main()
{
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(&Test_Resource, &Test_Rdr, NULL);

	return retval;
}
