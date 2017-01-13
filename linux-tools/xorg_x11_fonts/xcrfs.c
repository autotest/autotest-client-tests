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
 *
 */

#include <stdio.h>
#include <locale.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

int
main(int argc, char *argv[])
{
  Display* d;
  XFontSet fs;
  int i, rc=0;
  int n_miss, num;
  char *base_font_name = NULL;
  char *lang = "";
  char **miss, *def;
  char **fn_list;
  XFontStruct **fs_list;

  for (i=1; i<argc; i++) {
    char *opt = argv[i];

    if (!strcmp(opt,"-lang")) {
      lang = argv[++i];
    } else if (!strcmp(opt,"-fs")) {
      base_font_name = argv[++i];
    }
  }

  printf("[%s]\n",setlocale(LC_CTYPE,lang));
  d = XOpenDisplay(NULL);
  if (!d) {
    printf("Can't open display\n");
    exit (101);
  }
  if (!XSupportsLocale()) {
    printf("X Locale [%s] is not supported.\n", lang);
    exit (111);
  }
  XSynchronize(d,True);

  /* Create a FontSet */
  fs = XCreateFontSet (d, base_font_name, &miss, &n_miss, &def);
  if (fs == NULL) {
    printf("Can't create fontset [%s]\n", base_font_name);
    exit (202);
  }

  rc=0;
  printf("missing count = %d\n", n_miss);
  if (n_miss > 0) {
    for (i=0; i<n_miss; i++) {
      printf("Missing font #%d [%s]\n",i,miss[i]);
    }
    rc=n_miss;
  }

  num = XFontsOfFontSet(fs, &fs_list, &fn_list);
  for (i=0; i<num; i++) {
    printf("FID=0x%08x [%s]\n", fs_list[i]->fid, fn_list[i]);
  }

  exit (rc);
}
