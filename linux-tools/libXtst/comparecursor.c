#include <stdio.h>
#include<stdlib.h>
#include  <X11/cursorfont.h> 
#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>

int main( int argc, char * argv[])
{

  XEvent event;
  Display *display;
  Window window;
 
  display = XOpenDisplay(NULL);
  Cursor cursor1=XCreateFontCursor(display, XC_xterm);
  Cursor cursor2=XCreateFontCursor(display, XC_xterm);

  window= XCreateSimpleWindow(display, DefaultRootWindow(display), 0, 0,
      100, 100, 0, 0, 0);
  XDefineCursor (display, window, cursor1);

  XMapWindow (display, window);
  XSync(display, False);


  if (XTestCompareCursorWithWindow(display, window, cursor1))
    printf ("found xterm cursor1\n");
 exit(0);

  if (XTestCompareCursorWithWindow(display, window, cursor2))
    printf ("found xterm cursor2\n");
 exit(0);
 
  XNextEvent (display, &event);
exit(0);
}
