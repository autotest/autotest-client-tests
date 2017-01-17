/*###########################################################################################
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
#include <stdio.h>
#include <string.h>

/*
 * A function to check the output of dos2unix.
 */

int main (int argc, char *argv[])
{
	FILE * input = NULL;
	int cr = 0, nl = 0, TempChar;

	if (argc < 3)
	{
		fprintf(stderr, "\nUsage: %s mode inputfile\n\n", argv[0]);
		return -1;
	}

	if ((input=fopen(argv[2], "r")) == NULL)
	{
		 fprintf(stderr, "Unable to open file %s.\n", argv[2]);
                 return -1;
	}

	while ((TempChar = getc(input)) != EOF)
	{
		if ( TempChar == '\r' )
		{
			cr++;
			break;
		}

		if ( TempChar == '\n' )
                        nl++;
	}

	if (strcmp (argv[1],"dos") == 0)
		return cr;
	else if (strcmp (argv[1],"mac") == 0)
	{
		if ( nl != 6 )
			return nl;
		
		return cr;
	}
	else
		return -1;
}

