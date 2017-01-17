/*      -*- linux-c -*-
 *
 * Copyright (c) 2003 by Intel Corp.
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005  University of New Hampshire
 *
 *   This program is free software; you can redistribute it and/or modify 
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or 
 *   (at your option) any later version.
 *   This program is distributed in the hope that it will be useful, 
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of 
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 *   GNU General Public License for more details. 
 *   You should have received a copy of the GNU General Public License 
 *   along with this program; if not, write to the Free Software 
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 
 *   USA 
 *
 * Authors:
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *     Wang Jing <jing.j.wang@intel.com>	
 *     Qun Li <qun.li@intel.com>
 *     Donald A. Barre <dbarre@unh.edu>
 */

#ifndef HPI_TEST
#define HPI_TEST

#include <im_spec.h>
#include <string.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>

//  All standard Test Return Status Defined in saf_test.h
//
//#define SAF_TEST_PASS	        0
//#define SAF_TEST_FAIL	        1
//#define SAF_TEST_BLOCK	2
//#define SAF_TEST_NOTSUPPORT	3
//#define SAF_TEST_UNRESOLVED   4
//#define SAF_TEST_UNKNOWN      5

// PASS AND EXIT is not a valid test return.  Use only for execution logic
// in proceedures.
#define SAF_TEST_PASS_AND_EXIT	20       //Not valid as a test return


#define SAF_TEST_DOMAIN_LIST_SIZE 32


/********************************************************************
 *
 * These are the invalid values used for all of the tests.
 * While it it highly likely that these values are invalid, there
 * is a small chance of validity.  If that occurs, these values
 * should be changed and the tests rebuilt.
 *
 ********************************************************************/

#define INVALID_SESSION_ID  0xDEADBEEF
#define INVALID_RESOURCE_ID 0xDEADBEEF
#define INVALID_RDR_NUM     0xDEADBEEF


//Ignore resource&rdr list
/* {resource_name, rdr_name} */
#define MAX_IGNCNT    32
#define MAX_ITEMCNT   128 
char memPool[MAX_IGNCNT*MAX_ITEMCNT*2];
char *IgnList[MAX_IGNCNT][2]={{NULL,NULL},};
char *IGNFILE="ignore_res.cfg";

void repl_space(char *str){
        if (str == NULL)
                return;
        while(*str){
                if (*str==' '){
                        *str='\0';
                        break;
                }        
                if (*str=='~')
                        *str=' ';
                str++;
        }        
}


void read_ignList(){
        FILE* fp;
        char    *strRdrTag,*strRptTag;
        int i;

        fp=fopen(IGNFILE,"r");
        if(NULL==fp){
                return;
        }
        printf("Find ignoreList file\n");
        for(i=0;i<MAX_IGNCNT;i++){
                strRptTag = &memPool[i*MAX_ITEMCNT*2];
                strRdrTag = &memPool[i*MAX_ITEMCNT*2+MAX_ITEMCNT];
                if (fscanf(fp,"%s %s",strRptTag,strRdrTag)==EOF)
                        break;
                repl_space(strRptTag);
                repl_space(strRdrTag);
                printf("item%d:%s %s;\n",i,strRptTag,strRdrTag);
                IgnList[i][0]=strRptTag;
                IgnList[i][1]=strRdrTag;
        }
        if (i++<MAX_IGNCNT){
                IgnList[i][0]=NULL;
                IgnList[i][1]=NULL;
        }                

}

int check_ignList(SaHpiRptEntryT rpt_entry,SaHpiRdrT rdr){
	int rtcode = 0;
	int i=0;
        char    strRdrTag[MAX_ITEMCNT],strRptTag[MAX_ITEMCNT];
        
        memcpy(strRdrTag,rdr.IdString.Data,rdr.IdString.DataLength);
        strRdrTag[rdr.IdString.DataLength]=0;
        memcpy(strRptTag,rpt_entry.ResourceTag.Data,rpt_entry.ResourceTag.DataLength);
        strRptTag[rpt_entry.ResourceTag.DataLength]=0;
                
        while (IgnList[i][0]!=NULL){
		if (strcmp(IgnList[i][0],strRptTag)==0 && (strcmp(IgnList[i][1],"*")==0
                                        || strcmp(IgnList[i][1],strRdrTag)==0)){
			printf("  Match blacklist %s - %s\n", strRptTag,strRdrTag);
			rtcode = -1;
			break;
		}
		i++;
	}
	return rtcode;
}


