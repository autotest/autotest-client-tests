#include <stdio.h>
#include <stdlib.h>
#include <strings.h>

#include <libmng.h>
#ifndef _MAX_PATH
#define _MAX_PATH 280
#endif//_MAX_PATH
#ifndef _DEBUG
#define _DEBUG 0
#endif//_DEBUG

typedef struct user_struct userdata;
typedef userdata*          userdatap;

// callback functions used in libmng stuff
extern userdatap allocuser(char *sFilename, char *sFilemode);
extern void      freeuser(userdatap pMydata);
extern mng_ptr   myalloc(mng_size_t iSize);
extern void      myfree(mng_ptr pPtr, mng_size_t iSize);
extern mng_bool  myopenstream(mng_handle hMNG);
extern mng_bool  myclosestream(mng_handle hMNG);
extern mng_bool  myreaddata(mng_handle hMNG, mng_ptr pBuf, mng_uint32 iSize, mng_uint32 *iRead);
extern mng_bool  mywritedata(mng_handle hMNG, mng_ptr pBuf, mng_uint32 iSize, mng_uint32 *iWrite);
extern mng_bool  myiterchunk(mng_handle hMNG, mng_handle hChunk, mng_chunkid iChunktype, mng_uint32 iChunkseq);
// callback functions used in libmng over

//the command and it's argument
char sCommand [_MAX_PATH], sFilename[_MAX_PATH] = "create.mng";

int  tc_usage()
{
	printf("usage:\
		mngtest [--help] filename\n\
		mngtest [ read | create [ filename ] ]\n\
		    read,   read method\n\
		    create, create and write method\n\
		        filename, the file to read or create, default is linux.mng\n\
		    --help, print usage message\n");
	return -1;
}

//error message string
char strErrMsg[][_MAX_PATH] =
{	//initialize error   00--09
	"success!",                           //0
	"cannot initialize libmng",           //1
	"cannot set callback openstream",     //2
	"cannot set callback closestream",    //3
	"cannot set callback readdata",       //4
	"cannot set callback writedata",      //5
	"", "", "", "",                       //6-9, not in use
	//create&write error 10--19
	"cannot create a new mng",            //10
	"cannot putchunk mhdr",               //11
	"cannot putchunk basi",               //12
	"cannot putchunk iend",               //13
	"cannot putchunk mend",               //14
	"cannot putchunk defi",               //15
	"cannot write",                       //16
	"", "", "",                           //17-19, not in use
	//read&iterate chunks error
	"cannot read data",                   //20
	"cannot iterate chunks"               //21
};

//initialize mng and set callback functions
int  tc_open(char *sFilename, char *sFilemode, mng_handle *phMNG)
{
	#if _DEBUG > 1 //debug information
		printf("dbg2 open: %s %s\n", sFilename, sFilemode);
	#endif//_DEBUG > 1
	*phMNG              = NULL;
	userdatap   pMydata = allocuser(sFilename, sFilemode);
	if (pMydata == NULL)
		return -1;
	//now initialize mng handle
	*phMNG = mng_initialize ((mng_ptr)pMydata, myalloc, myfree, MNG_NULL);
	int iRC = *phMNG == NULL ? 1 : 0;
	// setup callbacks
	iRC = iRC != 0 ? iRC :
		(mng_setcb_openstream  (*phMNG, myopenstream ) == 0) ? 0 : 2;
	iRC = iRC != 0 ? iRC :
		(mng_setcb_closestream (*phMNG, myclosestream) == 0) ? 0 : 3;
	iRC = iRC != 0 ? iRC :
		(mng_setcb_readdata    (*phMNG, myreaddata)    == 0) ? 0 : 4;
	iRC = iRC != 0 ? iRC :
		(mng_setcb_writedata   (*phMNG, mywritedata)   == 0) ? 0 : 5;
	return iRC;
}

int  tc_close(mng_handle hMNG)
{
	#if _DEBUG > 1 //debug information
		printf("dbg2 close\n");
	#endif//_DEBUG > 1
	if (hMNG == NULL)
		return 0;
	// cleanup and return
	userdatap pMydata = (userdatap)mng_get_userdata (hMNG);
	mng_cleanup (&hMNG);
	freeuser(pMydata);
	return 0;
}

