/*
 * ###########################################################################################
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
 * Author Kingsuk Deb <kingsdeb@linux.vnet.ibm.com>
*/

#include <stdio.h>
#include <fipscheck.h>

int main(void)
{
    char buf[4096];
    const char *files[] = { "/usr/bin/fipscheck",
                     "/lib64/libfipscheck.so.1" };
    const char *libname = '\0', *symbolname = '\0';
    int FAILS = 0;

/* test FIPSCHECK_verify 
 * This will invoke fipscheck on either a shared library if both libname and
 * symbolname are not NULL or on the executable binary from which the
 * FIPSCHECK_verify was called. */
    if (FIPSCHECK_verify(libname, symbolname) != 1) {
        FAILS++;
        fprintf(stderr, "FIPSCHECK_verify FAIL\n");
    }

/* test FIPSCHECK_get_binary_path
 * Auxiliary function - returns path pointing to the executable file which is
 * being run. The path buffer must be large enough to hold the path, otherwise
 * it is truncated. */        
    if (FIPSCHECK_get_binary_path(buf, sizeof(buf)) != 0) {
        FAILS++;
        fprintf(stderr, "FIPSCHECK_get_binary_path FAIL\n");
    }

/* test FIPSCHECK_get_library_path
 * Auxiliary function - returns path pointing to the shared library file with
 * a name libname and containing a symbol symbolname. The path buffer must be
 * large enough to hold the path, otherwise it is truncated. */
    if (FIPSCHECK_get_library_path("libfipscheck.so.1", "FIPSCHECK_verify",
                  buf, sizeof(buf)) != 0) {
	 FAILS++;
         fprintf(stderr, "FIPSCHECK_get_library_path FAIL\n");
    }

/* test FIPSCHECK_verify_files
 * This will invoke fipscheck to verify the HMAC checksums of the files in
 * the NULL terminated array of pointers. The same pitfalls which might
 * cause verification errors apply as above. */
    if (FIPSCHECK_verify_files(files) != 0) {
         FAILS++;
         fprintf(stderr, "FIPSCHECK_verify_files\n");
    }

/* test FIPSCHECK_kernel_fips_mode
 * Auxiliary function - returns the value of the kernel fips mode flag. */
    printf("KERNEL_FIPS_MODE_FLAG %d\n", FIPSCHECK_kernel_fips_mode());

    return FAILS;
}
