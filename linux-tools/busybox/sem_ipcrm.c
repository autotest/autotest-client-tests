/*
 *
 * Copyright 2003, 2015 IBM Corp                                                         
 *                                                                                      
 * Redistribution and use in source and binary forms, with or without modification,    
 * are permitted provided that the following conditions are met:                    
 *     1.Redistributions of source code must retain the above copyright notice,          
 *       this list of conditions and the following disclaimer.                           
 *     2.Redistributions in binary form must reproduce the above copyright notice, this 
 *      list of conditions and the following disclaimer in the documentation and/or     
 *      other materials provided with the distribution.                                 
 *                                                                                      
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS AND ANY EXPRESS       
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF        
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 * THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF     
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,  
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS  
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                           
 *
 *
 *  FILE        : semaphore.c
 *  DESCRIPTION : Creates a semaphore for testing the ipcrm command
 *
 *  Author:
 *     Andrew Pham (apham@us.ibm.com)
 *      -written
 *
 */

#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <sys/sem.h>
#include <sys/types.h>

union semun {
  int val;
  struct semid_ds *buf;
  unsigned short *array;
};

int errors = 0;

int main(int argc, char *argv[]) {
  int semid;
  union semun semunion;
  
 /* set up the semaphore */
  if((semid = semget((key_t)9142, 1, 0666 | IPC_CREAT)) < 0) {
    return -1;
  }
  semunion.val = 1;
  if(semctl(semid, 0, SETVAL, semunion) == -1) {
    return -1;
  }

  printf ("%d", semid);
  return semid;
}
