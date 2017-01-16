/* LTsock.c -- Lsof Test IPv4 and IPv6 Sockets
 *
 * V. Abell
 * Purdue University
 *
 * Pritam S. Gundecha (pgundech@in.ibm.com)
 * Added ipv6 support
 */


/*
 * Copyright 2002 Purdue Research Foundation, West Lafayette, Indiana
 * 47907.  All rights reserved.
 *
 * Written by V. Abell.
 *
 * This software is not subject to any license of the American Telephone
 * and Telegraph Company or the Regents of the University of California.
 *
 * Permission is granted to anyone to use this software for any purpose on
 * any computer system, and to alter it and redistribute it freely, subject
 * to the following restrictions:
 *
 * 1. Neither the authors nor Purdue University are responsible for any
 *    consequences of the use of this software.
 *
 * 2. The origin of this software must not be misrepresented, either by
 *    explicit claim or by omission.  Credit to the authors and Purdue
 *    University must appear in documentation and sources.
 *
 * 3. Altered versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 *
 * 4. This notice may not be removed or altered.
 */

#ifndef lint
static char copyright[] =
"@(#) Copyright 2002 Purdue Research Foundation.\nAll rights reserved.\n";
#endif

#include "LsofTest.h"
#include "lsof_fields.h"

#include <netdb.h>
#include <signal.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <error.h> 
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>

/*
 * Pre-definitions that make be changed or revoked by dialects
 */

#define SIGHANDLER_T	void		/* signal handler function type */
#define	SOCKLEN_T	int		/* socket length type */

#if	defined(LT_DIAL_aix)
/*
 * AIX-specific items
 */

#undef	SOCKLEN_T
#define	SOCKLEN_T	size_t
#endif	/* defined(LT_DIAL_aix) */


#if	defined(LT_DIAL_ou)
/*
 * OpenUNIX-specific items
 */

#undef	SOCKLEN_T
#define	SOCKLEN_T	size_t
#endif	/* defined(LT_DIAL_ou) */


#if	defined(LT_DIAL_uw)
/*
 * UnixWare-specific items
 */

#undef	SOCKLEN_T
#define	SOCKLEN_T	size_t
#endif	/* defined(LT_DIAL_uw) */


/*
 * Local definitions
 */

#define	ALARMTM		30		/* alarm timer */

#define	LT_CLNT		0		/* child process index */
#define	LT_SRVR		1		/* parent process index */

#define	LT_FNF		0		/* file not found */
#define LT_FBYIP	1		/* file found by IP address */
#define	LT_FBYHN	2		/* file found by host name */
#define	LT_FBYPORT	4		/* file found by port */

#if	!defined(MAXHOSTNAMELEN)
#define	MAXHOSTNAMELEN	256		/* maximum host name length */
#endif	/* !defined(MAXHOSTNAMELEN) */

#if	!defined(MAXPATHLEN)
#define	MAXPATHLEN	1024		/* maximum path length */
#endif	/* !defined(MAXPATHLEN) */


/*
 * Local structure definitions.
 */


typedef struct fdpara {		/* file descriptor parameters */
    int fd;			/* FD */
    char *fds;			/* FD in ASCII */
    int ff;			/* file found flags (see LT_F*) */
    char *host;			/* host name */
    int hlen;			/* strlen(host) */
    char *ipaddr;		/* dotted IP address */
    int ilen;			/* strlen(ipaddr) */
    pid_t pid;			/* PID of process */
    char *port;			/* port in ASCII */
    int plen;			/* strlen(port) */
    void *sa;			/* socket's address */
} fdpara_t;


/*
 * Globals
 */
int family;		 	/* IP family */	
int sizeaddr;			/* size of socket address */ 
pid_t CPid = (pid_t)0;		/* client PID */
fdpara_t FdPara[2];		/* file descriptor parameters */
#define	NFDPARA	(sizeof(FdPara) /sizeof(fdpara_t))
void  *Myad;			/* my (server) socket address */
pid_t MyPid = (pid_t)0;		/* PID of this process */
char *Pn = (char *)NULL;	/* program name */
char *PtNm[] = { "client", "server" };
				/* program type name */
