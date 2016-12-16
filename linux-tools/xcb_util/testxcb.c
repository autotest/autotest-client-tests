/* Code Origin : http://en.wikibooks.org/wiki/X_Window_Programming/XCB 
 * This code is available under the Creative Commons Attribution-ShareAlike License
 * https://creativecommons.org/licenses/by-sa/3.0/legalcode
*/
#include <xcb/xcb.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
 
int
main (int argc, char **argv)
{
  xcb_connection_t *c;
  xcb_screen_t *s;
  xcb_window_t w;
  xcb_gcontext_t g;
  xcb_generic_event_t *e;
  uint32_t mask;
  uint32_t values[2];
  int done;
  xcb_rectangle_t r = { 20, 20, 60, 60 };
 
  /* open connection with the server */
 
  c = xcb_connect (NULL, NULL);
 
  if (!c)
    {
      printf ("Cannot open display\n");
      exit (1);
    }
 
  s = xcb_setup_roots_iterator (xcb_get_setup (c)).data;
 
  /* create window */
 
  mask = XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK;
  values[0] = s->white_pixel;
  values[1] = XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS;
 
  w = xcb_generate_id (c);
  xcb_create_window (c, XCB_COPY_FROM_PARENT, w, s->root,
                     10, 10, 100, 100, 1,
                     XCB_WINDOW_CLASS_INPUT_OUTPUT,
                     s->root_visual,
                     mask, values);
 
  /* create black graphics context */
 
  mask = XCB_GC_FOREGROUND | XCB_GC_GRAPHICS_EXPOSURES;
  values[0] = s->black_pixel;
  values[1] = 0;
 
  g = xcb_generate_id (c);
  xcb_create_gc (c, g, w, mask, values);
 
  /* map (show) the window */
 
  xcb_map_window (c, w);
 
  xcb_flush (c);
 
  /* event loop */
  done = 0;
  while (!done && (e = xcb_wait_for_event (c)))
    {
      switch (e->response_type)
        {
        /* (re)draw the window */
        case XCB_EXPOSE:
          printf ("EXPOSE\n");
          xcb_poly_fill_rectangle (c, w, g, 1, &r);
          xcb_flush (c);
          break;
 
        /* exit on keypress */
        case XCB_KEY_PRESS:
          done = 1;
          break;
        }
      free (e);
    }
 
    /* close connection to server */
 
    xcb_disconnect (c);
 
    return 0;
}