// function to call on individual RDR's 
typedef int (*callback2_t)(SaHpiSessionIdT      session_id, 
                           SaHpiResourceIdT     resource_id, 
                           SaHpiRdrT            rdr); 
// function to call on individual resouces
typedef int (*callback_t)(SaHpiSessionIdT       session_id, 
                          SaHpiRptEntryT        rpt_entry,     
                          callback2_t           func);
// function to call on individual domains
typedef int (*callback3_t)(SaHpiSessionIdT      session_id);

static inline const char * get_error_string(SaErrorT error)
{
	switch(error) {
		case SA_OK:
			return "SA_OK";
		case SA_ERR_HPI_ERROR:
			return "SA_ERR_HPI_ERROR";
		case SA_ERR_HPI_UNSUPPORTED_API:
			return "SA_ERR_UNSUPPORTED_API";
		case SA_ERR_HPI_BUSY:
			return "SA_ERR_HPI_BUSY";
                case SA_ERR_HPI_INTERNAL_ERROR:
                        return "SA_ERR_HPI_INTERNAL_ERROR";
		case SA_ERR_HPI_INVALID_CMD:
			return "SA_ERR_HPI_INVALID_CMD";
		case SA_ERR_HPI_TIMEOUT:
			return "SA_ERR_HPI_TIMEOUT";
		case SA_ERR_HPI_OUT_OF_SPACE:
			return "SA_ERR_HPI_OUT_OF_SPACE";
                case SA_ERR_HPI_OUT_OF_MEMORY:
                        return "SA_ERR_HPI_OUT_OF_MEMORY";
		case SA_ERR_HPI_INVALID_PARAMS:
			return "SA_ERR_HPI_INVALID_PARAMS";
		case SA_ERR_HPI_INVALID_DATA:
			return "SA_ERR_HPI_INVALID_DATA";
		case SA_ERR_HPI_NOT_PRESENT:
			return "SA_ERR_HPI_NOT_PRESENT";
		case SA_ERR_HPI_NO_RESPONSE:
			return "SA_ERR_HPI_NO_RESPONSE";
		case SA_ERR_HPI_DUPLICATE:
			return "SA_ERR_HPI_DUPLICATE";
		case SA_ERR_HPI_INVALID_SESSION:
			return "SA_ERR_HPI_INVALID_SESSION";
                case SA_ERR_HPI_INVALID_DOMAIN:
                        return "SA_ERR_HPI_INVALID_DOMAIN";
		case SA_ERR_HPI_INVALID_RESOURCE:
			return "SA_ERR_HPI_INVALID_RESOURCE";
		case SA_ERR_HPI_INVALID_REQUEST:
			return "SA_ERR_HPI_INVALID_REQUEST";
		case SA_ERR_HPI_ENTITY_NOT_PRESENT:
			return "SA_ERR_HPI_ENTITY_NOT_PRESENT";
                case SA_ERR_HPI_READ_ONLY:
                        return "SA_ERR_HPI_READ_ONLY";
                case SA_ERR_HPI_CAPABILITY:
                        return "SA_ERR_HPI_CAPABILITY";
                case SA_ERR_HPI_UNKNOWN:
                        return "SA_ERR_HPI_UNKNOWN";
		default:
			return "(invalid error code)";
	}
}