char Ssock = -1;		/* server socket */
int errnum;                     /* error capture */

/*
 * Local function prototypes
 */

_PROTOTYPE(static void CleanupClnt,(void));
_PROTOTYPE(static void CleanupSrvr,(void));
_PROTOTYPE(static int ClntAlarm,(int sig));
_PROTOTYPE(static SIGHANDLER_T HandleClntAlarm,(int sig));
_PROTOTYPE(static SIGHANDLER_T HandleSrvrAlarm,(int sig));
_PROTOTYPE(static char *FindSock,(int fn));
_PROTOTYPE(static void StartClnt,(void *cad));


/*
 * Main program
 */

int
main(argc, argv)
    int argc;				/* argument count */
    char *argv[];			/* arguments */
{
    void  *aa;				/* accept address */
    void  *ba;				/* bind address */
    char buf[2048];			/* temporary buffer */
    int bufl = sizeof(buf);		/* size of buf[] */
    void *ca;				/* connect address */
    char *cem;				/* current error message pointer */
    char *ep;				/* error message parameter */
    char hnm[MAXHOSTNAMELEN + 1];	/* this host's name */
    char *host;				/* host name */
    struct addrinfo *ai;	        /* this contains the addres linked list */
    struct addrinfo hints;              /* this contains the request info */ 
    char *ipaddr;			/* IP address */
    char *pem = (char *)NULL;		/* previous error message */
    char *port;				/* port */
    SOCKLEN_T sal;			/* socket address length */
    char *tcp;				/* temporary character size */
    int ti, tj, tk;			/* temporary indexes */
    int tsfd;				/* temporary socket FD */
    int xv = 0;				/* exit value */
    char *ipaddress;			/* IP address */	

/*
 * Get program name and PID, issue start message, and build space prefix.
 */
    if ((Pn = strrchr(argv[0], '/')))
	Pn++;
    else
	Pn = argv[0];
    MyPid = getpid();
    (void) printf("%s ... ", Pn);
    (void) fflush(stdout);
    PrtMsg((char *)NULL, Pn);

/*
 * Process arguments.
 */
    if (ScanArg(argc, argv, "h", Pn))
	xv = 1;
    if (xv || LTopt_h) {
	(void) PrtMsg("usage: [-h]", Pn);
	PrtMsgX("       -h       print help (this panel)", Pn, CleanupSrvr,
		xv);
    }

/*
 * See if lsof can be executed and can access kernel memory.
 */
    if ((cem = IsLsofExec()))
	(void) PrtMsgX(cem, Pn, CleanupSrvr, 1);
    if ((cem = CanRdKmem()))
	(void) PrtMsgX(cem, Pn, CleanupSrvr, 1);

/*
 * Get the host name and its IP address.  Convert the IP address to dotted
 * ASCII form.
 */
    if (gethostname(hnm, sizeof(hnm) - 1)) {
	cem = "ERROR!!!  can't get this host's name";
	goto print_errno;
    }
    hnm[sizeof(hnm) - 1] = '\0';
    memset (&hints, 0, sizeof (hints));
    hints.ai_flags=AI_PASSIVE | AI_ADDRCONFIG;
    hints.ai_family=AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM; 
    if (errnum = getaddrinfo(hnm, NULL, &hints, &ai)) { 
	(void) snprintf(buf, bufl - 1, "ERROR!!!  can't get IP address for %s",
	    hnm);
	buf[bufl - 1] = '\0';
	cem = buf;
	goto print_errno;
    }

    while(ai != NULL) {	 
    family = ai->ai_family;   
    switch(ai->ai_family) {
	case AF_INET6:	sizeaddr = sizeof(struct sockaddr_in6); 
			Myad=malloc(sizeaddr);	
    			(void) memset(Myad, 0, sizeaddr);
    			if ((ti = ai->ai_addrlen) > sizeof(((struct sockaddr_in6 *)Myad)->sin6_addr))
			ti = sizeof(((struct sockaddr_in6 *)Myad)->sin6_addr);
    			(void) memcpy((void *)(&(((struct sockaddr_in6*)Myad)->sin6_addr)), 
					(void *)(&((struct sockaddr_in6*)(ai->ai_addr))->sin6_addr), ti);
    			((struct sockaddr_in6 *) Myad)->sin6_family = AF_INET6;
 			ipaddress = (char *)malloc(INET6_ADDRSTRLEN);
 			inet_ntop(((struct sockaddr_in6 *)Myad)->sin6_family,
			           &(((struct sockaddr_in6 *)Myad)->sin6_addr),
                                         ipaddress,INET6_ADDRSTRLEN);
			printf("\nFor IPv6 address %s",ipaddress);
			break;	

	case AF_INET:	sizeaddr=sizeof(struct sockaddr_in);
			Myad=malloc(sizeaddr);	
    			(void) memset(Myad, 0, sizeaddr);
    			if ((ti = ai->ai_addrlen) > sizeof(((struct sockaddr_in *)Myad)->sin_addr))
			ti = sizeof(((struct sockaddr_in *)Myad)->sin_addr);
    			(void) memcpy((void *)(&(((struct sockaddr_in *)Myad)->sin_addr)), 
					(void *)(&((struct sockaddr_in*)(ai->ai_addr))->sin_addr), ti);
    			((struct sockaddr_in *)Myad)->sin_family = AF_INET;
			ipaddress = (char *)malloc(INET_ADDRSTRLEN);
                        inet_ntop(((struct sockaddr_in *)Myad)->sin_family,
                                   &(((struct sockaddr_in *)Myad)->sin_addr),
                                         ipaddress,INET_ADDRSTRLEN);	
		 	printf("\nFor IPv4 address %s",ipaddress);	
			break;	
    }
    
/*
 * Initalize the FdPara[] array before any CleanupClnt() call.
 */
    for (ti = 0; ti < NFDPARA; ti++) {
        (void) memset((void *)&FdPara[ti], 0, sizeof(fdpara_t));
        FdPara[ti].fd = -1;
        FdPara[ti].ff = LT_FNF;
	FdPara[ti].sa = malloc(sizeaddr);
   }

/*
 * Get INET domain socket FDs.
 */
    for (ti = 0; ti < NFDPARA; ti++) {
	if ((tsfd = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol)) < 0) {
	    ep = "socket";

print_errno_by_ti:

	/*
	 * Report socket function error.
	 *
	 * Entry: ep   = function name
	 *	  hnm  = this host's name
	 *	  Myad = this host's IP address
	 *	  ti   =  FdPara[] index
	 */
	    (void) snprintf(buf, bufl - 1, "ERROR!!!  %s %s() failure",
		PtNm[ti], ep);
	    buf[bufl - 1] = '\0';
	    PrtMsg(buf, Pn);
	    (void) snprintf(buf, bufl - 1, "    host: %s",
		FdPara[ti].host ? FdPara[ti].host : hnm);
	    buf[bufl - 1] = '\0';
	    PrtMsg(buf, Pn);
	    if(!FdPara[ti].ipaddr) 
		FdPara[ti].ipaddr = ipaddress;
  	    (void) snprintf(buf, bufl - 1, "    IP: %s",FdPara[ti].ipaddr);
	    
            buf[bufl - 1] = '\0';
	    cem = buf;

print_errno:

	/*
	 * Report errno.
	 *
	 * Entry: errno = error number
	 */
	    PrtMsg(cem, Pn);
	    (void) snprintf(buf, bufl - 1, "    Errno %d: %s", errno,
		strerror(errno));
	    buf[bufl - 1] = '\0';
	    PrtMsgX(buf, Pn, CleanupSrvr, 1);
	}
    /*
     * Put the FD just acquired in FdPara[ti].fd.
     *
     * Set the file-not-found to LT_FNF.
     *
     * Save the server socket if this FdPara[] is for it.
     */
	FdPara[ti].fd = tsfd;
	(void) snprintf(buf, bufl - 1, "%d", tsfd);
	buf[bufl - 1] = '\0';
	FdPara[ti].fds = MkStrCpy(buf, &tj);
	if (ti == LT_SRVR)
	    Ssock = tsfd;
    }
/*
 * Bind the host name to the server socket.
 *
 * Get and save the server's socket address.
 *
 * Initiate a listen with an address list of one.
 */
    ba = malloc(sizeaddr);	
    memset (ba, 0, sizeaddr);
    (void) memcpy((void *)ba, (void *)Myad, sizeaddr);
    ti = LT_SRVR;
    FdPara[ti].pid = MyPid;
    if ((errnum=bind(Ssock, (struct sockaddr *)ba, sizeaddr)) < 0) {	
	ep = "bind";
	goto print_errno_by_ti;
    }
    ca = malloc(sizeaddr);	
    sal = (SOCKLEN_T)sizeaddr;
    if (getsockname(Ssock, (struct sockaddr *)ca, &sal)) {
	ep = "getsockname";
	goto print_errno_by_ti;
    }

    (void) memcpy((void *)FdPara[ti].sa, (void *)ca, sizeaddr);
    if (listen(Ssock, 1) < 0) {
	ep = "listen";
	goto print_errno_by_ti;
    }
/*
 * Fork a child process to run as the client.
 */
    switch ((CPid = (pid_t)fork())) {
    case (pid_t)0:

    /*
     * This is the child.  Start the client.
     */
	StartClnt(ca);
	(void) PrtMsgX("ERROR!!!  unexpected client return", Pn, CleanupSrvr,
		       1);
    case (pid_t)-1:

    /*
     * This is a fork error.
     */
	cem = "ERROR!!! fork() error";
	goto print_errno;
    default:

    /*
     * This is the parent.
     *
     * Save the client's PID.
     *
     * Close the client's socket.
     */
	FdPara[LT_CLNT].pid = CPid;
	if (FdPara[LT_CLNT].fd >= 0) {
	    (void) close(FdPara[LT_CLNT].fd);
	    FdPara[LT_CLNT].fd = -1;
	}
    }
/*
 * Set a SIGALRM, then accept() the connection from the client.
 *
 * Save the client'ss socket address.
 *
 * Replace the server's FD with the accepted one and close the original.
 */
    aa = malloc(sizeaddr);
    sal = (SOCKLEN_T)sizeaddr;
    (void) alarm(0);
    (void) signal(SIGALRM, HandleSrvrAlarm);
    (void) alarm(ALARMTM);
    tsfd = FdPara[LT_SRVR].fd = accept(Ssock, (struct sockaddr *)aa, &sal);
    (void) alarm(0);
    (void) signal(SIGALRM, SIG_DFL);
    if (tsfd < 0) {
	ep = "accept";
	goto print_errno_by_ti;
    }
    (void) snprintf(buf, bufl - 1, "%d", tsfd);
    buf[bufl - 1] = '\0';
    if (FdPara[LT_SRVR].fds)
	(void) free((void *)FdPara[LT_SRVR].fds);
    FdPara[LT_SRVR].fds = MkStrCpy(buf, &tj);
    ti = LT_CLNT;
    (void) memcpy(FdPara[ti].sa, aa, sizeaddr);
    (void) close(Ssock);
    Ssock = -1;
/*
 * Convert the client and server IP address to ASCII form.
 *
 * Look up the client and server host names for their IP addresses.
 *
 * Convert the port from the socket address to host form.
 */
    for (ti = 0; ti < NFDPARA; ti++) {
	switch(family) {
		case AF_INET6:  (void) snprintf(buf, bufl - 1, "%d",
            				(int)ntohs((((struct sockaddr_in6 *)FdPara[ti].sa)->sin6_port)));
				break;
		case AF_INET:   (void) snprintf(buf, bufl - 1, "%d",
                        		(int)ntohs((((struct sockaddr_in *)FdPara[ti].sa)->sin_port)));
				break;

                buf[bufl - 1] = '\0';
	}
 	FdPara[ti].ipaddr = MkStrCpy(ipaddress, &FdPara[ti].ilen);
        FdPara[ti].port = MkStrCpy(buf, &FdPara[ti].plen);
	if (getnameinfo((struct sockaddr *)FdPara[ti].sa,
                                 sizeaddr,
                                 buf, sizeof (buf), NULL, 0, 0)!=0) {
            	ep = "getnameinfo";
            	goto print_errno_by_ti;
        }
        if (buf)
            FdPara[ti].host = MkStrCpy(buf, &FdPara[ti].hlen);
        else {

	/*
	 * The connected client's socket address can't be mapped to a host
	 * name.
	 */

	    (void) snprintf(buf, bufl - 1,
		"ERROR!!!  can't map %s (client) to a host name",
		FdPara[ti].ipaddr);
	    buf[bufl - 1] = '\0';
	    PrtMsgX(buf, Pn, CleanupSrvr, 1);
	}
    }
/*
 * Call lsof three times to find the two sockets: 1) by host name and port;
 * 2)  by IP addressand port ; and 3) by port.
 */
    if ((cem = FindSock(LT_FBYHN)))
	PrtMsgX(cem, Pn, CleanupSrvr, 1);
    if ((cem = FindSock(LT_FBYIP)))
	PrtMsgX(cem, Pn, CleanupSrvr, 1);
    if ((cem = FindSock(LT_FBYPORT)))
	PrtMsgX(cem, Pn, CleanupSrvr, 1);
/*
 * Check the FindSock() results.
 */
    for (pem = (char *)NULL, ti = 0; ti < NFDPARA; ti++) {
	if ((tj = FdPara[ti].ff) != (LT_FBYHN | LT_FBYIP | LT_FBYPORT)) {
	    host = FdPara[ti].host;
	    ipaddr = FdPara[ti].ipaddr;
	    port = FdPara[ti].port;

	/*
	 * This FD wasn't found by some search method.
	 */
	    if (!(tj & LT_FBYHN)) {

	    /*
	     * The search by host name and port failed.
	     */
		(void) snprintf(buf, bufl - 1,
		    "ERROR!!!  no %s socket by host and port: %s@%s",
		    PtNm[ti], host, port);
		buf[bufl - 1] = '\0';
		if (pem)
		    (void) PrtMsg(pem, Pn);
		pem = MkStrCpy(buf, &tk);
	    }
	    if (!(tj & LT_FBYIP)) {

	    /*
	     * The search by IP address and port failed.
	     */
		(void) snprintf(buf, bufl - 1,
		    "ERROR!!!  no %s socket by IP and port: %s@%s",
		    PtNm[ti], ipaddr, port);
		buf[bufl - 1] = '\0';
		if (pem)
		    (void) PrtMsg(pem, Pn);
		pem = MkStrCpy(buf, &tk);
	    }
	    if (!(tj & LT_FBYPORT)) {

	    /*
	     * The search by port number failed.
	     */
		(void) snprintf(buf, bufl - 1,
		    "ERROR!!!  no %s socket by port: %s",
		    PtNm[ti], port);
		buf[bufl - 1] = '\0';
		if (pem)
		    (void) PrtMsg(pem, Pn);
		pem = MkStrCpy(buf, &tk);
	    }
	}
    }
    if (pem)
	(void) PrtMsgX(pem, Pn, CleanupSrvr, 1);
/*
 * Exit successfully.
 */
    printf("\t success ");
    ai = ai->ai_next;

    free(Myad);
    free(aa);
    free(ba);
    free(ca);
    free(ipaddress);	
    for (ti = 0; ti < NFDPARA; ti++)
	free(FdPara[ti].sa); 	
 }
    (void) PrtMsgX("\nOK", Pn, CleanupSrvr, 0);	 
}


