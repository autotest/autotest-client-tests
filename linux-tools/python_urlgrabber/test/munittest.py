#!/usr/bin/env python
"""
This is a modified version of the unittest module has been modified by
Michael D. Stenner from Steve Purcell's version (revision 1.46, as
distributed with python 2.3.3) in the following ways:

  * the text formatting has been made much prettier by printing "nested"
    test suites
  * the test resulte "skip" has been added for skipping tests.  A test
    can call any of the .skip() .skipUnless(<test>), or .skipIf(<test>)
    methods from within the test method or the setUp method.
  * all attributes originally named with leading "__" have been changed
    to a single "_".  This makes subclassing much easier.

COMPATIBILITY

  It should be possible to drop this in as replacement for the
  standard unittest module simply by doing:

    import munittest as unittest

  In fact, the reverse is ALMOST true.  Test code written for this
  module very nearly runs perfectly with the standard unittest module.
  Exceptions are:

    * The .skip() methods will obviously not work on the standard
      unittest.  However, they will ERROR out and the error message will
      complain about missing .skip() attributes, so it will be obvious and
      will have the same effect as skipping.

    * the .setDescription method (or description argument) for
      TestSuite will not work.  However, setting the .description
      attribute on a standard TestSuite instance does no harm, so if
      need to set them manually (you're not satisfied with the
      doc-string route) and you WANT to be compatible both ways, do
      that :)

DESCRIPTIONS

  Names for suites in the pretty formatting are (like the test
  functions) slurped from the doc-strings of the corresponding object,
  or taken from the names of those objects.  This applies to both
  TestCase-derived classes, and modules.  Also, the TestSuite class
  description can be set manually in a number of ways (all of which
  achieve the same result):

    suite = TestSuite(test_list, 'this is the description')
    suite.setDescription('this is the description')
    suite.description = 'this is the description'

Michael D. Stenner <mstenner@linux.duke.edu>
2004/03/18
v0.1
===========================================================================
The original doc-string for this module follows:
===========================================================================
Python unit testing framework, based on Erich Gamma's JUnit and Kent Beck's
Smalltalk testing framework.

This module contains the core framework classes that form the basis of
specific test cases and suites (TestCase, TestSuite etc.), and also a
text-based utility class for running the tests and reporting the results
 (TextTestRunner).

Simple usage:

    import unittest

    class IntegerArithmenticTestCase(unittest.TestCase):
        def testAdd(self):  ## test method names begin 'test*'
            self.assertEquals((1 + 2), 3)
            self.assertEquals(0 + 1, 1)
        def testMultiply(self):
            self.assertEquals((0 * 10), 0)
            self.assertEquals((5 * 8), 40)

    if __name__ == '__main__':
        unittest.main()

Further information is available in the bundled documentation, and from

  http://pyunit.sourceforge.net/

Copyright (c) 1999, 2000, 2001 Steve Purcell
This module is free software, and you may redistribute it and/or modify
it under the same terms as Python itself, so long as this copyright message
and disclaimer are retained in their original form.

IN NO EVENT SHALL THE AUTHOR BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF
THIS CODE, EVEN IF THE AUTHOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.

THE AUTHOR SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE.  THE CODE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS,
AND THERE IS NO OBLIGATION WHATSOEVER TO PROVIDE MAINTENANCE,
SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
"""

# $Id: munittest.py,v 1.2 2004/03/31 01:27:24 mstenner Exp $

import time
import sys
import traceback
import string
import os
import types

##############################################################################
# Exported classes and functions
##############################################################################
__all__ = ['TestResult', 'TestCase', 'TestSuite', 'TextTestRunner',
           'TestLoader', 'FunctionTestCase', 'main', 'defaultTestLoader']

# Expose obsolete functions for backwards compatibility
__all__.extend(['getTestCaseNames', 'makeSuite', 'findTestCases'])


##############################################################################
# Test framework core
##############################################################################

# All classes defined herein are 'new-style' classes, allowing use of 'super()'
__metaclass__ = type

