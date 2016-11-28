
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
 * /

/* include X11 stuff */
#include <X11/Xlib.h>
/* include Imlib2 stuff */
#include <Imlib2.h>
/* sprintf include */
#include <stdio.h>

/* some globals for our window & X display */
Display *disp;
Window   win;
Visual  *vis;
Colormap cm;
int      depth;

/* the program... */
int main(int argc, char **argv)
{
   /* events we get from X */
   XEvent ev;
   /* our virtual framebuffer image we draw into */
   Imlib_Image buffer;
   /* a font */
   Imlib_Font font;
   /* our color range */
   Imlib_Color_Range range;
   /* our mouse x, y coordinates */
   int mouse_x = 0, mouse_y = 0;
   /* image variable */
   Imlib_Image image;
   /* the height and width of the window */
   int h, w;
   /* arguments */
   char imagename[256];
   int sleeptime;

   if (argc !=3) {
      printf("This test takes 2 arguments, an image file and a time to\n"
             "to display the image.\n");
      return 1;
   }
   snprintf(imagename, 256, "%s", argv[1]);
   sleeptime = atoi(argv[2]);
   
   /* connect to X */
   disp  = XOpenDisplay(NULL);
   /* get default visual , colormap etc. you could ask imlib2 for what it */
   /* thinks is the best, but this example is intended to be simple */
   vis   = DefaultVisual(disp, DefaultScreen(disp));
   depth = DefaultDepth(disp, DefaultScreen(disp));
   cm    = DefaultColormap(disp, DefaultScreen(disp));
   /* create a window 640x480 */
   win = XCreateSimpleWindow(disp, DefaultRootWindow(disp), 
                             60, 60, 640, 480, 0, 0, 0);

   /* tell X what events we are interested in */
   XSelectInput(disp, win, ButtonPressMask | ButtonReleaseMask | 
                PointerMotionMask | ExposureMask);
   /* show the window */
   XMapWindow(disp, win);
   XSync(disp, 0);
   /* set our cache to 2 Mb so it doesn't have to go hit the disk as long as */
   /* the images we use use less than 2Mb of RAM (that is uncompressed) */
   imlib_set_cache_size(2048 * 1024);
   /* set the maximum number of colors to allocate for 8bpp and less to 128 */
   imlib_set_color_usage(128);
   /* dither for depths < 24bpp */
   imlib_context_set_dither(1);
   /* set the display , visual, colormap and drawable we are using */
   imlib_context_set_display(disp);
   imlib_context_set_visual(vis);
   imlib_context_set_colormap(cm);
   imlib_context_set_drawable(win);

   /* load and display the image */
   image = imlib_load_image(imagename);
   imlib_context_set_image(image);
     if (!image) {
        printf("image didn't load\n");
        return -1;
     }
   imlib_context_set_image(image);
   w = imlib_image_get_width();
   h = imlib_image_get_height();
   printf("image is %d wide, %d high\n", w, h);
   imlib_context_set_image(image);

   imlib_render_image_on_drawable(0, 0);
   imlib_free_image();
   sleep(sleeptime);

   return 0;
}