/*
 * ClntCleanup() -- release client resources
 */

static void
CleanupClnt()
{
    int tfd;				/* temporary file descriptor */

    if ((tfd = FdPara[LT_CLNT].fd) >= 0) {
	(void) shutdown(tfd, 2);
	(void) close(tfd);
	FdPara[LT_CLNT].fd = -1;
    }
}


/*
 * CleanupSrvr() -- release server resources
 */

static void
CleanupSrvr()
{
    int tfd;				/* temporary file descriptor */
    int ti;				/* temporary index */
    pid_t wpid;				/* wait() PID */

    if ((Ssock >= 0) && (Ssock != FdPara[LT_SRVR].fd)) {
	(void) shutdown(Ssock, 2);
	(void) close(Ssock);
	Ssock = -1;
    }
    for (ti = 0; ti < NFDPARA; ti++) {
	if ((tfd = FdPara[ti].fd) >= 0) {
	    (void) shutdown(tfd, 2);
	    (void) close(tfd);
	    FdPara[ti].fd = -1;
	}
    }
    if (CPid > 0) {
	wpid = wait3(NULL, WNOHANG, NULL);
	if (wpid != CPid) {
	    kill(CPid, SIGKILL);
	    (void) wait3(NULL, WNOHANG, NULL);
	}
	CPid = (pid_t)0;
    }
}