char * get_test_result(int error){
        switch(error) {
        	case SAF_TEST_PASS:
			return "SAF_TEST_PASS";
        	case SAF_TEST_PASS_AND_EXIT:
			return "SAF_TEST_PASS_AND_EXIT";
		case SAF_TEST_FAIL:
			return "SAF_TEST_FAIL";
                case SAF_TEST_BLOCK:
                        return "SAF_TEST_BLOCK";
		case SAF_TEST_NOTSUPPORT:
			return "SAF_TEST_NOTSUPPORT";
		case SAF_TEST_UNRESOLVED:
			return "SAF_TEST_UNRESOLVED";
		case SAF_TEST_UNKNOWN:
			return "SAF_TEST_UNKNOWN";
		default:
			return "Invalid result";
	}		
}

/************************************************************************
 *
 * Return the severity as a string.  
 *
 ************************************************************************/

static inline const char *get_severity_str(SaHpiSeverityT severity)
{
        char *buf;

        switch(severity) {
        	case SAHPI_CRITICAL:
			return "SAHPI_CRITICAL";
        	case SAHPI_MAJOR:
			return "SAHPI_MAJOR";
        	case SAHPI_MINOR:
			return "SAHPI_MINOR";
        	case SAHPI_INFORMATIONAL:
			return "SAHPI_INFORMATIONAL";
        	case SAHPI_OK:
			return "SAHPI_OK";
        	case SAHPI_DEBUG:
			return "SAHPI_DEBUG";
        	case SAHPI_ALL_SEVERITIES:
			return "SAHPI_ALL_SEVERITIES";
		default:
                {
                        /* a little memory leak; don't worry about it */
                        buf = (char *) malloc(50);
                        sprintf(buf, "Unknown Severity (0x%x)", severity);
			return buf;
                }
	}
}

void show_resource_name_by_id(SaHpiSessionIdT session_id,SaHpiResourceIdT resource_id, char *comments){

        SaHpiRptEntryT rpt_entry;
        SaErrorT       val;
        char            strTag[256];
        val = saHpiRptEntryGetByResourceId(session_id,
                                           resource_id,
                                                &rpt_entry);
        if (val != SA_OK) {
                printf("  Fail to show tag\n");
                return;
        }
        memcpy(strTag,rpt_entry.ResourceTag.Data,rpt_entry.ResourceTag.DataLength);
        strTag[rpt_entry.ResourceTag.DataLength]=0;
	if (comments)
		printf("  resource_id=%d, tag=%s, return=%s\n",resource_id,strTag,comments);
	else
		printf("  resource_id=%d, tag=%s\n",resource_id,strTag);

}


static inline int do_resource(SaHpiSessionIdT   session_id,
                              SaHpiRptEntryT    rpt_entry, 
                              callback2_t       rdr_test_func)
{
	SaHpiEntryIdT  	current_rdr;
	SaHpiEntryIdT  	next_rdr;
	SaHpiRdrT    	rdr;
	SaErrorT       	val;
	int            	ret = SAF_TEST_UNKNOWN;
	int 		r;
        int             num_passed = 0;

        // Run the Function when the passed in function is valid and 
        // the resource capabilities
        if ((rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_RDR) && 
            (rdr_test_func != NULL))
        {
		next_rdr = SAHPI_FIRST_ENTRY;
		while (next_rdr != SAHPI_LAST_ENTRY) {
                        char strTag[256];
			current_rdr = next_rdr;
			val = saHpiRdrGet(session_id, 
                                          rpt_entry.ResourceId,
                                          current_rdr, 
                                          &next_rdr, 
                                          &rdr);
                        if (val != SA_OK) {
                                printf("  Error in core execution\n");
                                printf("  Unable to get an Rdr\n");
                                printf("  saHpiRdrGet returned: %s.\n",get_error_string(val));
				ret = SAF_TEST_UNRESOLVED;
				break;
			}
			if (check_ignList(rpt_entry,rdr)<0)
				continue;
                        memcpy(strTag,rdr.IdString.Data,rdr.IdString.DataLength);
                        strTag[rdr.IdString.DataLength]=0;
                        printf("\n  ----------------%s\n",strTag);
                        // Execute the Rdr Specific test for this Resource
			r = (*rdr_test_func)(session_id, rpt_entry.ResourceId, rdr);
                        printf("  ----------------%s\n",get_test_result(r));
                        // When the test returns the SAF_TEST_PASS_AND_EXIT, 
                        //  set the result as PASS and quit executing on other 
                        //  RDR's 
                        if (r == SAF_TEST_PASS_AND_EXIT) 
                        {
                                ret = SAF_TEST_PASS_AND_EXIT;
                                break;
                        }

                        if (r == SAF_TEST_PASS)
                        {
                                num_passed++;
                        }
                        // When the last test returns NOTSUPPORT, but we
                        // still has at least one which passed, then
                        // return SAF_TEST_PASS
                        if ((r == SAF_TEST_NOTSUPPORT) && (num_passed > 0))
                        {
                                r = SAF_TEST_PASS;
                        }

                        ret = r;

                        if (ret == SAF_TEST_FAIL || ret == SAF_TEST_UNRESOLVED)
                                break;
		}
	}
        else
        {
                ret = SAF_TEST_NOTSUPPORT;
        }
        return ret;
}


