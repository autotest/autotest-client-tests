/***************************************************************************/
/*									   */
/* This program is free software; you can redistribute it and/or    	   */
/* modify it under the terms of the GNU General Public License		   */
/* as published by the Free Software Foundation; either version 2	   */
/* of the License, or (at your option) any later version.		   */
/*		   							   */
/* This program is distributed in the hope that it will be useful,	   */
/* but WITHOUT ANY WARRANTY; without even the implied warranty of	   */
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the	   */
/* GNU General Public License for more details. 			   */
/*							   		   */
/***************************************************************************/

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

#include "ftplib.h" /* ftplib rpm need to be installed */

#define nMaxPar 6

static char cmdbuf[512], tmpbuf[2048];
static char * par[nMaxPar];
static char mode = 'I';
static int logged_in = 0;
static netbuf *conn = NULL;
static int hfifo1, hfifo2;

static int writef(char * buf)
{
	int n,len;
	
	len=strlen(buf);
	n=write(hfifo2, buf, len+1);
	if (n==-1)
	    fprintf(stderr, "Named pipe write error! \n");
	return n;
}

static int parsecmd(char * buf, int len, char** par)
{
	char * ptr;
	int i, n = 0; 
	
	ptr = buf;
	for (i=0; i<nMaxPar ;i++)
	    par[i]=NULL;
	    
	while((*ptr == ' ' || *ptr == '\0') && (ptr < buf+len)) ptr++;
	while (ptr < buf+len)
	{
		par[n++] = ptr;

		while(*ptr != ' ' && *ptr !='\0') 
		{
			if(*ptr=='\"')
			{
				while (*(++ptr)!='\"' && ptr<buf+len) ;
				if (ptr >= buf+len) break;
			} 
			if (*ptr=='\n')
				*ptr='\0' ; 
			ptr++;
		 }
		while((*ptr == ' ') && (ptr < buf+len)) {*ptr='\0'; ptr++;}
		
		if (*ptr == '\0')
		    break;
	}
	
    return n;	
}


// par: hostname
static int do_connect(char **par , int npar)
{
    if (conn)
	{
		writef("Ok:FtpConnect already."); 
		return 0;	
	}
	
	if (npar<2)
	{
		writef("Error:parameter.");
		return -1;
	}
	
	if (!FtpConnect(par[1],&conn))
	{
		writef("Error:FtpConnect.");
		return -1;
	}else
	    writef("Ok:FtpConnect."); 	
	return 0;
}