/*
 * FindSock() -- find sockets with lsof
 */

static char *
FindSock(fn)
    int fn;				/* function -- an LT_FBY* value */
{
    char buf[2048];			/* temporary buffer */
    int bufl = sizeof(buf);		/* size of buf[] */
    char *cem;				/* current error message pointer */
    LTfldo_t *cmdp;			/* command pointer */
    LTfldo_t *devp;			/* device pointer */
    LTfldo_t *fop;			/* field output pointer */
    LTdev_t lsofdc;			/* lsof device components */
    int nf;				/* number of fields */
    int nl;				/* name length */
    LTfldo_t *nmp;			/* name pointer */
    char *opv[5];			/* option vector for ExecLsof() */
    char *pem = (char *)NULL;		/* previous error message pointer */
    pid_t pid;				/* PID */
    int pids = 0;			/* PID found status */
    int pl;				/* port length */
    int px;				/* process index -- LT_CLNT or
					 * LT_SRVR */
    char *tcp, *tcp1;			/* temporary character pointers */
    int ti, tj;				/* temporary integers */
    LTfldo_t *typ;			/* file type pointer */
/*
 * Check the function and determine the first lsof option from it.
 */
    ti = 0;
    switch (fn) {
    case LT_FBYHN:
	opv[ti++] = "-P";
	for (tj = 0; tj < NFDPARA; tj++) {
	    if(family== AF_INET6)
		(void) snprintf(buf, bufl - 1, "-i6@%s:%s", FdPara[tj].host, FdPara[tj].port);
	    else
		(void) snprintf(buf, bufl - 1, "-i@%s:%s", FdPara[tj].host, FdPara[tj].port); 
	    buf[bufl - 1] = '\0';
	    opv[ti++] = MkStrCpy(buf, &pl);
	}
	break;
    case LT_FBYIP:
	opv[ti++] = "-Pn";
	for (tj = 0; tj < NFDPARA; tj++) {
 	    if(family== AF_INET6)
	    	(void) snprintf(buf, bufl - 1, "-i6@[%s]:%s", FdPara[tj].ipaddr, FdPara[tj].port);
	    else
		(void) snprintf(buf, bufl - 1, "-i@%s:%s", FdPara[tj].ipaddr, FdPara[tj].port);
	    buf[bufl - 1] = '\0';
	    opv[ti++] = MkStrCpy(buf, &pl);
	}
	break;
    case LT_FBYPORT:
	opv[ti++] = "-P";
	for (tj = 0; tj < NFDPARA; tj++) {
	    if(family== AF_INET6)	
	    	(void) snprintf(buf, bufl - 1, "-i6:%s", FdPara[tj].port);
	    else
		(void) snprintf(buf, bufl - 1, "-i:%s", FdPara[tj].port);
	    buf[bufl - 1] = '\0';
	    opv[ti++] = MkStrCpy(buf, &pl);
	}
	break;
    default:
	(void) snprintf(buf, bufl - 1,
	    "ERROR!!!  illegal FindSock() function: %d", fn);
	buf[bufl - 1] = '\0';
	return(MkStrCpy(buf, &ti));
    }
/*
 * Complete the option vector and start lsof execution.
 */

#if	defined(USE_LSOF_C_OPT)
    opv[ti++] = "-C";
#endif	/* defined(USE_LSOF_C_OPT) */

    opv[ti] = (char *)NULL;
    if ((cem = ExecLsof(opv)))
	return(cem);
/*
 * Read lsof output.
 */
    while ((((FdPara[LT_CLNT].ff & fn) == 0)
    ||	    ((FdPara[LT_SRVR].ff & fn) == 0))
    &&	   (fop = RdFrLsof(&nf, &cem))
    ) {
	if (cem) {
	    if (pem)
		(void) PrtMsg(pem, Pn);
	    return(cem);
	}
	switch (fop->ft) {
	case LSOF_FID_PID:

	/*
	 * This is a process information line.
	 */
	    pid = (pid_t)atoi(fop->v);
	    pids = 1;
	    cmdp = (LTfldo_t *)NULL;
	    for (fop++, ti = 1; ti < nf; fop++, ti++) {
		switch (fop->ft) {
		case LSOF_FID_CMD:
		    cmdp = fop;
		    break;
		}
	    }
	    if (!cmdp || ((pid != CPid) && (pid != MyPid)))
		pids = 0;
	    break;
	case LSOF_FID_FD:

	/*
	 * This is a file descriptor line.
	 *
	 * Identify the process -- client or server.
	 */
	    if (!pids)
		break;
	    if (pid == CPid)
		px = LT_CLNT;
	    else if (pid == MyPid)
		px = LT_SRVR;
	    else
		break;
	/*
	 * Make sure the FD matches the identified process.
	 */
	    if (strcmp(fop->v, FdPara[px].fds))
		break;
	/*
	 * Scan for name and type.
	 */
	    nmp = typ  = (LTfldo_t *)NULL;
	    for (fop++, ti = 1; ti < nf; fop++, ti++) {
		switch (fop->ft) {
		case LSOF_FID_NAME:
		    nmp = fop;
		    break;
		case LSOF_FID_TYPE:
		    typ = fop;
		    break;
		}
	    }
	/*
	 * Check the type of the file.
	 */
	    if (!typ
	    ||  (strcasecmp(typ->v, "inet") && strcasecmp(typ->v, "ipv4") && strcasecmp(typ->v, "ipv6"))) 
		break;
	/*
	 * Check the addess in the name, based on the calling function.
	 */
	    if (!nmp)
		break;
	    tcp = nmp->v;
	    switch (fn) {
	    case LT_FBYHN:
		if (((nl = FdPara[px].hlen) <= 0)
		||  !(tcp1 = FdPara[px].host)
		||  strncasecmp(tcp, tcp1, nl)
		) {
		    break;
		}
		tcp += nl;
		if ((*tcp++ != ':')
		||  !(tcp1 = FdPara[px].port)
		||  ((pl = FdPara[px].plen) <= 0)
		||  strncmp(tcp, tcp1, pl)
		) {
		    break;
		}
		tcp += pl;
		if ((*tcp == '-') || (*tcp == ' ') || !*tcp) {
		    FdPara[px].ff |= LT_FBYHN;
		}
		break;
	    case LT_FBYIP:
		if(family == AF_INET6)
			tcp++;
		if (((nl = FdPara[px].ilen) <= 0)
		||  !(tcp1 = FdPara[px].ipaddr)
		||  strncasecmp(tcp, tcp1, nl)
		) {
		    break;
		}
		tcp += nl;
		if(family == AF_INET6)
			tcp++;
		if ((*tcp++ != ':')
		||  !(tcp1 = FdPara[px].port)
		||  ((pl = FdPara[px].plen) <= 0)
		||  strncmp(tcp, tcp1, pl)
		) {
		    break;
		}
		tcp += pl;
		if ((*tcp == '-') || (*tcp == ' ') || !*tcp) {
		    FdPara[px].ff |= LT_FBYIP;
		}
		break;
	    case LT_FBYPORT:
		if (!(tcp = strchr(tcp, ':')))
		    break;
		tcp++;
		if (!(tcp1 = FdPara[px].port)
		||  ((pl = FdPara[px].plen) <= 0)
		||  strncmp(tcp, tcp1, pl)
		) {
		    break;
		}
		tcp += pl;
		if ((*tcp == '-') || (*tcp == ' ') || !*tcp) {
		    FdPara[px].ff |= LT_FBYPORT;
		}
		break;
	    }
	}
    }
/*
 * Clean up and return.
 */
    (void) StopLsof();
    return(pem);
}


