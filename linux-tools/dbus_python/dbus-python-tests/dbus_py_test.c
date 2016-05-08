/* Test fixtures for dbus-python, based on _dbus_glib_bindings.
 *
 * Copyright (C) 2007 Collabora Ltd. <http://www.collabora.co.uk/>
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include <Python.h>
#include "dbus-python.h"

#ifdef PY3
PyMODINIT_FUNC PyInit_dbus_py_test(void);
#else
PyMODINIT_FUNC initdbus_py_test(void);
#endif

#if defined(__GNUC__)
#   if __GNUC__ >= 3
#       define UNUSED __attribute__((__unused__))
#   else
#       define UNUSED /*nothing*/
#   endif
#else
#   define UNUSED /*nothing*/
#endif

static dbus_bool_t
dbus_py_test_set_up_conn(DBusConnection *conn UNUSED, void *data UNUSED)
{
    PyErr_SetString(PyExc_ValueError, "Dummy error from UnusableMainLoop");
    return 0;
}

static dbus_bool_t
dbus_py_test_set_up_srv(DBusServer *srv UNUSED, void *data UNUSED)
{
    PyErr_SetString(PyExc_ValueError, "Dummy error from UnusableMainLoop");
    return 0;
}

static void
dbus_py_test_free(void *data UNUSED)
{
}

static PyObject *
dbus_test_native_mainloop(void)
{
    PyObject *loop = DBusPyNativeMainLoop_New4(dbus_py_test_set_up_conn,
                                               dbus_py_test_set_up_srv,
                                               dbus_py_test_free,
                                               NULL);
    return loop;
}

static PyObject *
UnusableMainLoop (PyObject *always_null UNUSED, PyObject *args, PyObject *kwargs)
{
    PyObject *mainloop, *function, *result;
    int set_as_default = 0;
    static char *argnames[] = {"set_as_default", NULL};

    if (PyTuple_Size(args) != 0) {
        PyErr_SetString(PyExc_TypeError, "UnusableMainLoop() takes no "
                                         "positional arguments");
        return NULL;
    }
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "|i", argnames,
                                     &set_as_default)) {
        return NULL;
    }

    mainloop = dbus_test_native_mainloop();
    if (mainloop && set_as_default) {
        if (!_dbus_bindings_module) {
            PyErr_SetString(PyExc_ImportError, "_dbus_bindings not imported");
            Py_CLEAR(mainloop);
            return NULL;
        }
        function = PyObject_GetAttrString(_dbus_bindings_module,
                                          "set_default_main_loop");
        if (!function) {
            Py_CLEAR(mainloop);
            return NULL;
        }
        result = PyObject_CallFunctionObjArgs(function, mainloop, NULL);
        Py_CLEAR(function);
        if (!result) {
            Py_CLEAR(mainloop);
            return NULL;
        }
    }
    return mainloop;
}

static PyMethodDef module_functions[] = {
    {"UnusableMainLoop", (PyCFunction)UnusableMainLoop,
     METH_VARARGS|METH_KEYWORDS, "Return a main loop that fails to attach"},
    {NULL, NULL, 0, NULL}
};

#ifdef PY3
PyMODINIT_FUNC
PyInit_dbus_py_test(void)
{
    static struct PyModuleDef moduledef = {
        PyModuleDef_HEAD_INIT,
        "dbus_py_test",         /* m_name */
        NULL,                   /* m_doc */
        -1,                     /* m_size */
        module_functions,       /* m_methods */
        NULL,                   /* m_reload */
        NULL,                   /* m_traverse */
        NULL,                   /* m_clear */
        NULL                    /* m_free */
    };
    if (import_dbus_bindings("dbus_py_test") < 0)
        return NULL;

    return PyModule_Create(&moduledef);
}
#else
PyMODINIT_FUNC
initdbus_py_test(void)
{
    PyObject *this_module;

    if (import_dbus_bindings("dbus_py_test") < 0) return;
    this_module = Py_InitModule3 ("dbus_py_test", module_functions, "");
    if (!this_module) return;
}
#endif

/* vim:set ft=c cino< sw=4 sts=4 et: */