static inline int check_domain(SaHpiDomainIdT        domain_id,
				SaHpiSessionIdT session_id,
                                  callback_t            func, 
                                  callback2_t           func2, 
                                  callback3_t           func3)
{
        SaHpiEntryIdT	next_entry_id, temp_id;
	SaHpiRptEntryT	rpt_entry;
	SaErrorT       	status;
	int            	retval = SAF_TEST_UNKNOWN;
	int 		r;
        int             num_passed = 0;

        
        if ((retval == SAF_TEST_UNKNOWN) && (func3 != NULL))
        {
                printf("\n*****************Domain func begin***************\n");
                r = (*func3)(session_id);
                printf("\n  return=%s\n",get_test_result(r));
                printf("\n*****************Domain func end*****************\n");
                //NOTE:  if is this function is just to set up
                //       test conditions, then will require
                //       reseting the retval to SAF_TEST_UNKNOWN

                // successfully found an testable domain
                // this is all that is needed to return
                // successful
                if (r == SAF_TEST_PASS_AND_EXIT) 
                {
                        retval = SAF_TEST_PASS;
			goto out;
                }
                if (r == SAF_TEST_FAIL ||r == SAF_TEST_UNRESOLVED)
                {
                        retval = r;
                        goto out; 
                }
                if (r == SAF_TEST_PASS){
			num_passed++;	
		}
        }

       	//
       	// Perform test function on a per resource basis
      	//
        if (func != NULL)
        {
                next_entry_id = SAHPI_FIRST_ENTRY;
                while (next_entry_id != SAHPI_LAST_ENTRY){
                        char strTag[256];
                        temp_id = next_entry_id;
                        status = saHpiRptEntryGet(session_id, temp_id, 
                                        &next_entry_id, &rpt_entry);
                        if (status != SA_OK) {
                                retval = SAF_TEST_NOTSUPPORT;
                                break;
                        }
                        memcpy(strTag,rpt_entry.ResourceTag.Data,rpt_entry.ResourceTag.DataLength);
                        strTag[rpt_entry.ResourceTag.DataLength]=0;
                                        
			printf("\n*****************Resource %d: %s begin******************\n",rpt_entry.ResourceId,strTag);
                        r = (*func)(session_id, rpt_entry, func2);
                        printf("\n  resource_id=%d, tag=%s, return=%s\n",rpt_entry.ResourceId,strTag,get_test_result(r));
			printf("*****************Resource %d: %s end********************\n",rpt_entry.ResourceId,strTag);
			// A failure negates the success of all of 
                        // the resources
                        if (r == SAF_TEST_FAIL ||r == SAF_TEST_UNRESOLVED)
                        {
				retval = r;
			// If you want to check not so strictly, comment the next line - break;		
                             	break;
                        }
                        // successfully found an testable instance
                        // this is all that is needed to return
                        // successful
                        if (r == SAF_TEST_PASS_AND_EXIT) 
                        {
                                retval = SAF_TEST_PASS;
                                break;
                        }
                        //If just one resource passes, then the test
                        // is valid. All N/A and Unknown returns are
                        // ignored.
                        if (r == SAF_TEST_PASS){
				num_passed++;	
			}
                }
        }
	if (retval == SAF_TEST_UNKNOWN && num_passed>0)
		retval = SAF_TEST_PASS;
	if (retval == SAF_TEST_UNKNOWN)
		retval = SAF_TEST_NOTSUPPORT;
out:
	return retval;

}



