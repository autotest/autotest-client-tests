#include <libmng.h>
#ifndef _MAX_PATH
#define _MAX_PATH 280
#endif//_MAX_PATH
#ifndef _DEBUG
#define _DEBUG 0
#endif//_DEBUG

// user's data handle structure
typedef struct user_struct
{
	FILE *hFile;                 /* file handle */
	int   iIndent;               /* for nice indented formatting */
	char  sName[_MAX_PATH];      /* file name */
	char  sMode[_MAX_PATH];      /* file open mode */
} userdata;
typedef userdata* userdatap;

// alloc data handle
userdatap allocuser(char *sFilename, char *sFilemode)
{
	userdatap   pMydata = calloc(1, sizeof(userdata));
	if (pMydata == NULL)
		return  NULL;
	pMydata->hFile   = NULL;
	pMydata->iIndent = 2;
	strcpy(pMydata->sName, sFilename);
	strcpy(pMydata->sMode, sFilemode);
	return pMydata;
}
// free data handle
void      freeuser(userdatap pMydata)
{
	if (pMydata != NULL)
		free(pMydata);
}

//call back functions used in libmng stuff
mng_ptr  myalloc(mng_size_t iSize)
{
	#if _DEBUG > 2
		printf("dbg3 alloc: %d\n", iSize);
	#endif//_DEBUG > 2
	return (mng_ptr)calloc (1, (size_t)iSize);
}

void     myfree(mng_ptr pPtr, mng_size_t iSize)
{
	#if _DEBUG > 2
		printf("dbg3 free: %d\n", iSize);
	#endif//_DEBUG > 1
	free (pPtr);
}

mng_bool myopenstream(mng_handle hMNG)
{
	#if _DEBUG > 2
		printf("dbg3 openstream: \n");
	#endif//_DEBUG > 1
	// get data handle, and open the file
	userdatap pMydata = (userdatap)mng_get_userdata (hMNG);
	pMydata->hFile    = fopen(pMydata->sName, pMydata->sMode);
	return pMydata->hFile == NULL ? MNG_FALSE : MNG_TRUE;
}

mng_bool myclosestream(mng_handle hMNG)
{
	#if _DEBUG > 2
		printf("dbg3 closestream: \n");
	#endif//_DEBUG > 1
	// get data handle, and open the file
	userdatap pMydata = (userdatap)mng_get_userdata (hMNG);
	if (pMydata->hFile != NULL)
		fclose(pMydata->hFile);
	pMydata->hFile = NULL;
	return MNG_TRUE;
}

mng_bool myreaddata (mng_handle hMNG,
                     mng_ptr    pBuf,
                     mng_uint32 iSize,
                     mng_uint32 *iRead)
{
	#if _DEBUG > 2
		printf("dbg3 readdata: %d\n", iSize);
	#endif//_DEBUG > 1
	// get data handle, and read from file
	userdatap pMydata = (userdatap)mng_get_userdata (hMNG);
	*iRead = fread (pBuf, 1, iSize, pMydata->hFile);
	// iRead will indicate EOF
	return MNG_TRUE;
}

mng_bool mywritedata(mng_handle hMNG,
                     mng_ptr    pBuf,
                     mng_uint32 iSize,
                     mng_uint32 *iWrite)
{
	#if _DEBUG > 2
		printf("dbg3 writedata: %d\n", iSize);
	#endif//_DEBUG > 1
	// get data handle, and write to file
	userdatap pMydata = (userdatap)mng_get_userdata (hMNG);
	*iWrite = fwrite(pBuf, 1, iSize, pMydata->hFile);
	// pWritten indicate how much data written
	return MNG_TRUE;
}

mng_bool myiterchunk (mng_handle  hMNG,
                      mng_handle  hChunk,
                      mng_chunkid iChunktype,
                      mng_uint32  iChunkseq)
{
	#if _DEBUG > 2
		printf("dbg3 iterchunk: %d\n", iChunktype);
	#endif//_DEBUG > 1
	// get data handle
	userdatap pMydata = (userdatap)mng_get_userdata (hMNG);
	// decode the chunkname
	char aCh[4];
	aCh[0] = (char)((iChunktype >> 24) & 0xFF);
	aCh[1] = (char)((iChunktype >> 16) & 0xFF);
	aCh[2] = (char)((iChunktype >>  8) & 0xFF);
	aCh[3] = (char)((iChunktype      ) & 0xFF);
	// indent less ?
	if ((iChunktype == MNG_UINT_MEND) || (iChunktype == MNG_UINT_IEND) ||
	    (iChunktype == MNG_UINT_ENDL)   )
		pMydata->iIndent -= 2;

	char zIndent[80];
	memset(zIndent, ' ', pMydata->iIndent);
	zIndent[pMydata->iIndent] = '\0';
	//indent more ? 
	if ((iChunktype == MNG_UINT_MHDR) || (iChunktype == MNG_UINT_IHDR) ||
	    (iChunktype == MNG_UINT_JHDR) || (iChunktype == MNG_UINT_DHDR) ||
	    (iChunktype == MNG_UINT_BASI) || (iChunktype == MNG_UINT_LOOP)   )
		pMydata->iIndent += 2;

	/* keep'm coming... */
	return MNG_TRUE;
}
//fill callback functions over!
