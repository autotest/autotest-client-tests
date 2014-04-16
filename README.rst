=========================
Client tests for autotest
=========================

This is where we develop the majority of the
available test modules for autotest. The
exception being the larger, more complex
tests, such as the virt test project:

https://github.com/autotest/virt-test

And the autotest-docker project:

https://github.com/autotest/autotest-docker

Really quick start guide
------------------------

1) Fork this repo on github
2) Create a new topic branch for your work
3) Make sure you have `inspektor installed. <https://github.com/autotest/inspektor#inspektor>`_
4) Run:

::

    inspekt lint
    inspekt style
5) Fix any problems
6) Push your changes and submit a pull request
7) That's it.
