/*
 * ############################################################################################
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
 *
 * fiv_client.c     Write to a port
 * Created by Bob Paulsen
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/socket.h>
#include <netdb.h>

struct  hostent *he;

char    *me;    /* name of this program */
int port;   /* port number */
int af; /* address family */

void usage()
{
    fprintf(stderr,"usage: %s hostname portnum\n",me);
    fprintf(stderr,"where:\thostname is the server to connect to.\n");
    fprintf(stderr,"where:\tportnum is the port to connect to.\n");
    exit(1);
}

int main(int argc, char **argv)
{
    /* parse args */
    me=argv[0];
    if (argc !=  3 ) usage();
    char    *hostname=argv[1];
    char    *port=argv[2];

    char    *req="Hello!\n";        /* msg to send */
    struct  addrinfo request;
    struct  addrinfo *reply;
    int     n, error, fd;

    /* get addrinfo for the socket */
    memset(&request, 0, sizeof(struct addrinfo));
    request.ai_family = AF_UNSPEC;
    request.ai_flags = AI_PASSIVE;
    request.ai_socktype = SOCK_STREAM;
    error = getaddrinfo(hostname, port, &request, &reply);
    if (error) {
        perror(gai_strerror(error));
        exit (2);
    }
    if (!reply) {
        fprintf(stderr,"No iface found?\n");
        exit (3);
    }

    /* create socket based on addrinfo */
    fd = socket(reply->ai_family, reply->ai_socktype, reply->ai_protocol);
    if (!fd) {
        perror("socket");
        exit(4);
    }
    printf("socket created\n");

    /* connect to host */
    error=connect(fd, reply->ai_addr, reply->ai_addrlen);
    if (error) {
        perror("connect");
        exit(5);
    }
    printf("socket connected\n");

    /* send request string */
    if ((n=send(fd, req, strlen(req), 0)) != strlen(req)) {
        if (n==-1) perror("send");
        else fprintf(stderr,"not all sent\n");
        exit(1);
    }
    printf("data sent\n");

    /* all done! */
    close(fd);
    return 0;
}
