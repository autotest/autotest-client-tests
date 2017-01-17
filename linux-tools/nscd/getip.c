/*###########################################################################################
 * ## Copyright 2003, 2015 IBM Corp                                                          ##
 * ##                                                                                        ##
 * ## Redistribution and use in source and binary forms, with or without modification,       ##
 * ## are permitted provided that the following conditions are met:                          ##
 * ##      1.Redistributions of source code must retain the above copyright notice,          ##
 * ##        this list of conditions and the following disclaimer.                           ##
 * ##      2.Redistributions in binary form must reproduce the above copyright notice, this  ##
 * ##        list of conditions and the following disclaimer in the documentation and/or     ##
 * ##        other materials provided with the distribution.                                 ##
 * ##                                                                                        ##
 * ## THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS AND ANY EXPRESS       ##
 * ## OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF        ##
 * ## MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ##
 * ## THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    ##
 * ## EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF     ##
 * ## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ##
 * ## HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,  ##
 * ## OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS  ##
 * ## SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                           ##
 * ############################################################################################
 * */
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <string.h>

int main (int argc, char *argv[]) {
   char Address[257];
   int AddrLen=sizeof(Address);
   struct addrinfo Hints, *AddrInfo, *AI;
   char v6addr[INET6_ADDRSTRLEN+1];
   int Family = PF_UNSPEC;
   int SocketType = SOCK_STREAM;
   struct hostent *hptr;
   int ret;

   memset(&Hints, 0, sizeof(Hints));
   Hints.ai_family = Family;
   Hints.ai_socktype = SocketType;

   memset(Address,0, sizeof(Address));
   memset(v6addr,0, sizeof(v6addr));

   if (argc > 1)
     strcpy (Address, argv[1]);
   else 
     gethostname(Address,sizeof(Address));

   ret = getaddrinfo(Address, NULL, &Hints, &AddrInfo);
   if (ret) {
	fprintf(stderr,"getaddrinfo(%s): %s\n",Address, gai_strerror(ret));
	exit(1);
   }

   for( AI = AddrInfo; AI != NULL; AI = AI->ai_next) {
      getnameinfo((struct sockaddr *)AI->ai_addr, AI->ai_addrlen, v6addr,
                      sizeof(v6addr), NULL, 0, NI_NUMERICHOST);
      printf("[%s]\n", v6addr );
   }

   return 0;
}



