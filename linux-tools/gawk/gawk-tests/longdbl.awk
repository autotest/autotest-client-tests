# From arnold@f7.net  Wed Apr 27 09:48:37 2005
# Return-Path: <arnold@f7.net>
# Received: from localhost (skeeve [127.0.0.1])
# 	by skeeve.com (8.12.11/8.12.11) with ESMTP id j3R6mZVm015791
# 	for <arnold@localhost>; Wed, 27 Apr 2005 09:48:37 +0300
# Received: from pop.012.net.il [84.95.5.221]
# 	by localhost with POP3 (fetchmail-6.2.5)
# 	for arnold@localhost (single-drop); Wed, 27 Apr 2005 09:48:37 +0300 (IDT)
# Received: from mtain3.012.net.il ([10.220.5.7])
#  by i_mss3.012.net.il (HyperSendmail v2004.12)
#  with ESMTP id <0IFK00L1DIZ02530@i_mss3.012.net.il> for arobbins@012.net.il;
#  Tue, 26 Apr 2005 22:18:36 +0300 (IDT)
# Received: from VScan3 ([10.220.20.3])
#  by i_mtain3.012.net.il (HyperSendmail v2004.12)
#  with ESMTP id <0IFK007U1IZ0U980@i_mtain3.012.net.il> for arobbins@012.net.il
#  (ORCPT arobbins@012.net.il); Tue, 26 Apr 2005 22:18:36 +0300 (IDT)
# Received: from i_mtain1.012.net.il ([10.220.5.1])
#  by VScan3 with InterScan Messaging Security Suite; Tue,
#  26 Apr 2005 22:15:22 +0300
# Received: from f7.net ([209.61.216.22])
#  by i_mtain1.012.net.il (HyperSendmail v2004.12)
#  with ESMTP id <0IFK009SIIYRN7G0@i_mtain1.012.net.il> for arobbins@012.net.il;
#  Tue, 26 Apr 2005 22:18:33 +0300 (IDT)
# Received: (from arnold@localhost)	by f7.net (8.11.7-20030920/8.11.7)
#  id j3QJFAg18376	for arobbins@012.net.il; Tue, 26 Apr 2005 15:15:10 -0400
# Received: from fencepost.gnu.org (fencepost.gnu.org [199.232.76.164])
# 	by f7.net (8.11.7-20030920/8.11.7) with ESMTP id j3QJF5J18304	for
#  <arnold@skeeve.com>; Tue, 26 Apr 2005 15:15:06 -0400
# Received: from monty-python.gnu.org ([199.232.76.173])
# 	by fencepost.gnu.org with esmtp (Exim 4.34)
# 	id 1DQVVh-0004gD-CH	for bug-gawk@gnu.org; Tue, 26 Apr 2005 15:14:17 -0400
# Received: from Debian-exim by monty-python.gnu.org with spam-scanned
#  (Exim 4.34)	id 1DQVYa-0002PR-2b	for bug-gawk@gnu.org; Tue,
#  26 Apr 2005 15:17:56 -0400
# Received: from [129.183.4.8] (helo=ecfrec.frec.bull.fr)
# 	by monty-python.gnu.org with esmtp (Exim 4.34)
# 	id 1DQVYZ-0002Lr-EF	for bug-gawk@gnu.org; Tue, 26 Apr 2005 15:17:15 -0400
# Received: from localhost (localhost [127.0.0.1])
# 	by ecfrec.frec.bull.fr (Postfix) with ESMTP id 5782819D907	for
#  <bug-gawk@gnu.org>; Tue, 26 Apr 2005 21:12:53 +0200 (CEST)
# Received: from ecfrec.frec.bull.fr ([127.0.0.1])
#  by localhost (ecfrec.frec.bull.fr [127.0.0.1]) (amavisd-new, port 10024)
#  with ESMTP id 06763-10 for <bug-gawk@gnu.org>; Tue,
#  26 Apr 2005 21:12:51 +0200 (CEST)
# Received: from ecn002.frec.bull.fr (ecn002.frec.bull.fr [129.183.4.6])
# 	by ecfrec.frec.bull.fr (Postfix) with ESMTP id 4488B19D906	for
#  <bug-gawk@gnu.org>; Tue, 26 Apr 2005 21:12:51 +0200 (CEST)
# Received: from daphne ([129.183.192.6])
#  by ecn002.frec.bull.fr (Lotus Domino Release 5.0.12)
#  with ESMTP id 2005042621231613:3312 ; Tue, 26 Apr 2005 21:23:16 +0200
# Date: Tue, 26 Apr 2005 21:12:49 +0200 (CEST)
# From: Jean-Marc Saffroy <jean-marc.saffroy@ext.bull.net>
# Subject: GNU awk unable to handle 64-bit ints on IA64
# X-X-Sender: saffroyj@daphne.frec.bull.fr
# To: bug-gawk@gnu.org
# Message-id: <Pine.LNX.4.61.0504261916140.22370@daphne.frec.bull.fr>
# MIME-version: 1.0
# Content-type: TEXT/PLAIN; charset=US-ASCII; format=flowed
# X-MIMETrack: Itemize by SMTP Server on ECN002/FR/BULL(Release 5.0.12  |February
#  13, 2003) at 26/04/2005 21:23:16,
# 	Serialize by Router on ECN002/FR/BULL(Release 5.0.12  |February 13,
#  2003) at 26/04/2005 21:23:16,	Serialize complete at 26/04/2005 21:23:16
# X-Virus-Scanned: by amavisd-new at frec.bull.fr
# Original-recipient: rfc822;arobbins@012.net.il
# X-Spam-Checker-Version: SpamAssassin 2.63 (2004-01-11) on skeeve.com
# X-Spam-Level: 
# X-Spam-Status: No, hits=-4.9 required=5.0 tests=BAYES_00 autolearn=ham 
# 	version=2.63
# Status: RO
# 
# 
# Hello,
# 
# I have rounding problems when manipulating 64-bit ints (actually they are 
# addresses) on Linux/IA64:
# 
# $ echo 0xa000000100000813|./gawk '{printf("0x%lx\n",strtonum($1));}'
# 0xa000000100000800
# $ echo 0xffffffffffffffff|./gawk '{printf("0x%lx\n",strtonum($1));}'
# 0x8000000000000000
# $ ./gawk --version|head -1
# GNU Awk 3.1.4
# 
# The problem seems to be that AWKNUM is defined to be a double, which has a 
# 53-bit mantissa. On IA64 with gcc 3.2.3 (maybe other compilers as well) 
# there is a long double type with a larger mantissa:
# 
# $ grep define.*LDBL_MANT_DIG /usr/lib/gcc-lib/ia64-redhat-linux/3.2.3/include/float.h
# #define LDBL_MANT_DIG 64
# 
# So I changed AWKNUM to be a long double; this does not seem to be 
# sufficient, because of some dubious casts to double (there may be others 
# left, I didn't check), see patch below. Now it's much nicer:
# 
# $ echo 0xa000000100000813|./gawk '{printf("0x%lx\n",strtonum($1));}'
# 0xa000000100000813
# $ echo 0xffffffffffffffff|./gawk '{printf("0x%lx\n",strtonum($1));}'
# 0xffffffffffffffff
# 
# Maybe the gawk configure script should set AWKNUM to be a long double on 
# Linux/IA64?
# 
# 
# Regards,
# 
# -- 
# Jean-Marc Saffroy - jean-marc.saffroy@ext.bull.net
# 
# 
# diff -ru gawk-3.1.4/awk.h gawk/awk.h
# --- gawk-3.1.4/awk.h	2004-07-26 16:11:05.000000000 +0200
# +++ gawk/awk.h	2005-04-26 19:19:10.545419273 +0200
# @@ -273,7 +273,7 @@
#   /* ------------------ Constants, Structures, Typedefs  ------------------ */
# 
#   #ifndef AWKNUM
# -#define AWKNUM	double
# +#define AWKNUM	long double
#   #endif
# 
#   #ifndef TRUE
# diff -ru gawk-3.1.4/builtin.c gawk/builtin.c
# --- gawk-3.1.4/builtin.c	2004-07-13 09:55:28.000000000 +0200
# +++ gawk/builtin.c	2005-04-26 20:53:41.211365432 +0200
# @@ -578,7 +578,7 @@
#   	char *cend = &cpbuf[30];/* chars, we lose, but seems unlikely */
#   	char *cp;
#   	const char *fill;
# -	double tmpval;
# +	AWKNUM tmpval;
#   	char signchar = FALSE;
#   	size_t len;
#   	int zero_flag = FALSE;
# @@ -2773,16 +2773,16 @@
#   do_strtonum(NODE *tree)
#   {
#   	NODE *tmp;
# -	double d;
# +	AWKNUM d;
# 
#   	tmp = tree_eval(tree->lnode);
# 
#   	if ((tmp->flags & (NUMBER|NUMCUR)) != 0)
# -		d = (double) force_number(tmp);
# +		d = (AWKNUM) force_number(tmp);
#   	else if (isnondecimal(tmp->stptr))
#   		d = nondec2awknum(tmp->stptr, tmp->stlen);
#   	else
# -		d = (double) force_number(tmp);
# +		d = (AWKNUM) force_number(tmp);
# 
#   	free_temp(tmp);
#   	return tmp_number((AWKNUM) d);
# 
# 
# #####################################################################################
# This Mail Was Scanned by 012.net Anti Virus Service - Powered by TrendMicro Interscan
# 
{ printf("0x%lx\n",strtonum($1)); }