// par: user password
static int do_login(char **par , int npar)
{
	if (logged_in)
	{
		writef("Ok:Ftplogin already.");
		return 0;
	}

    if (!conn)
	{
		writef("Error:FtpConnect needed."); 
		return -1;	
	}	


	if (npar<3)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	if (!FtpLogin(par[1],par[2],conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpLogin", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else
		writef("Ok:Ftplogin.");
	
	logged_in++;
	return 0;	
}


// par: dir
static int do_chdir(char **par , int npar)
{
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (npar<2)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	if (!FtpChdir(par[1], conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpChdir", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else
		writef("Ok:FtpChdir.");
	
	return 0;	
}

// par: dir
static int do_rmdir(char **par , int npar)
{
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (npar<2)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	if (!FtpRmdir(par[1], conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpRmdir", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else
		writef("Ok:FtpRmdir.");
	
	return 0;	
}

// par: dir
static int do_nlist(char **par , int npar)
{
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (npar<2)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	if (!FtpNlst(NULL, par[1], conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpNlst", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else
		writef("Ok:FtpNlst.");
	
	return 0;	
}

// par: dir
static int do_ftpdir(char **par , int npar)
{
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (npar<2)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	if (!FtpDir(NULL, par[1], conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpDir", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else
		writef("Ok:FtpDir.");
	
	return 0;	
}

//par: localfile ftpfile  
static int do_put(char **par , int npar)
{
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (npar<3)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	if (!FtpPut(par[1], par[2], mode, conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpPut", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else
		writef("Ok:FtpPut.");
	
	return 0;	
}

//par: i|a 
static int do_mode(char **par , int npar)
{
	if (npar<2)
	{
		writef("Error:parameter.");
		return -1;
	}

	if (par[1][0]=='a')
		mode='A';
	else if (par[1][0]=='i')
		mode='I';
	else {
		writef("Error:parameter.");
		return -1;
	}			
	
	writef("Ok:mode.");
	
	return 0;	
}


//par: localfile ftpfile   
static int do_get(char **par , int npar)
{
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (npar<2)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	//if (!FtpGet(par[1], par[2], FTPLIB_WRITE_TYPE_OVERWRITE, mode, conn))
	if (!FtpGet(par[1], par[2],  mode, conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpGet", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else
		writef("Ok:FtpGet.");
	
	return 0;	
}

//par: file  
static int do_delete(char **par , int npar)
{
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (npar<2)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	if (!FtpDelete(par[1], conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpDelete", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else
		writef("Ok:FtpDelete.");

	return 0;	
}

//par: file  
static int do_size(char **par , int npar)
{
	int sz;
	
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (npar<2)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	if (!FtpSize(par[1], &sz, mode, conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpSize", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else {
		sprintf(tmpbuf,"%s\n%d - %s", "Ok:FtpSize", sz, FtpLastResponse(conn));
		writef(tmpbuf);
	}

	return 0;	
}

//par: 
static int do_quit(char **par , int npar)
{
    if (!conn)
	{
		writef("Error:FtpConnect needed."); 
		return -1;	
	}	

	FtpQuit(conn);
	writef("Ok:FtpQuit.");
		
	logged_in--;
	conn=NULL;	
	
	return 0;	
}

//par: file  
static int do_moddate(char **par , int npar)
{
	char buf[96];
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (npar<2)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	if (!FtpModDate(par[1], buf, 96, conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpModDate.", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else {	
		sprintf(tmpbuf,"%s\n%s", "Ok:FtpModDate.", buf);
		writef(tmpbuf);
	}
	return 0;	
}



//par:  
static int do_systype(char **par , int npar)
{
	char buf[96];
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

		
	if (!FtpSysType(buf, 96, conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpSysType.", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else {	
		sprintf(tmpbuf,"%s\n%s", "Ok:FtpSysType.", buf);
		writef(tmpbuf);
	}
	return 0;	
}


//par: cmd
static int do_site(char **par , int npar)
{
	// char buf[96];
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (npar<2)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	if (!FtpSite(par[1], conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpSite", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else {
		sprintf(tmpbuf,"%s\n%s", "Ok:FtpSite.", FtpLastResponse(conn));
		writef(tmpbuf);
	}
	return 0;	
}

//par: dir
static int do_mkdir(char **par , int npar)
{
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (npar<2)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	if (!FtpMkdir(par[1], conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpMkdir", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else {
		sprintf(tmpbuf,"%s\n%s", "Ok:FtpMkdir", FtpLastResponse(conn));
		writef(tmpbuf);
	}
	
	return 0;		
	
}


//par: 
static int do_cdup(char **par, int npar)
{
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (!FtpCDUp(conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpCDUp.", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else {
		sprintf(tmpbuf,"%s\n%s", "Ok:FtpCDUp.", FtpLastResponse(conn));
		writef(tmpbuf);
	}
	return 0;		
}

//par: 
static int do_pwd(char **par , int npar)
{
	char buf[512];
	
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (!FtpPwd(buf, 512, conn))
	{
		sprintf(tmpbuf,"%s", "Error:FtpPwd");
		writef(tmpbuf);
		return -1;
	} else
	{
		sprintf(tmpbuf,"%s\n%s", "Ok:FtpPwd", FtpLastResponse(conn));
		writef(tmpbuf);
	}
	return 0;		
	
}

//par: src dst
static int do_rename(char **par , int npar)
{
    if (!logged_in)
	{
		writef("Error:FtpLogin needed."); 
		return -1;	
	}	

	if (npar<3)
	{
		writef("Error:parameter.");
		return -1;
	}
		
	if (!FtpRename(par[1], par[2], conn))
	{
		sprintf(tmpbuf,"%s\n%s", "Error:FtpRename", FtpLastResponse(conn));
		writef(tmpbuf);
		return -1;
	} else {
		sprintf(tmpbuf,"%s\n%s", "Ok:FtpRename", FtpLastResponse(conn));
		writef(tmpbuf);
	}
	
	return 0;		
}

static int do_action(char **par, int npar)
{
	
	sprintf(tmpbuf, "%s:%s", "ok" ,par[0]);
	writef(tmpbuf);
	return 0;
}


//return : 0->sucess
static int handlecmd(char **par , int npar)
{
	
	if (strstr(par[0],"host") != NULL)
		return do_connect(par,npar);

	else if (strstr(par[0],"user") != NULL)
		return do_login(par,npar);

	else if (strstr(par[0],"chdir") != NULL)
		return do_chdir(par,npar);
		
	else if (strstr(par[0],"rmdir") != NULL)
		return do_rmdir(par,npar);

	else if (strstr(par[0],"nlist") != NULL)
		return do_nlist(par,npar);

	else if (strstr(par[0],"ftpdir") != NULL)
		return do_ftpdir(par,npar);
    
	else if (strstr(par[0],"size") != NULL) 
		return do_size(par,npar);

	else if (strstr(par[0],"mode") != NULL)
  		return do_mode(par,npar); 
	
	else if (strstr(par[0],"get") != NULL)
	    return do_get(par,npar);

	else if (strstr(par[0],"put") != NULL)
		return do_put(par,npar);    
	    
	else if (strstr(par[0],"delete") != NULL)
		return do_delete(par,npar); 

	else if (strstr(par[0],"quit") != NULL) 
		return do_quit(par,npar); 
 
	else if (strstr(par[0],"moddate") != NULL)
  		return do_moddate(par,npar); 
	    
	else if (strstr(par[0],"systype") != NULL)
	    return do_systype(par,npar); 
	    
	else if (strstr(par[0],"site") != NULL)
		 return do_site(par,npar); 
		     
	else if (strstr(par[0],"mkdir") != NULL)
	    return do_mkdir(par,npar); 
	    
	else if (strstr(par[0],"cdup") != NULL)
		return do_cdup(par,npar);

	else if (strstr(par[0],"pwd") != NULL)
	    return do_pwd(par,npar);
	    
	else if (strstr(par[0],"rename") != NULL)
	    return do_rename(par,npar);

	fprintf(stderr, "Unknown operation: %s. \n", par[0]);
    return do_action(par, npar);
}



int main(int argc, char *argv[])
{
	
	int i;
	ssize_t n;

	if (argv[1] == NULL || argv[2] == NULL )
	{
		fprintf(stderr, "You must specify a pair of named pipes, one for read one for write.\n");
		return -1;
	}
	
	hfifo1 = open(argv[1], O_RDWR);
	if (hfifo1 == -1)
	{
		fprintf(stderr, "Fifo file to read open error.\n");
		return -1;
	}

	hfifo2 = open(argv[2], O_RDWR);
	if (hfifo2 == -1)
	{
		fprintf(stderr, "Fifo file to write open error.\n");
		return -1;
	}	

	FtpInit();
	
	while (1)
	{
		memset(cmdbuf, 0, 512);
		n = read(hfifo1, cmdbuf, 512);
		if (n == -1)
		    fprintf(stderr, "Fifo file read error.\n");
		n = parsecmd(cmdbuf, 512, par);

		for (i=0; i<n; i++)
		    printf("  par[%d]=%s\n", i, par[i] );
		
		if (strstr(cmdbuf,"testover") != NULL) 
		    break;
		
		handlecmd(par, n);
	}

	if (conn)
		FtpClose(conn);	

	close(hfifo1);
	close(hfifo2);
	return 0;
}
