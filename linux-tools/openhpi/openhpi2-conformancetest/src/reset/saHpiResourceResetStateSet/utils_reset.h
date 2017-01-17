#ifndef __SAF_HPI_RESET
#define __SAF_HPI_RESET
#include "SaHpi.h"
#include "saf_test.h"

#define HPI_TEST_RETRY_COUNT  8

int check_resetstate(SaHpiResetActionT state)
{
	int ret = 0;
	if (state < SAHPI_RESET_ASSERT || state > SAHPI_RESET_DEASSERT) {
		printf("  reset state is out of range = %d\n", state);
		ret = -1;
	}
	return ret;
}

SaErrorT try_get_resetstate(SaHpiSessionIdT session_id,
			    SaHpiResourceIdT resource_id,
			    SaHpiResetActionT * state)
{
	int retry = 0;
	SaErrorT ret = SA_OK;
	for (retry = 0; retry < HPI_TEST_RETRY_COUNT; retry++) {
		ret = saHpiResourceResetStateGet(session_id,
						 resource_id, state);
		if (ret != SA_ERR_HPI_BUSY) {
			if (ret != SA_OK) {
                                e_print(saHpiResourceResetStateGet,
                                        SA_OK,
                                        ret);
			}
			break;
		}
		sleep(1);
	}
	if (retry >= HPI_TEST_RETRY_COUNT) {
		printf
		    ("  Function \"saHpiResourceResetActionGet\" works abnormally!\n");
		printf("  Timeout on getting reset status!\n");
		printf("  Return value: %s \n", get_error_string(ret));
	}

	return ret;
}

SaErrorT try_set_resetstate(SaHpiSessionIdT session_id,
			    SaHpiResourceIdT resource_id,
			    SaHpiResetActionT state)
{
	int retry = 0;
	SaErrorT ret = SA_OK;
	for (retry = 0; retry < HPI_TEST_RETRY_COUNT; retry++) {
		ret = saHpiResourceResetStateSet(session_id,
						 resource_id, state);
		if (ret != SA_ERR_HPI_BUSY) {
			if (ret != SA_OK) {
				if (ret != SA_ERR_HPI_INVALID_CMD) {
                                        e_print(saHpiResourceResetStateSet,
                                                SA_ERR_HPI_INVALID_CMD,
                                                ret);
				} else {
					printf
					    (" ResetAction not be support by Resource\n");
				}
			}
			break;
		}
		sleep(1);
	}
	if (retry >= HPI_TEST_RETRY_COUNT) {
		printf
		    ("  Function \"saHpiResourceResetActionSet\" works abnormally!\n");
		printf("  Timeout on setting reset status!\n");
		printf("  Return value: %s \n", get_error_string(ret));
	}

	return ret;
}

#endif