def _strclass(cls):
    return "%s.%s" % (cls.__module__, cls.__name__)

class TestResult:
    """Holder for test result information.

    Test results are automatically managed by the TestCase and TestSuite
    classes, and do not need to be explicitly manipulated by writers of tests.

    Each instance holds the total number of tests run, and collections of
    failures and errors that occurred among those test runs. The collections
    contain tuples of (testcase, exceptioninfo), where exceptioninfo is the
    formatted traceback of the error that occurred.
    """
    def __init__(self):
        self.failures = []
        self.errors = []
        self.skipped = []
        self.testsRun = 0
        self.shouldStop = 0

    def startTest(self, test):
        "Called when the given test is about to be run"
        self.testsRun = self.testsRun + 1

    def stopTest(self, test):
        "Called when the given test has been run"
        pass

    def startSuite(self, suite):
        "Called when the given suite is about to be run"
        pass

    def stopSuit(self, suite):
        "Called when the tiven suite has been run"
        pass

    def addError(self, test, err):
        """Called when an error has occurred. 'err' is a tuple of values as
        returned by sys.exc_info().
        """
        self.errors.append((test, self._exc_info_to_string(err)))

    def addFailure(self, test, err):
        """Called when an error has occurred. 'err' is a tuple of values as
        returned by sys.exc_info()."""
        self.failures.append((test, self._exc_info_to_string(err)))

    def addSuccess(self, test):
        "Called when a test has completed successfully"
        pass

    def addSkip(self, test, err):
        "Called when the test has been skipped"
        self.skipped.append((test, self._exc_info_to_string(err)))

    def wasSuccessful(self):
        "Tells whether or not this result was a success"
        return len(self.failures) == len(self.errors) == 0

    def stop(self):
        "Indicates that the tests should be aborted"
        self.shouldStop = 1

    def _exc_info_to_string(self, err):
        """Converts a sys.exc_info()-style tuple of values into a string."""
        return string.join(traceback.format_exception(*err), '')

    def __repr__(self):
        return "<%s run=%i errors=%i failures=%i>" % \
               (_strclass(self.__class__), self.testsRun, len(self.errors),
                len(self.failures))


