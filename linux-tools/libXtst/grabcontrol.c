#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>


int
main (int argc, char *argv[])
{
  Display *display;
  int eventbase, errorbase, majorver, minorver;
  int x, y;
  struct timespec delay = { 0, 500000 };

  if (argc != 3)
    {
      fprintf (stderr, "Usage: grabcontrol <x> <y>\n");
      exit (1);
    }

  x = atoi (argv[1]);
  y = atoi (argv[2]);

  if ((display = XOpenDisplay(XDisplayName(NULL))) == NULL)
    {
      fprintf (stderr, "Can't connect to X display\n");
      exit(1);
    }

  if (!XTestQueryExtension(display, &eventbase, &errorbase,
                           &majorver, &minorver))
    {
      fprintf (stderr, "Can't find XTest support\n");
      exit(1);
    }

  XTestGrabControl(display, True);
  XTestFakeMotionEvent (display, DefaultScreen (display),
                        x, y, CurrentTime);

  XTestFakeButtonEvent(display, 1, True, CurrentTime);
  nanosleep (&delay, NULL);
  XTestFakeButtonEvent(display, 1, False, CurrentTime);

  XTestGrabControl(display, False);

  XFlush (display);

  return 0;
}
