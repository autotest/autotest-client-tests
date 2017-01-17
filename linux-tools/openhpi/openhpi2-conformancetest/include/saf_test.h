/*
 * Copyright (c) 2004, Intel Corporation.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307 USA.
 *
 */


#ifndef SAF_TEST
#define SAF_TEST

#define SAF_TEST_PASS	0
#define SAF_TEST_FAIL	1
#define SAF_TEST_BLOCK	2
#define SAF_TEST_NOTSUPPORT	3
#define SAF_TEST_UNRESOLVED	4
#define SAF_TEST_UNKNOWN 5

#ifdef __AIS_A_TEST__
#include "aistest_a.h"
#endif

#ifdef __AIS_B_TEST__
#include "aistest_b.h"
#endif

#ifdef __HPI_A_TEST__
#include "hpitest_a.h"
#endif

#ifdef __HPI_B_TEST__
#include "hpitest_b.h"
#endif

#endif