class TestCase:
    """A class whose instances are single test cases.

    By default, the test code itself should be placed in a method named
    'runTest'.

    If the fixture may be used for many test cases, create as
    many test methods as are needed. When instantiating such a TestCase
    subclass, specify in the constructor arguments the name of the test method
    that the instance is to execute.

    Test authors should subclass TestCase for their own tests. Construction
    and deconstruction of the test's environment ('fixture') can be
    implemented by overriding the 'setUp' and 'tearDown' methods respectively.

    If it is necessary to override the __init__ method, the base class
    __init__ method must always be called. It is important that subclasses
    should not change the signature of their __init__ method, since instances
    of the classes are instantiated automatically by parts of the framework
    in order to be run.
    """

    # This attribute determines which exception will be raised when
    # the instance's assertion methods fail; test methods raising this
    # exception will be deemed to have 'failed' rather than 'errored'

    failureException = AssertionError

    # test methods raising the following exception will be considered
    # skipped - this is neither pass, fail, or error.  it should be
    # used when some resource needed to perform the test isn't avialable,
    # or when a lengthy test is deliberately skipped for time.

    class skipException(Exception): pass

    # whether receiving KeyboardInterrupt during setUp or the test causes
    # the test to be interpreted as skipped.  The default is no.  It's
    # probably best to do:
    #   except KeyboardInterrupt: self.skip()
    # inside the test method

    interrupt_skips = 0

    def __init__(self, methodName='runTest'):
        """Create an instance of the class that will use the named test
           method when executed. Raises a ValueError if the instance does
           not have a method with the specified name.
        """
        try:
            self._testMethodName = methodName
            testMethod = getattr(self, methodName)
            self._testMethodDoc = testMethod.__doc__
        except AttributeError:
            raise ValueError, "no such test method in %s: %s" % \
                  (self.__class__, methodName)

    def setUp(self):
        "Hook method for setting up the test fixture before exercising it."
        pass

    def tearDown(self):
        "Hook method for deconstructing the test fixture after testing it."
        pass

    def countTestCases(self):
        return 1

    def defaultTestResult(self):
        return TestResult()

    def shortDescription(self):
        """Returns a one-line description of the test, or None if no
        description has been provided.

        The default implementation of this method returns the first line of
        the specified test method's docstring.
        """
        doc = self._testMethodDoc
        return doc and string.strip(string.split(doc, "\n")[0]) or None

    def id(self):
        return "%s.%s" % (_strclass(self.__class__), self._testMethodName)

    def __str__(self):
        return "%s (%s)" % (self._testMethodName, _strclass(self.__class__))

    def __repr__(self):
        return "<%s testMethod=%s>" % \
               (_strclass(self.__class__), self._testMethodName)

    def run(self, result=None):
        return self(result)

    def __call__(self, result=None):
        if result is None: result = self.defaultTestResult()
        result.startTest(self)
        testMethod = getattr(self, self._testMethodName)
        try:
            try:
                self.setUp()
            except KeyboardInterrupt:
                if self.interrupt_skips:
                    result.addSkip(self, self._exc_info())
                    return
                else:
                    raise
            except self.skipException:
                result.addSkip(self, self._exc_info())
                return
            except:
                result.addError(self, self._exc_info())
                return

            ok = 0
            try:
                testMethod()
                ok = 1
            except self.failureException:
                result.addFailure(self, self._exc_info())
            except KeyboardInterrupt:
                if self.interrupt_skips:
                    result.addSkip(self, self._exc_info())
                    return
                else:
                    raise
            except self.skipException:
                result.addSkip(self, self._exc_info())
                return
            except:
                result.addError(self, self._exc_info())

            try:
                self.tearDown()
            except KeyboardInterrupt:
                raise
            except:
                result.addError(self, self._exc_info())
                ok = 0
            if ok: result.addSuccess(self)
        finally:
            result.stopTest(self)

    def debug(self):
        """Run the test without collecting errors in a TestResult"""
        self.setUp()
        getattr(self, self._testMethodName)()
        self.tearDown()

    def _exc_info(self):
        """Return a version of sys.exc_info() with the traceback frame
           minimised; usually the top level of the traceback frame is not
           needed.
        """
        exctype, excvalue, tb = sys.exc_info()
        if sys.platform[:4] == 'java': ## tracebacks look different in Jython
            return (exctype, excvalue, tb)
        newtb = tb.tb_next
        if newtb is None:
            return (exctype, excvalue, tb)
        return (exctype, excvalue, newtb)

    def fail(self, msg=None):
        """Fail immediately, with the given message."""
        raise self.failureException, msg

    def failIf(self, expr, msg=None):
        "Fail the test if the expression is true."
        if expr: raise self.failureException, msg

    def failUnless(self, expr, msg=None):
        """Fail the test unless the expression is true."""
        if not expr: raise self.failureException, msg

    def failUnlessRaises(self, excClass, callableObj, *args, **kwargs):
        """Fail unless an exception of class excClass is thrown
           by callableObj when invoked with arguments args and keyword
           arguments kwargs. If a different type of exception is
           thrown, it will not be caught, and the test case will be
           deemed to have suffered an error, exactly as for an
           unexpected exception.
        """
        try:
            callableObj(*args, **kwargs)
        except excClass:
            return
        else:
            if hasattr(excClass,'__name__'): excName = excClass.__name__
            else: excName = str(excClass)
            raise self.failureException, excName

    def failUnlessEqual(self, first, second, msg=None):
        """Fail if the two objects are unequal as determined by the '=='
           operator.
        """
        if not first == second:
            raise self.failureException, \
                  (msg or '%s != %s' % (`first`, `second`))

    def failIfEqual(self, first, second, msg=None):
        """Fail if the two objects are equal as determined by the '=='
           operator.
        """
        if first == second:
            raise self.failureException, \
                  (msg or '%s == %s' % (`first`, `second`))

    def failUnlessAlmostEqual(self, first, second, places=7, msg=None):
        """Fail if the two objects are unequal as determined by their
           difference rounded to the given number of decimal places
           (default 7) and comparing to zero.

           Note that decimal places (from zero) is usually not the same
           as significant digits (measured from the most significant digit).
        """
        if round(second-first, places) != 0:
            raise self.failureException, \
                  (msg or '%s != %s within %s places' % (`first`, `second`, `places` ))

    def failIfAlmostEqual(self, first, second, places=7, msg=None):
        """Fail if the two objects are equal as determined by their
           difference rounded to the given number of decimal places
           (default 7) and comparing to zero.

           Note that decimal places (from zero) is usually not the same
           as significant digits (measured from the most significant digit).
        """
        if round(second-first, places) == 0:
            raise self.failureException, \
                  (msg or '%s == %s within %s places' % (`first`, `second`, `places`))

    assertEqual = assertEquals = failUnlessEqual

    assertNotEqual = assertNotEquals = failIfEqual

    assertAlmostEqual = assertAlmostEquals = failUnlessAlmostEqual

    assertNotAlmostEqual = assertNotAlmostEquals = failIfAlmostEqual

    assertRaises = failUnlessRaises

    assert_ = failUnless

    def skip(self, msg=None):
        """Skip the test"""
        raise self.skipException, msg

    def skipIf(self, expr, msg=None):
        "Skip the test if the expression is true."
        if expr: raise self.skipException, msg

    def skipUnless(self, expr, msg=None):
        """Skip the test unless the expression is true."""
        if not expr: raise self.skipException, msg



