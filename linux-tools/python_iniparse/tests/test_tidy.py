import unittest
from textwrap import dedent
from StringIO import StringIO

from iniparse import tidy,INIConfig
from iniparse.ini import  EmptyLine
from iniparse.compat import ConfigParser

class test_tidy(unittest.TestCase):
    def setUp(self):
        self.cfg = INIConfig()

    def test_empty_file(self):
        self.assertEqual(str(self.cfg), '')
        tidy(self.cfg)
        self.assertEqual(str(self.cfg), '')

    def test_last_line(self):
        self.cfg.newsection.newproperty = "Ok"
        self.assertEqual(str(self.cfg), dedent("""\
            [newsection]
            newproperty = Ok"""))
        tidy(self.cfg)
        self.assertEqual(str(self.cfg), dedent("""\
            [newsection]
            newproperty = Ok
            """))

    def test_first_line(self):
        s = dedent("""\
 
                [newsection]
                newproperty = Ok
                """)
        self.cfg._readfp(StringIO(s))
        tidy(self.cfg)
        self.assertEqual(str(self.cfg), dedent("""\
                [newsection]
                newproperty = Ok
                """))

    def test_remove_newlines(self):
        s = dedent("""\


                [newsection]
                newproperty = Ok
               



                [newsection2]

                newproperty2 = Ok


                newproperty3 = yup
               
               
                [newsection4]


                # remove blank lines, but leave continuation lines unharmed

                a = 1

                b = l1
                 l2

                
                # asdf
                 l5

                c = 2
               
               
                """)
        self.cfg._readfp(StringIO(s))
        tidy(self.cfg)
        self.assertEqual(str(self.cfg), dedent("""\
                [newsection]
                newproperty = Ok

                [newsection2]
                newproperty2 = Ok

                newproperty3 = yup

                [newsection4]
                # remove blank lines, but leave continuation lines unharmed

                a = 1

                b = l1
                 l2


                # asdf
                 l5

                c = 2
                """))

    def test_compat(self):
        s = dedent("""
            [sec1]
            a=1


            [sec2]

            b=2

            c=3


            """)
        cfg = ConfigParser()
        cfg.readfp(StringIO(s))
        tidy(cfg)
        self.assertEqual(str(cfg.data), dedent("""\
            [sec1]
            a=1

            [sec2]
            b=2

            c=3
            """))


class suite(unittest.TestSuite):
    def __init__(self):
        unittest.TestSuite.__init__(self, [
                unittest.makeSuite(test_tidy, 'test'),
    ])
