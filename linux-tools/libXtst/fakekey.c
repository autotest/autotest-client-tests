#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <X11/extensions/XTest.h>
#include <X11/keysym.h>
#include <X11/Xlib.h>

extern char    *__progname;

void
usage(void)
{
	printf("Usage: %s key off/on\n", __progname);
	printf("Example: %s num off\n", __progname);
	printf("Key can be one of:  caps \n");
	exit (1);
}

int
keyState(int iKey, Display *pDisplay)
{
	int              iKeyMask;
	Window           wDummy1, wDummy2;
	int              iDummy3, iDummy4, iDummy5, iDummy6, i;
	unsigned int     iMask;
	XModifierKeymap* map;
	KeyCode          keyCode;

	keyCode = XKeysymToKeycode(pDisplay, iKey);
	map = XGetModifierMapping(pDisplay);

	if (keyCode == NoSymbol)
		return (0);

	for (i = 0; i < 8; i++)
		if (map->modifiermap[map->max_keypermod * i] == keyCode)
			iKeyMask = 1 << i;

	XQueryPointer(pDisplay, DefaultRootWindow(pDisplay),
	    &wDummy1, &wDummy2, &iDummy3, &iDummy4, &iDummy5, &iDummy6, &iMask);

	XFreeModifiermap(map);

	return ((iMask & iKeyMask) != 0);
}

int
main(int argc, char **argv)
{
	Display* pDisplay;

#ifdef DEBUG
	printf("Caps  : %d\n", keyState(XK_Caps_Lock, pDisplay));
	printf("Command Line Args: %s %s\n", argv[1], argv[2]);
#endif

        /* Check for proper usage*/
	if (argc != 3)
		usage();

	if (strcmp(argv[2], "on") != 0 && strcmp(argv[2], "off") != 0)
		usage();

	pDisplay = XOpenDisplay(NULL);
	if (pDisplay == NULL)
		return (1);

        /* Caps Lock Area */
	if (strcmp(argv[1], "caps") == 0) {
		if(keyState(XK_Caps_Lock, pDisplay) == 0 && strcmp(argv[2], "on") == 0) {
			XTestFakeKeyEvent(pDisplay, XKeysymToKeycode(pDisplay, XK_Caps_Lock), True, CurrentTime);
			XTestFakeKeyEvent(pDisplay, XKeysymToKeycode(pDisplay, XK_Caps_Lock), False, CurrentTime);
		} else if (keyState(XK_Caps_Lock, pDisplay) == 1 && strcmp(argv[2], "off") == 0) {
			XTestFakeKeyEvent(pDisplay, XKeysymToKeycode(pDisplay, XK_Caps_Lock), True, CurrentTime);
			XTestFakeKeyEvent(pDisplay, XKeysymToKeycode(pDisplay, XK_Caps_Lock), False, CurrentTime);
		}
	} else
		usage();

	XCloseDisplay(pDisplay);
	return (0);
}

