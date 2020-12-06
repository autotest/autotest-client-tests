/*
 * aio_bug.c
 * http://www.kvack.org/~bcrl/20140824-aio_bug.c
 * Introduced by:
 *   f8567a3845ac05bb28f3c1b478ef752762bd39ef
 * Fixed by:
 *   d856f32a86b2b015ab180ab7a55e455ed8d3ccc5
 *
 * Copyright (C) 2014, Dan Aloni, Kernelim Ltd.
 * Copyright (C) 2014, Benjamin LaHaise <bcrl@kvack.org>.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 */
#define _GNU_SOURCE 1

#include <assert.h>
#include <errno.h>
#include <libaio.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>

int max_ios = 128;
const int max_events = 32;
const int io_size = 0x1000;
io_context_t io_ctx;
struct iocb *io;
struct iocb **iops;
struct iovec *iovecs;
struct io_event *events;
char *data;

long submitted = 0;
long completed = 0;
long pending = 0;

int use_user_getevents = 0;

struct aio_ring {
	unsigned	id;	/* kernel internal index number */
	unsigned	nr;	/* number of io_events */
	volatile unsigned	head;
	volatile unsigned	tail;

	unsigned	magic;
	unsigned	compat_features;
	unsigned	incompat_features;
	unsigned	header_length;	/* size of aio_ring */

	struct io_event io_events[0];
};

int user_getevents(io_context_t ctx, int nr_events, struct io_event *event)
{
	struct aio_ring *ring = (void *)ctx;
	int completed = 0;
	while ((completed < nr_events) && (ring->head != ring->tail)) {
		unsigned new_head = ring->head;
		*event = ring->io_events[new_head];
		new_head += 1;
		new_head %= ring->nr;
		ring->head = new_head;
		completed++;
	}
	return completed;
}

void prune(void)
{
	int ret;

	if (use_user_getevents)
        	ret = user_getevents(io_ctx, max_ios, events);
	else
        	ret = io_getevents(io_ctx, pending, max_ios, events, NULL);
	if (ret > 0) {
		printf("Completed: %d\n", ret);
		completed += ret;
		pending -= ret;
	}
}

void usage(char *progname)
{
	printf("Usage: %s [--user_getevents] [--max-ios=NR]\n", progname);
}

int main(int argc, char **argv)
{
	int ret;
	int fd;
	const char *filename = "aio_bug_temp";
	long i, to_submit;
	struct iocb **iocb_sub;

	for (i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "--user_getevents"))
			use_user_getevents = 1;
		else if (!strncmp(argv[i], "--max-ios=", 10)) {
			max_ios = atoi(argv[i] + 10);
			if ((max_ios < 1) || (max_ios >= 1000000)) {
				printf("Invalid value for max_ios: %d\n",
					max_ios);
				exit(1);
			}
			printf("max_ios=%d\n", max_ios);
		} else {
			printf("Invalid argument %s\n", argv[i]);
			usage(argv[0]);
			exit(1);
		}
	}

	io = calloc(max_ios, sizeof(*io));
	iops = calloc(max_ios, sizeof(*iops));
	iovecs = calloc(max_ios, sizeof(*iovecs));
	events = calloc(max_ios, sizeof(*events));

	ret = io_setup(max_events, &io_ctx);
	assert(!ret);

	unlink(filename);
	fd = open(filename, O_CREAT | O_RDWR | O_DIRECT, 0644);
	assert(fd >= 0);

	ret = ftruncate(fd, max_ios * io_size);
	assert(!ret);

	data = mmap(NULL, io_size * max_ios, PROT_READ | PROT_WRITE,
		    MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	assert(data != MAP_FAILED);

	for (i = 0; i < max_ios; i++) {
		iops[i] = &io[i];
		io[i].data = io;
		iovecs[i].iov_base = &data[io_size * i];
		iovecs[i].iov_len = io_size;
		io_prep_preadv(&io[i], fd, &iovecs[i], 1, 0);
	}

	to_submit = max_ios;
	iocb_sub = iops;

	while (submitted < max_ios) {
		printf("Submitting: %ld\n", to_submit);

		ret = io_submit(io_ctx, to_submit, iocb_sub);
		if (ret >= 0) {
			printf("Submitted: %d\n", ret);
			submitted += ret;
			iocb_sub += ret;
			pending += ret;
			to_submit -= ret;
		} else {
			if (ret == -EAGAIN) {
				printf("Submitted too much, that's okay\n");
				prune();
			}
		}
	}

	prune();
	io_destroy(io_ctx);

	close(fd);

	printf("Verifying...\n");

	assert(completed == submitted);

	printf("OK\n");

	return 0;
}

/*
 *
 * Good output:
 *
 *   Submitting: 128
 *   Submitted: 126
 *   Submitting: 2
 *   Submitted too much, that's okay
 *   Completed: 126
 *   Submitting: 2
 *   Submitted: 2
 *   Completed: 2
 *   Verifying...
 *   OK
 *
 * Bad output:
 *
 *   Submitting: 128
 *   Submitted: 128
 *   <program stuck, IO/s swallowed>
 *
 */