/*
 * HandleClntAlarm() -- handle client alarm
 */

static SIGHANDLER_T
HandleClntAlarm(sig)
    int sig;				/* the signal (SIGALRM) */
{
    (void) PrtMsgX("ERROR!!!  client caught an alarm signal", Pn,
	CleanupClnt, 1);
}


/*
 * Handle SrvrAlarm() -- handle server alarm
 */

static SIGHANDLER_T
HandleSrvrAlarm(sig)
    int sig;				/* the signal (SIGALRM) */
{
    (void) PrtMsgX("ERROR!!!  server caught an alarm signal.", Pn,
	CleanupSrvr, 1);
}


/*
 * StartClnt() -- start network client
 */

static void
StartClnt(cad)
    void *cad;				/* connection address */
{
    void *ba;				/* bind address */
    int br;				/* bytes read */
    char buf[2048];			/* temporary buffer */
    int bufl = sizeof(buf);		/* size of buf[] */
    int cr;				/* connect() reply */
    char *em;				/* error message pointer */
    int fd = FdPara[LT_CLNT].fd;	/* client's socket FD */
    int xv = 0;				/* exit value */
/*
 * Close the server's sockets.
 */
    if ((Ssock >= 0) && (Ssock != FdPara[LT_SRVR].fd)) {
	(void) close(Ssock);
	Ssock = -1;
    }
    if (FdPara[LT_SRVR].fd >= 0) {
	(void) close(FdPara[LT_SRVR].fd);
	FdPara[LT_SRVR].fd = -1;
    }
/*
 * Bind to the local address.
 */
    ba=malloc(sizeaddr);
    (void) memcpy((void *)ba, (void *)Myad, sizeaddr);
    if (bind(fd, (struct sockaddr *)ba, sizeaddr) < 0) {
	em = "bind";

client_errno:

	(void) snprintf(buf, bufl - 1,
	    "ERROR!!!  client %s error: %s", em, strerror(errno));
	buf[bufl - 1] = '\0';
	(void) PrtMsgX(em, Pn, CleanupClnt, 1);
    }
/*
 * Set an alarm timeout and connect to the server.
 */
    (void) signal(SIGALRM, HandleSrvrAlarm);
    (void) alarm(ALARMTM);
    cr = connect(fd, (struct sockaddr *)cad, sizeaddr);
    (void) alarm(0);
    (void) signal(SIGALRM, SIG_DFL);
    if (cr) {
	em = "connect";
	goto client_errno;
    }
/*
 * Sleep until the socket closes or the parent kills the process.
 */
    for (br = 0; br >= 0;) {
	sleep(1);
	br = read(fd, buf, bufl);
    }
    xv = 0;
    (void) CleanupClnt();
    free(ba);
    exit(0);
}
