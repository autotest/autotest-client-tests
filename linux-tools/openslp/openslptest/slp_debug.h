/****************************************************************************/
/* slp_debug                                                                */
/* Creation Date: Wed May 24 14:26:50 EDT 2000                              */
/****************************************************************************/
#include <stdio.h>
#include<stdlib.h>
#define MAX_STRING_LENGTH		4096

typedef struct {
	SLPError	error_number;
	char		*label;
	char		*description;
} SLPErrorEntry;

SLPErrorEntry error_entries[] = {
	{SLP_LAST_CALL,
		"SLP_LAST_CALL",
		"Passed to callback functions when the API library has no more data for them and therefore no further calls will be made to the callback on the currently outstanding operation. The callback can use this to signal the main body of the client code that no more data will be forthcoming on the operation, so that the main body of the client code can break out of data collection loops. On the last call of a callback during both a synchronous and synchronous call, the error code parameter has value SLP_LAST_CALL, and the other parameters are all NULL. If no results are returned by an API operation, then only one call is made , with the error parameter set to SLP_LAST_CALL."},
	{SLP_OK,
		 "SLP_OK",
		 "No DA or SA has service advertisement or attribute information in the language requested, but at least one DA or SA indicated, via the LANGUAGE_NOT_SUPPORTED error code, that it might have information for that service in another language"},
	//SLP_LANGUAGE_NOT_SUPPORTED,
	{-1,
		 "SLP_LANGUAGE_NOT_SUPPORTED",
		 "The SLP message was rejected by a remote SLP agent. The API returns this error only when no information was retrieved, and at least one SA or DA indicated a protocol error. The data supplied through the API may be malformed or a may have been damaged in transit."},
	{SLP_INVALID_REGISTRATION,
		 "SLP_INVALID_REGISTRATION",
		 "The API may return this error if an attempt to register a service was rejected by all DAs because of a malformed URL or attributes. SLP does not return the error if at least one DA accepted the registration."}, 
	{SLP_AUTHENTICATION_ABSENT,
		 "SLP_AUTHENTICATION_ABSENT",
		 "The API returns this error if the SA has been configured with net.slp.useScopes value-list of scopes and the SA request did not specify one or more of these allowable scopes, and no others. It may be returned by a DA or SA if the scope included in a request is not supported by the DA or SA."}, 
	{SLP_INVALID_UPDATE, 
		 "SLP_INVALID_UPDATE", 
		 "if the SLP framework supports authentication, this error arises when the UA or SA failed to send an authenticator for requests or registrations in a protected scope."},
	{SLP_AUTHENTICATION_FAILED, 
		 "SLP_AUTHENTICATION_FAILED", 
		 "If the SLP framework supports authentication, this error arises when a authentication on an SLP message failed"},
	{SLP_INVALID_UPDATE, 
		  "SLP_INVALID_UPDATE", 
		  "An update for a non-existing registration was issued, or the update includes a service type or scope different than that in the initial registration, etc."}, 
	{SLP_REFRESH_REJECTED, 
		  "SLP_REFRESH_REJECTED", 
		  "The SA attempted to refresh a registration more frequently than the minimum refresh interval. The SA should call the appropriate API function to obtain the minimum refresh interval to use."},
	{SLP_NOT_IMPLEMENTED, 
		  "SLP_NOT_IMPLEMENTED", 
		  "If an unimplemented feature is used, this error is returned."},
	{SLP_BUFFER_OVERFLOW,
		  "SLP_BUFFER_OVERFLOW", 
		  "An outgoing request overflowed the maximum network MTU size. The request should be reduced in size or broken into pieces and tried again."},
	{SLP_NETWORK_TIMED_OUT,
		  "SLP_NETWORK_TIMED_OUT", 
		  "When no reply can be obtained in the time specified by the configured timeout interval for a unicast request, this error is returned."},
	{SLP_NETWORK_INIT_FAILED, 
		  "SLP_NETWORK_INIT_FAILED", 
		  "If the network cannot initialize properly, this error is returned. Will also be returned if an SA or DA agent (slpd) can not be contacted. See SLPReg() and SLPDeReg() for more information."},
	{SLP_MEMORY_ALLOC_FAILED, 
		  "SLP_MEMORY_ALLOC_FAILED", 
		  "Out of memory error"},
	{SLP_PARAMETER_BAD, 
		  "SLP_PARAMETER_BAD", 
		  "If a parameter passed into a function is bad, this error is returned."},
	{SLP_NETWORK_ERROR, 
		  "SLP_NETWORK_ERROR ", 
		  "The failure of networking during normal operations causes this error to be returned."},
	{SLP_INTERNAL_SYSTEM_ERROR, 
		  "SLP_INTERNAL_SYSTEM_ERROR", 
		  "A basic failure of the API causes this error to be returned. This occurs when a system call or library fails. The operation could not recover."},
	{SLP_HANDLE_IN_USE, 
		  "SLP_HANDLE_IN_USE", 
		  "In the C API, callback functions are not permitted to recursively call into the API on the same SLPHandle, either directly or indirectly. If an attempt is made to do so, this error is returned from the called API function."},
	{SLP_TYPE_ERROR, 
		  "SLP_TYPE_ERROR", 
		  "If the API supports type checking of registrations against service type templates, this error can arise if the attributes in a registration do not match the service type template for the service."},
};

/* These strings are returned if the error code is not found. */
#define UNKNOWN_ERROR_LABEL			"Unknown"
#define UNKNOWN_ERROR_DESCRIPTION	"Undefined error code."

/*=========================================================================*/
void get_full_error_data(int error_number,
			 char **error_name,
			 char **error_description)
/* Returns data in the parameter variables about the error code            */
/*                                                                         */
/* errorNumber -	Error code received.                                   */
/*                                                                         */
/* errorName -		Name of the error code.                                */
/*                                                                         */
/* errorDescription -		A long winded description about the error.     */
/*                                                                         */
/* Returns -		Nothing.                                               */
/*                                                                         */
/* Comment -		This returns (char *) (const) pointers to the strings  */
/*					which means that deletion of the strings is un-neces-  */
/*					ary.                                                   */
/*=========================================================================*/
{
	int		i;
	int		num_entires;

	/* Determine the number of entries in the error code array. */
	num_entires = sizeof(error_entries) / sizeof(SLPErrorEntry);
	for (i = 0; i < num_entires; i++)
	{
		if (error_entries[i].error_number == error_number)
		{
			*error_name = (error_entries[i].label);
			*error_description = (error_entries[i].description);
			return;
		} /* End If. */
	} /* End For. */
	*error_name = UNKNOWN_ERROR_LABEL;
	*error_description = UNKNOWN_ERROR_DESCRIPTION;
} /* End getFullErrorData(int, char *, char *). */

void check_error_state(int err, char *location_text)
{
    char		*error_name;
    char		*error_description;

    if (err != SLP_OK)
    {
        get_full_error_data(err, &error_name, &error_description);
        printf ("%s\n%d: %s\n%s\n",
            location_text, err, error_name, error_description);
        exit(err);
    } /* End If. */
}

