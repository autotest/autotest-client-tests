/*
###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##      1.Redistributions of source code must retain the above copyright notice,          ##
##        this list of conditions and the following disclaimer.                           ##
##      2.Redistributions in binary form must reproduce the above copyright notice, this  ##
##        list of conditions and the following disclaimer in the documentation and/or     ##
##        other materials provided with the distribution.                                 ##
##                                                                                        ##
## THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS AND ANY EXPRESS       ##
## OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF        ##
## MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ##
## THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    ##
## EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF     ##
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ##
## HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,  ##
## OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS  ##
## SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                           ##
############################################################################################
*/
/******************************************************************************/
/*
 * File:        crack_check.c
 *
 * Description: A program that check the security of a password, such that
 *              it cannot be guessed easily. 
 *
 * Author:      Manoj Iyer manjo@mail.utexas.edu
 *
 */

#include <crack.h>                /* Definitions for cracklib functions */
#include <stdlib.h>               /* Definitions for exit()             */

/*
 * Function:    main
 *
 * Description: - Entry point to this program. 
 *              - takes the password and path to the password dictionary files.
 *              - calls the FascistCheck function that will perform.
 *                the password sanity check.
 *
 * Input:       <password>  - password that need to checked for sanity.
 *              <dict path> - path to the password dictionary files.
 *
 * Output:      The program prints the following to stdout:
 *
 * Exit:        0 - in case the password is good 
 *              1 - in case the password is bad
 *              2 - in case the usage of this command is wrong.
 *              
 */
int
main(int   argc,
     char *argv[])
{

	/* expect two arguments, password and path. */
    if (argc < 2)
    {
        exit(2);
    }

	exit(((FascistCheck(argv[1], argv[2])) != NULL) ? 1 : 0);
}