static inline int process_domain(SaHpiDomainIdT        domain_id,
                                  callback_t            func, 
                                  callback2_t           func2, 
                                  callback3_t           func3)
{
	SaHpiSessionIdT session_id;
	SaErrorT       	status;
	int            	retval = SAF_TEST_UNKNOWN;


        //
        // First process the default domain
        //
	status = saHpiSessionOpen(domain_id, &session_id, NULL);
	if (status != SA_OK){ 
		retval = SAF_TEST_UNRESOLVED;
        	goto out;
	}
        
	retval=check_domain(domain_id,session_id,func,func2,func3);
out:
	return retval;

}

 
static inline int process_domains(SaHpiDomainIdT        domain_id,
                                  callback_t            func, 
                                  callback2_t           func2, 
                                  callback3_t           func3)
{
	SaHpiSessionIdT session_id;
        SaHpiEntryIdT	next_entry_id, temp_id;
        SaHpiDrtEntryT  domain_table_entry;
	SaErrorT       	status;
	int            	retval = SAF_TEST_UNKNOWN;
	int 		testing_retval = SAF_TEST_UNKNOWN;
        int             num_passed = 0;


        // Init IgnList
        read_ignList();
        // First process the default domain
        //
	printf("Open Domain 0\n");
	status = saHpiSessionOpen(domain_id, &session_id, NULL);
	if (status != SA_OK){ 
		retval = SAF_TEST_UNRESOLVED;
        	goto out;
	}

	printf("Start Check Domain 0\n");
	retval=check_domain(domain_id,session_id,func,func2,func3);
	printf("End Check Domain 0,return=%s\n",get_test_result(retval));
	if (retval==SAF_TEST_FAIL || retval==SAF_TEST_UNRESOLVED){
		testing_retval=retval;
		goto out1;
	}

	if (retval == SAF_TEST_PASS)
		num_passed++;
	

        next_entry_id = SAHPI_FIRST_ENTRY;
        while (next_entry_id != SAHPI_LAST_ENTRY)
        {
                temp_id = next_entry_id;
                status = saHpiDrtEntryGet(session_id,
                                          temp_id,
                                         &next_entry_id,
                                          &domain_table_entry);
               	// test if error or empty
               	if (status != SA_OK)
               	{
                	break;
               	}
	       	printf("Start Process domain %d\n",domain_table_entry.DomainId);
               	retval = process_domain(domain_table_entry.DomainId,
                                                    func, 
                                                    func2, 
                                                    func3);
                                // A failure negates the success of all 
                                //  of the children domains
	       	printf("End Process domain %d,return=%s\n",domain_table_entry.DomainId,get_test_result(retval));	
        	if (retval==SAF_TEST_FAIL || retval==SAF_TEST_UNRESOLVED){
                	testing_retval=retval;
                	break;	
        	}

        	if (retval == SAF_TEST_PASS)
        	{
                	num_passed++;
        	}	

        } //end of while loop testing each child domain
		
        if (testing_retval == SAF_TEST_UNKNOWN && num_passed>0)
		testing_retval= SAF_TEST_PASS;
        if (testing_retval == SAF_TEST_UNKNOWN)
        	testing_retval = SAF_TEST_NOTSUPPORT;
		
out1:       
        status = saHpiSessionClose(session_id);
out:
	return testing_retval;
}

static inline int process_all_domains(callback_t func, 
                                      callback2_t func2, 
                                      callback3_t func3)
{
        int retval = SAF_TEST_UNKNOWN;

        // The primary purpose of this array of domainId's is to prevent an 
        // unbreakable loop when testing a peer domain infrastructure.  

        retval = process_domains(SAHPI_UNSPECIFIED_DOMAIN_ID, 
                                 func, 
                                 func2, 
                                 func3);

	return retval;
}




