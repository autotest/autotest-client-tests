/* Test program, used by the plural-1 test.                                  
   Copyright (C) 2001-2002, 2009, 2015 Free Software Foundation, Inc.          
   This program is free software: you can redistribute it and/or modify        
   it under the terms of the GNU General Public License as published by        
   the Free Software Foundation; either version 3 of the License, or           
   (at your option) any later version.                                         
                                                                             
   This program is distributed in the hope that it will be useful,             
   but WITHOUT ANY WARRANTY; without even the implied warranty of              
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               
   GNU General Public License for more details.                                
                                                                             
   You should have received a copy of the GNU General Public License           
   along with this program.  If not, see <http://www.gnu.org/licenses/>.*/
   
/*
# File :	mytest.c
#
# Description:	This test is based on the plural-1-prg.c in gettext source.
#		It is used to test textdomain, bindtextdomain, ngettext and
#		gettext. 
#
# Author:	Andrew Pham <apham@us.ibm.com>
#
##############################################################################*/

#include <libintl.h>
#include <stdlib.h>
#include <stdio.h>
#include <locale.h>

int main(int argc, char* argv[])
{
	int n = atoi(argv[1]);

	if (setlocale (LC_ALL, "") == NULL)
	{
		setlocale (LC_CTYPE, "");
		setlocale (LC_MESSAGES, "");
	}
	textdomain ("cake");
	bindtextdomain ("cake", "/tmp/gettext");
  
 	if ( n == -1)
		printf (gettext ("a piece of cake"));
	else
		printf (ngettext ("a piece of cake", "%d pieces of cake", n), n);

	printf ("\n");
	return 0;
}