class TestSuite:
    """A test suite is a composite test consisting of a number of TestCases.

    For use, create an instance of TestSuite, then add test case instances.
    When all tests have been added, the suite can be passed to a test
    runner, such as TextTestRunner. It will run the individual test cases
    in the order in which they were added, aggregating the results. When
    subclassing, do not forget to call the base class constructor.
    """
    def __init__(self, tests=(), description=None):
        self._tests = []
        self.addTests(tests)
        self.description = description or '(no description)'
        
    def __repr__(self):
        return "<%s tests=%s>" % (_strclass(self.__class__), self._tests)

    __str__ = __repr__
    
    def shortDescription(self):
        return self.description

    def setDescription(self, description):
        self.description = description

    def countTestCases(self):
        cases = 0
        for test in self._tests:
            cases = cases + test.countTestCases()
        return cases

    def addTest(self, test):
        self._tests.append(test)

    def addTests(self, tests):
        for test in tests:
            self.addTest(test)

    def run(self, result):
        return self(result)

    def __call__(self, result):
        try: result.startSuite(self)
        except AttributeError: pass
        
        for test in self._tests:
            if result.shouldStop:
                break
            test(result)

        try: result.endSuite(self)
        except AttributeError: pass

        return result

    def debug(self):
        """Run the tests without collecting errors in a TestResult"""
        for test in self._tests: test.debug()


class FunctionTestCase(TestCase):
    """A test case that wraps a test function.

    This is useful for slipping pre-existing test functions into the
    PyUnit framework. Optionally, set-up and tidy-up functions can be
    supplied. As with TestCase, the tidy-up ('tearDown') function will
    always be called if the set-up ('setUp') function ran successfully.
    """

    def __init__(self, testFunc, setUp=None, tearDown=None,
                 description=None):
        TestCase.__init__(self)
        self._setUpFunc = setUp
        self._tearDownFunc = tearDown
        self._testFunc = testFunc
        self._description = description

    def setUp(self):
        if self._setUpFunc is not None:
            self._setUpFunc()

    def tearDown(self):
        if self._tearDownFunc is not None:
            self._tearDownFunc()

    def runTest(self):
        self._testFunc()

    def id(self):
        return self._testFunc.__name__

    def __str__(self):
        return "%s (%s)" % (_strclass(self.__class__), self._testFunc.__name__)

    def __repr__(self):
        return "<%s testFunc=%s>" % (_strclass(self.__class__), self._testFunc)

    def shortDescription(self):
        if self._description is not None: return self._description
        doc = self._testFunc.__doc__
        return doc and string.strip(string.split(doc, "\n")[0]) or None



