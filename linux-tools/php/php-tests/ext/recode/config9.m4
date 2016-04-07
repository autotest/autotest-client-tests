dnl
dnl $Id$
dnl

dnl Check for extensions with which Recode can not work
if test "$PHP_RECODE" != "no"; then

  if test -n "$recode_conflict"; then
    AC_MSG_ERROR([recode extension can not be configured together with:$recode_conflict])
  fi
fi