int  tc_create(mng_handle hMNG)
{
	#if _DEBUG > 1 //debug information
		printf("dbg2 create\n");
	#endif//_DEBUG > 1
	int iRC = (mng_create(hMNG) == 0) ? 0 : 10;
	iRC = iRC != 0 ? iRC :
	    (mng_putchunk_mhdr(hMNG, 640, 480, 1000, 3, 1, 3, 0x0007                   ) == 0) ? 0 : 11;
	iRC = iRC != 0 ? iRC :
	    (mng_putchunk_basi(hMNG, 640, 160, 8, 2, 0, 0, 0, 0xFF, 0x00, 0x00, 0xFF, 1) == 0) ? 0 : 12;
	iRC = iRC != 0 ? iRC :
	    (mng_putchunk_iend(hMNG                                                    ) == 0) ? 0 : 13;
	iRC = iRC != 0 ? iRC :
	    (mng_putchunk_defi(hMNG, 0, 0, 0, MNG_TRUE, 0, 160, MNG_FALSE, 0, 0, 0, 0  ) == 0) ? 0 : 14;
	iRC = iRC != 0 ? iRC :
	    (mng_putchunk_basi(hMNG, 640, 160, 8, 2, 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF, 1) == 0) ? 0 : 12;
	iRC = iRC != 0 ? iRC :
	    (mng_putchunk_iend(hMNG                                                    ) == 0) ? 0 : 13;
	iRC = iRC != 0 ? iRC :
	    (mng_putchunk_defi(hMNG, 0, 0, 0, MNG_TRUE, 0, 320, MNG_FALSE, 0, 0, 0, 0  ) == 0) ? 0 : 14;
	iRC = iRC != 0 ? iRC :
	    (mng_putchunk_basi(hMNG, 640, 160, 8, 2, 0, 0, 0, 0x00, 0x00, 0xFF, 0xFF, 1) == 0) ? 0 : 12;
	iRC = iRC != 0 ? iRC :
	    (mng_putchunk_iend(hMNG                                                    ) == 0) ? 0 : 13;
	iRC = iRC != 0 ? iRC :
	    (mng_putchunk_mend(hMNG                                                    ) == 0) ? 0 : 15;
	iRC = iRC != 0 ? iRC : (mng_write(hMNG) == 0) ? 0 : 16;
	return iRC;
}

int  tc_read(mng_handle hMNG)
{
	#if _DEBUG > 1 //debug information
		printf("dbg2 read\n");
	#endif//_DEBUG > 1
	//get data handle, read data
	userdatap pMydata = (userdatap)mng_get_userdata (hMNG);
	int       iRC     = (mng_read (hMNG) == 0) ? 0 : 20;
	iRC = iRC != 0 ? iRC :
	    (mng_iterate_chunks (hMNG, 0, myiterchunk) == 0) ? 0 : 21;
	return iRC;
}

int main(int argc, char *argv[])
{
	if ((argc < 2) || (strcmp(argv[1], "--help") == 0))
		return tc_usage();
	// read in command and filename at first
	strcpy(sCommand, argv[1]);
	if (argc >= 3)
		strcpy(sFilename, argv[2]);
	#if _DEBUG > 0
		printf("dbg1 main: %s %s %s\n", argv[0], sCommand, sFilename);
	#endif//_DEBUG

	mng_handle  hMNG = NULL;
	mng_retcode iRC  = 0;
	if (strcmp(sCommand, "read") == 0)
	{
		iRC = tc_open(sFilename, "rb", &hMNG);
		iRC = iRC != 0 ? iRC : tc_read(hMNG);
		tc_close(hMNG);
	}
	else if (strcmp(sCommand, "create") == 0)
	{
		iRC = tc_open(sFilename, "wb", &hMNG);
		iRC = iRC != 0 ? iRC : tc_create(hMNG);
		tc_close(hMNG);
	}
	else
	{
		printf("unknown command %s\n", sCommand);
		tc_usage();
	}

	if (iRC > 0)
		printf("err %d: %s\n", iRC, strErrMsg[iRC]);
	return iRC;
}