##############################################################################
# Locating and loading tests
##############################################################################

class TestLoader:
    """This class is responsible for loading tests according to various
    criteria and returning them wrapped in a Test
    """
    testMethodPrefix = 'test'
    sortTestMethodsUsing = cmp
    suiteClass = TestSuite

    def loadTestsFromTestCase(self, testCaseClass):
        """Return a suite of all tests cases contained in testCaseClass"""
        name_list = self.getTestCaseNames(testCaseClass)
        instance_list = map(testCaseClass, name_list)
        description = getattr(testCaseClass, '__doc__') \
                      or testCaseClass.__name__
        description = (description.splitlines()[0]).strip()
        suite = self.suiteClass(instance_list, description)
        return suite
    
    def loadTestsFromModule(self, module):
        """Return a suite of all tests cases contained in the given module"""
        tests = []
        for name in dir(module):
            obj = getattr(module, name)
            if (isinstance(obj, (type, types.ClassType)) and
                issubclass(obj, TestCase) and
                not obj in [TestCase, FunctionTestCase]):
                tests.append(self.loadTestsFromTestCase(obj))
        description = getattr(module, '__doc__') \
                      or module.__name__
        description = (description.splitlines()[0]).strip()
        return self.suiteClass(tests, description)

    def loadTestsFromName(self, name, module=None):
        """Return a suite of all tests cases given a string specifier.

        The name may resolve either to a module, a test case class, a
        test method within a test case class, or a callable object which
        returns a TestCase or TestSuite instance.

        The method optionally resolves the names relative to a given module.
        """
        parts = string.split(name, '.')
        if module is None:
            if not parts:
                raise ValueError, "incomplete test name: %s" % name
            else:
                parts_copy = parts[:]
                while parts_copy:
                    try:
                        module = __import__(string.join(parts_copy,'.'))
                        break
                    except ImportError:
                        del parts_copy[-1]
                        if not parts_copy: raise
                parts = parts[1:]
        obj = module
        for part in parts:
            obj = getattr(obj, part)

        import unittest
        if type(obj) == types.ModuleType:
            return self.loadTestsFromModule(obj)
        elif (isinstance(obj, (type, types.ClassType)) and
              issubclass(obj, unittest.TestCase)):
            return self.loadTestsFromTestCase(obj)
        elif type(obj) == types.UnboundMethodType:
            return obj.im_class(obj.__name__)
        elif callable(obj):
            test = obj()
            if not isinstance(test, unittest.TestCase) and \
               not isinstance(test, unittest.TestSuite):
                raise ValueError, \
                      "calling %s returned %s, not a test" % (obj,test)
            return test
        else:
            raise ValueError, "don't know how to make test from: %s" % obj

    def loadTestsFromNames(self, names, module=None):
        """Return a suite of all tests cases found using the given sequence
        of string specifiers. See 'loadTestsFromName()'.
        """
        suites = []
        for name in names:
            suites.append(self.loadTestsFromName(name, module))
        return self.suiteClass(suites)

    def getTestCaseNames(self, testCaseClass):
        """Return a sorted sequence of method names found within testCaseClass
        """
        testFnNames = filter(lambda n,p=self.testMethodPrefix: n[:len(p)] == p,
                             dir(testCaseClass))
        for baseclass in testCaseClass.__bases__:
            for testFnName in self.getTestCaseNames(baseclass):
                if testFnName not in testFnNames:  # handle overridden methods
                    testFnNames.append(testFnName)
        if self.sortTestMethodsUsing:
            testFnNames.sort(self.sortTestMethodsUsing)
        return testFnNames



defaultTestLoader = TestLoader()


##############################################################################
# Patches for old functions: these functions should be considered obsolete
##############################################################################