static inline int process_single_domain(callback3_t domain_test_func)
{
        SaHpiSessionIdT         session;
        SaErrorT                status;
        int                     retval = SAF_TEST_UNKNOWN;

        //
        //  Open the session
        //
        // Init IgnList
        read_ignList();
        printf("Open Domain\n");
        status = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &session, NULL);
        
        if (status != SA_OK)
        {
                printf("  Error in core execution\n");
                printf("  Unable to open a session\n");
                printf("  saHpiSessionOpen returned: %s.\n",get_error_string(status));
                retval = SAF_TEST_UNRESOLVED;
        }
        else
        {
                retval = (*domain_test_func)(session);

                if (retval == SAF_TEST_PASS_AND_EXIT)
                {
                        retval = SAF_TEST_PASS;
                }

                //
                // Close the session
                //
                status = saHpiSessionClose(session);
                 // test is still valid if this fails do to an error
                 // so there is no error handling for this call.
        }

        return(retval);
}

/** 
 * Macro for error report.
 *
 * @func_name [in]:	points out which function is wrong
 * @expected_rv [in]:	expected return value, such as SA_OK
 * @err_rv [in]:	error return value we've got
 */
#define e_print(func_name, expected_rv, err_val)        \
do {                                                    	\
        fprintf(stderr, "  Function \"%s\" works abnormally!\n", #func_name);    \
        fprintf(stderr, "  %s at %s, line %d\n", __func__, __FILE__, __LINE__); \
        fprintf(stderr, "  Expected return value: %s\n", #expected_rv); 	\
        fprintf(stderr, "  Return value: %s\n", get_error_string(err_val)); 	\
} while(0)

/** 
 * Macro for printing a message.
 *
 * @message [in]:	message to print (printf format)
 * @args [in]:		arguments 
 */
#define m_print(message, args...)    \
do {                  \
    fprintf(stderr, "  "); \
    fprintf(stderr, message, ##args); \
    fprintf(stderr, "\n"); \
    fprintf(stderr, "  %s at %s, line %d\n", __func__, __FILE__, __LINE__); \
} while(0)

/** 
 * Trace print.  
 */
#define e_trace()    \
do {                    \
    fprintf(stderr, "  %s at %s, line %d\n", __func__, __FILE__, __LINE__); \
} while(0)


/************************************************************************
 *
 * Get the current time of day in milliseconds.
 *
 * **********************************************************************/

typedef unsigned long long int SafTimeT __attribute__((__aligned__(8)));

static inline SafTimeT getCurrentTime()
{
	struct timeval tv;

	gettimeofday(&tv, NULL);
	return ((SafTimeT) tv.tv_sec) * 1000 + ((tv.tv_usec + 500) / 1000);
}


/************************************************************************
 *
 * Get the val from environment variable.
 *
 * **********************************************************************/

int try_get_int_val_from_env(const char *envstr, int def_val){
        char *len_str=NULL;
        int len=0;
        if ((len_str = getenv(envstr)) != NULL){
                len=atoi(len_str);
                printf("  get the env value=%d\n",len);
        }
        if (len==0)
                len=def_val;
        return len;
}

/**
 * A standard function used to print prompt and get response.
 *
 * @prompt: message dump to stdout
 * @return: -1 indicates an error, 0 on success.
 */
int read_prompt(const char * prompt)
{
        struct termios  old, new;

        /* save old value */
        if (tcgetattr(1, &old) != 0)
                return -1;

        printf("%s", prompt);
        fflush(stdout);

        /* no ECHO */
        new = old;
        new.c_lflag &= ~ECHO;
        if (tcsetattr(1, TCSAFLUSH, &new) != 0)
                return -1;

        while (getchar() != '\n')
                continue;

        /* restore old value */
        (void) tcsetattr(1, TCSAFLUSH, &old);
        return 0;
}

#endif
