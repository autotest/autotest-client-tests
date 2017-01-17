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
 * Function:    saHpiSensorEventEnableSet
 * Description:   
 *   Event states may still be read for a sensor even if the event
 *   generation is disabled, by using saHpiSensorReadingGet().
 *   Expected return: SA_OK.
 * Line:        P88-26:P88-27
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

int Test_Rdr(SaHpiSessionIdT session_id, SaHpiResourceIdT resource_id,
	     SaHpiRdrT rdr)
{
	SaHpiBoolT enable = SAHPI_FALSE, enable_old;
	SaErrorT val;
	SaHpiSensorNumT num;
	SaHpiEventStateT event_state;
	int ret = SAF_TEST_UNKNOWN;

	/* Need to skip sensors which we can't set */
	if (rdr.RdrType == SAHPI_SENSOR_RDR &&
	    rdr.RdrTypeUnion.SensorRec.EventCtrl != SAHPI_SEC_READ_ONLY) {
		num = rdr.RdrTypeUnion.SensorRec.Num;

		val =
		    saHpiSensorEnableGet(session_id, resource_id, num, &enable);
		if (val != SA_OK) {
			e_print(saHpiSensorReadingGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out;
		}

		if (enable == SAHPI_FALSE) {
			m_print("sensor is currently disabled");
			ret = SAF_TEST_NOTSUPPORT;
			goto out;
		}

		val = saHpiSensorEventEnableGet(session_id, resource_id, num,
						&enable_old);
		if (val != SA_OK) {
			e_print(saHpiSensorEventEnableGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out;
		}

		if (enable_old) {
			enable = SAHPI_FALSE;

			val =
			    saHpiSensorEventEnableSet(session_id, resource_id,
						      num, enable);
			if (val != SA_OK) {
				e_print(saHpiSensorEventEnableSet, SA_OK, val);
				ret = SAF_TEST_UNRESOLVED;
				goto out1;
			}
		}

		val = saHpiSensorReadingGet(session_id, resource_id, num,
					    NULL, &event_state);
		if (val != SA_OK) {
			if (val == SA_ERR_HPI_ENTITY_NOT_PRESENT) {
				m_print("sensor is not present.");
				ret = SAF_TEST_NOTSUPPORT;
				goto out1;
			}
			e_print(saHpiSensorReadingGet, SA_OK
				|| SA_ERR_HPI_ENTITY_NOT_PRESENT, val);
			m_print("Resource id: %u; sensor number: %u",
				resource_id, num);
			ret = SAF_TEST_FAIL;
		} else if (event_state == 0) {
			m_print("Need to see some asserted event states.");
			ret = SAF_TEST_NOTSUPPORT;
		} else {
			ret = SAF_TEST_PASS;
		}

	      out1:
		val = saHpiSensorEventEnableSet(session_id, resource_id, num,
						enable_old);
		if (val != SA_OK) {
			e_print(saHpiSensorEventEnableSet, SA_OK, val);
		}
	} else
		ret = SAF_TEST_NOTSUPPORT;
      out:
	return ret;
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
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(Test_Resource, Test_Rdr, NULL);

	return ret;
}