def _makeLoader(prefix, sortUsing, suiteClass=None):
    loader = TestLoader()
    loader.sortTestMethodsUsing = sortUsing
    loader.testMethodPrefix = prefix
    if suiteClass: loader.suiteClass = suiteClass
    return loader

def getTestCaseNames(testCaseClass, prefix, sortUsing=cmp):
    return _makeLoader(prefix, sortUsing).getTestCaseNames(testCaseClass)

def makeSuite(testCaseClass, prefix='test', sortUsing=cmp, suiteClass=TestSuite):
    return _makeLoader(prefix, sortUsing, suiteClass).loadTestsFromTestCase(testCaseClass)

def findTestCases(module, prefix='test', sortUsing=cmp, suiteClass=TestSuite):
    return _makeLoader(prefix, sortUsing, suiteClass).loadTestsFromModule(module)


##############################################################################
# Text UI
##############################################################################

class _WritelnDecorator:
    """Used to decorate file-like objects with a handy 'writeln' method"""
    def __init__(self,stream):
        self.stream = stream

    def __getattr__(self, attr):
        return getattr(self.stream,attr)

    def write(self, arg):
        self.stream.write(arg)
        self.stream.flush()

    def writeln(self, arg=None):
        if arg: self.write(arg)
        self.write('\n') # text-mode streams translate to \r\n if needed


class _TextTestResult(TestResult):
    """A test result class that can print formatted text results to a stream.

    Used by TextTestRunner.
    """
    separator1 = '=' * 79
    separator2 = '-' * 79

    def __init__(self, stream, descriptions, verbosity):
        TestResult.__init__(self)
        self.stream = stream
        self.showAll = verbosity > 1
        self.dots = verbosity == 1
        self.descriptions = descriptions
        if descriptions: self.indent = '  '
        else: self.indent = ''
        self.depth = 0
        self.width = 80

    def getDescription(self, test):
        if self.descriptions:
            return test.shortDescription() or str(test)
        else:
            return str(test)

    def startSuite(self, suite):
        if self.showAll and self.descriptions:
            self.stream.write(self.indent * self.depth)
            try: desc = self.getDescription(suite)
            except AttributeError: desc = '(no description)'
            self.stream.writeln(desc)
        self.depth += 1
        
    def startTest(self, test):
        TestResult.startTest(self, test)
        if self.showAll:
            self.stream.write(self.indent * self.depth)
            d = self.getDescription(test)
            dwidth = self.width - len(self.indent) * self.depth - 11
            format = "%%-%is" % dwidth
            self.stream.write(format % d)
            self.stream.write(" ... ")

    def addSuccess(self, test):
        TestResult.addSuccess(self, test)
        if self.showAll:
            self.stream.writeln("ok")
        elif self.dots:
            self.stream.write('.')

    def addError(self, test, err):
        TestResult.addError(self, test, err)
        if self.showAll:
            self.stream.writeln("ERROR")
        elif self.dots:
            self.stream.write('E')

    def addFailure(self, test, err):
        TestResult.addFailure(self, test, err)
        if self.showAll:
            self.stream.writeln("FAIL")
        elif self.dots:
            self.stream.write('F')

    def addSkip(self, test, err):
        TestResult.addSkip(self, test, err)
        if self.showAll:
            self.stream.writeln("skip")
        elif self.dots:
            self.stream.write('s')

    def endSuite(self, suite):
        self.depth -= 1

    def printErrors(self):
        if self.dots or self.showAll:
            self.stream.writeln()
        self.printErrorList('ERROR', self.errors)
        self.printErrorList('FAIL', self.failures)

    def printErrorList(self, flavour, errors):
        for test, err in errors:
            self.stream.writeln(self.separator1)
            self.stream.writeln("%s: %s" % (flavour,self.getDescription(test)))
            self.stream.writeln(self.separator2)
            self.stream.writeln("%s" % err)


