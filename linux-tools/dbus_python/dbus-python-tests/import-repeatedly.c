/* Regression test for https://bugs.freedesktop.org/show_bug.cgi?id=23831 */

#include <Python.h>

int main(void)
{
    int i;

    for (i = 0; i < 100; ++i) {
        Py_Initialize();
        PyRun_SimpleString("import dbus\n");
        Py_Finalize();
    }

    return 0;
}
