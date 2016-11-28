//
// vi: ts=2 sw=2 autoindent expandtab :
//
//  README  README  README  README  README  README
//
//  This file contains a trivial version of a replacement
//   for wbemcat. The key difference is that this is IPv6
//   aware and can be used to test if the cimom is returning
//   what we want it to. It's almost a drop in replacement
//   for wbemcat in the xmltest script. The only change you
//   really need to make is to supply the hostname as an
//   argument. Note that it expects an ipv6 hostname.
//   This is how it was called, in xmltest, for ipv6 testing:
//
// ./cabbey shadows.ipv6.lab $_TESTXML 2> $$.errout > $_TESTRESULT
//
//   (note that this was in client/server mode from a
//    seperate machine)
//


#include <sys/socket.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <netdb.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/sendfile.h>
#include <fcntl.h>

int main (int argc, char** argv) {
  
  struct addrinfo request;
  struct addrinfo *reply;
  void * tmp;
  struct stat finfo;
  char * walk;
  char step;
  char scratch[1000];
  int timeout=60;
  int error, fd, fdxml, len, dest, retval;
  fd_set  rfds;
  struct  timeval tv;
  int httpOK, httpLen, sofar;

  memset(&request, 0, sizeof(struct addrinfo));
  memset(&finfo, 0, sizeof (struct stat));

  if (argc != 3) {
    fprintf(stderr,"usage: %s hostname /path/to/xml\n", argv[0]);
    exit(1);
  }
  
  request.ai_family = AF_UNSPEC;
  request.ai_flags = AI_PASSIVE;
  request.ai_socktype = SOCK_STREAM;
  error = getaddrinfo(argv[1], "5988", &request, &reply);

  if (error) {
    perror(gai_strerror(error));
    exit(2);
  }
  if (!reply) {
    fprintf(stderr,"No ipv6 iface found?\n");
    exit(3);
  }

//  fprintf(stderr,"addrinfo {\n ai_flags %X\n ai_family %X\n ai_socktype %X\n ai_protocol %X\n ai_addrlen %X\n sockaddr {\n  sa_family %X\n", reply->ai_flags, reply->ai_family, reply->ai_socktype, reply->ai_protocol, reply->ai_addrlen, reply->ai_addr->sa_family);

  switch (reply->ai_family) {
  case 0x0A :
    tmp=(void *)(&((struct sockaddr_in6*)(reply->ai_addr))->sin6_addr);
    dest=inet_ntop(AF_INET6, tmp, scratch, 99);
    if (!dest) {
      fprintf(stderr,"  port %d\n  address %s\n",
        htons(((struct sockaddr_in6*)(reply->ai_addr))->sin6_port),
        scratch
      );
    }
    break;
  case 0x02 :
    tmp=(void *)(&((struct sockaddr_in*)(reply->ai_addr))->sin_addr);
    dest=inet_ntop(AF_INET, tmp, scratch, 99);
    if (!dest) {
        fprintf(stderr,"  port %d\n  address %s\n",
            htons(((struct sockaddr_in*)(reply->ai_addr))->sin_port),
            scratch
        );
    }
    break;
  }

//  fprintf(stderr," } ai_addr\n}\n");

  fd = socket(reply->ai_family, reply->ai_socktype, reply->ai_protocol);
  if (!fd) {
    perror("socket");
    exit(4);
  }

//  fprintf(stderr,"socket created\n");

  error=connect(fd, reply->ai_addr, reply->ai_addrlen);
  if (error) {
    perror("connect");
    exit(5);
  }

//  fprintf(stderr,"socket connected\n");
  
  if( stat(argv[2], &finfo) != 0 ) {
    perror("stat");
    exit(6);
  }

  fdxml = open(argv[2], O_RDONLY);
  if (! fdxml ) {
    perror("open");
    exit(7);
  }


  len = snprintf(scratch, 999, "POST /cimom HTTP/1.1\nHost: %s\nContent-Type: application/xml; charset=\"utf-8\"\nContent-Length: %d\nCIMProtocolVersion: 1.0\nCIMOperation: MethodCall\n\n", argv[1], finfo.st_size);

//  fprintf(stderr,"bytes in header %d\n", len);
//  fprintf(stderr,"request:\n%s\n",scratch);

  if (-1 == write(fd, scratch, len) ) {
    perror("write");
    exit(8);
  }
  if (-1 == sendfile(fd, fdxml, 0, finfo.st_size) ) {
    perror("sendfile");
    exit(9);
  }

  //read headers

  memset(scratch, 0, 999);
  walk = scratch;
  httpOK=1;
  httpLen=0;
  sofar=0;

  while (1) {

    FD_ZERO (&rfds);
    FD_SET (fd, &rfds);
    tv.tv_sec = timeout;
    tv.tv_usec = 0;

    retval = select (fd + 1, &rfds, NULL, NULL, &tv);
    if (-1 == retval) {
      perror("select");
      exit(10);
    }
    if (0 == retval) {
      fprintf(stderr,"timeout (%d seconds) waiting for server header data\n", timeout);
      fprintf(stderr,"using fd %d\n",fd);
      fprintf(stderr,"read %d bytes so far: %s\n",sofar,scratch);
      exit(11);
    }

    len=read(fd, &step, 1);
    if (len != 1) {
        perror("read");
        exit(12);
    }
    if (walk == &scratch[999]) {
        fprintf(stderr,"walked past end of 999-byte scratch space\n");
        exit(13);
    }
    if (step == '\r') {
      continue;
    }
    *walk=step;
    walk++;
    sofar++;

//    fprintf(stderr,"%c", step);

    if (step == '\n') {
      if (strncmp(scratch, "HTTP/1.1 200 OK", 15) == 0) {
        httpOK=0;
      }
      if (strncmp(scratch, "Content-Length: ", 16) == 0) {
        sscanf(&scratch[16], "%d", &httpLen);
      }
      if (&scratch[1] == walk) {
        //end of headers
        break;
      }
      memset(scratch, 0, 999);
      walk = scratch;
    }
  }

  walk = malloc(httpLen+1);
  if (!walk) {
    fprintf(stderr, "error mallocing %d\n", httpLen);
    exit(14);
  }
  walk[httpLen]=0;
  sofar=0;
  while (httpLen>0) {

    tv.tv_sec = timeout;
    tv.tv_usec = 0;

    retval = select (fd + 1, &rfds, NULL, NULL, &tv);
    if (-1 == retval) {
      perror("select");
      exit(15);
    }
    if (0 == retval) {
      fprintf(stderr,"timeout (%d seconds) waiting for server data\n", timeout);
      fprintf(stderr,"using fd %d\n",fd);
      fprintf(stderr,"read %d bytes so far: %s\n",sofar,scratch);
      exit(16);
    }

    len = read(fd,&walk[sofar],httpLen);

//    fprintf(stderr, "read %d bytes, so far %d, remaining %d\n", len, sofar, httpLen);

    httpLen -= len;
    sofar += len;
  }
  printf("%s", walk);

  close(fd);
  close(fdxml);

  exit(httpOK);

}
