/* This is based on the code provided in the documentation.
 * See either doc/index.html or online at:
 * http://docs.enlightenment.org/api/imlib2/html/
 *
 * This package is under a BSD-like license, included below:
 *
 * Copyright (C) 2000 Carsten Haitzler and various contributors (see AUTHORS)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies of the Software and its Copyright notices. In addition publicly
 * documented acknowledgment must be given that this software has been used if no
 * source code of this software is made available publicly. This includes
 * acknowledgments in either Copyright notices, Manuals, Publicity and Marketing
 * documents or any documentation provided with any product containing this
 * software. This License does not apply to any software that links to the
 * libraries provided by this software (statically or dynamically), but only to
 * the software provided.
 */

/* main program */

#include <string.h>
#include <stdio.h>
#include <Imlib2.h>
int main(int argc, char **argv)
{
  /* an image handle */
  Imlib_Image image;
  
  /* if we provided < 2 arguments after the command - exit */
  if (argc != 3) {
     printf("This test takes two arguments.  The source image file and\n"
            "the new image file.  The format is taken from the file\n"
            "extension of the new image file name.\n");
     return(1);
  }
  /* load the image */
  image = imlib_load_image(argv[1]);
  /* if the load was successful */
  if (image)
    {
      char *tmp;
      /* set the image we loaded as the current context image to work on */
      imlib_context_set_image(image);
      /* set the image format to be the format of the extension of our last */
      /* argument - i.e. .png = png, .tif = tiff etc. */
      tmp = strrchr(argv[2], '.');
      if(tmp)
         imlib_image_set_format(tmp + 1);
      /* save the image */
      imlib_save_image(argv[2]);
    }
}