class TextTestRunner:
    """A test runner class that displays results in textual form.

    It prints out the names of tests as they are run, errors as they
    occur, and a summary of the results at the end of the test run.
    """
    def __init__(self, stream=sys.stderr, descriptions=1, verbosity=1):
        self.stream = _WritelnDecorator(stream)
        self.descriptions = descriptions
        self.verbosity = verbosity

    def _makeResult(self):
        return _TextTestResult(self.stream, self.descriptions, self.verbosity)

    def run(self, test):
        "Run the given test case or test suite."
        result = self._makeResult()
        startTime = time.time()
        test(result)
        stopTime = time.time()
        timeTaken = float(stopTime - startTime)
        result.printErrors()
        self.stream.writeln(result.separator2)
        run = result.testsRun
        self.stream.writeln("Ran %d test%s in %.3fs" %
                            (run, run != 1 and "s" or "", timeTaken))
        self.stream.writeln()
        if not result.wasSuccessful():
            self.stream.write("FAILED (")
            failed, errored, skipped = map(len, \
                (result.failures, result.errors, result.skipped))
            if failed:
                self.stream.write("failures=%d" % failed)
            if errored:
                if failed: self.stream.write(", ")
                self.stream.write("errors=%d" % errored)
            if skipped:
                self.stream.write(", skipped=%d" % skipped)
            self.stream.writeln(")")
        else:
            if result.skipped:
                self.stream.writeln("OK (skipped=%d)" % len(result.skipped))
            else:
                self.stream.writeln("OK")
        return result



##############################################################################
# Facilities for running tests from the command line
##############################################################################

class TestProgram:
    """A command-line program that runs a set of tests; this is primarily
       for making test modules conveniently executable.
    """
    USAGE = """\
Usage: %(progName)s [options] [test] [...]

Options:
  -h, --help       Show this message
  -v, --verbose    Verbose output
  -q, --quiet      Minimal output

Examples:
  %(progName)s                               - run default set of tests
  %(progName)s MyTestSuite                   - run suite 'MyTestSuite'
  %(progName)s MyTestCase.testSomething      - run MyTestCase.testSomething
  %(progName)s MyTestCase                    - run all 'test*' test methods
                                               in MyTestCase
"""
    def __init__(self, module='__main__', defaultTest=None,
                 argv=None, testRunner=None, testLoader=defaultTestLoader):
        if type(module) == type(''):
            self.module = __import__(module)
            for part in string.split(module,'.')[1:]:
                self.module = getattr(self.module, part)
        else:
            self.module = module
        if argv is None:
            argv = sys.argv
        self.verbosity = 1
        self.defaultTest = defaultTest
        self.testRunner = testRunner
        self.testLoader = testLoader
        self.progName = os.path.basename(argv[0])
        self.parseArgs(argv)
        self.runTests()

    def usageExit(self, msg=None):
        if msg: print msg
        print self.USAGE % self.__dict__
        sys.exit(2)

    def parseArgs(self, argv):
        import getopt
        try:
            options, args = getopt.getopt(argv[1:], 'hHvq',
                                          ['help','verbose','quiet'])
            for opt, value in options:
                if opt in ('-h','-H','--help'):
                    self.usageExit()
                if opt in ('-q','--quiet'):
                    self.verbosity = 0
                if opt in ('-v','--verbose'):
                    self.verbosity = 2
            if len(args) == 0 and self.defaultTest is None:
                self.test = self.testLoader.loadTestsFromModule(self.module)
                return
            if len(args) > 0:
                self.testNames = args
            else:
                self.testNames = (self.defaultTest,)
            self.createTests()
        except getopt.error, msg:
            self.usageExit(msg)

    def createTests(self):
        self.test = self.testLoader.loadTestsFromNames(self.testNames,
                                                       self.module)

    def runTests(self):
        if self.testRunner is None:
            self.testRunner = TextTestRunner(verbosity=self.verbosity)
        result = self.testRunner.run(self.test)
        sys.exit(not result.wasSuccessful())

main = TestProgram


##############################################################################
# Executing this module from the command line
##############################################################################

if __name__ == "__main__":
    main(module=None)
