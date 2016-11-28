/*
 * Suzuki K P <suzuki@in.ibm.com>
 * Wrapper for utempter:
 *  utempter expects the stdin to be a master end of pty.
 *  So we need to create one in our wrapper and use it as the stdin
 *  for the utempter.
 *  This wrapper will do the following :
 *   * create a master pty, print the name of the pty to stdou
 *   * do a utempter add
 *   * verify the add by doing a who
 *   * do a utempter dele
 *   * verify the del by doing a who
 *
 *   We have to do the "who" from the wrapper to avoid synchronization between
 *   the utempter.sh and the wrapper.
 *
 *   The output of the utempter goes to stdout/stderr
 *   We need separate files for the output of "who" so our caller
 *   can verify if the "add" and "del" were successful.
 *
 *   So the invocation of this utility is :
 *
 *   argv[0] <file_for_1st_who> <file_for_2nd_who>
 *
 *   For eg: ut_wrapper $TCTMP/who.1 $TCTMP/who.2
 */


#define _XOPEN_SOURCE 600
#define _GNU_SOURCE  		/* For ptsname_r */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <errno.h>

#include <sys/types.h>
#include <termios.h>

#define PTSNAME_BUFLEN 32

#ifndef posix_openpt
int posix_openpt(int flags)
{
	return open("/dev/ptmx", flags);
}
#endif

/* find the first pty master device that available */
int ptym_open(char *pts_name)
{
	int fdm;
	int ret;

	if ((fdm = posix_openpt(O_RDWR)) < 0) {
		perror ("ut_wrapper : posix_openpt:");
		return -1;
	}

	ret =  ptsname_r(fdm, pts_name, PTSNAME_BUFLEN);
	if (ret) {
		perror ("ut_wrapper : ptsname");
		close(fdm);
		return -1;
	}

	printf("PTS %s\n", pts_name);
	fflush (stdout);
	return fdm;	
}
/*
 * spawn_utempter : execute the utempter with @arg as a new process
 * The "fd" will be the stdin for the utempter.
 * Wait for the child process and verify the exit status
 */
int spawn_utempter (int fd, char *arg)
{
	pid_t pid;
	int status;

	pid = fork();

	switch (pid) {
		case  -1: /* Error */
			return -1;
		case 0: /* Child 
			 * stdin is fd->0
			 */
			dup2(fd,0);
			if (execlp("utempter", "utempter", arg, NULL) == -1)
				return -1;
			/* Doesn't reach here */
		default:  /* Parent */
			if (waitpid(pid, &status, 0) == pid) {
				int rc = WIFEXITED(status) ? WEXITSTATUS(status) : 0;
				if (rc)
					fprintf(stderr, "utempter %s failed with rc=%d\n",
						arg, rc);
				return rc;
			} else {
				fprintf(stderr, "ut_wrapper: waitpid failed to wait for %d\n",
						pid);
				return -1;
			}
	}
}
/* Similar to spawn_utempter, except the stdout is changed to outfd */
int spawn_who(int outfd)
{
	pid_t pid;
	int status;

	pid = fork();

	switch (pid) {
		case  -1: /* Error */
			return -1;
		case 0: /* Child 
			 * stdout is fd->1
			 */
			dup2(outfd,1);
			if (execlp("who" , "who", NULL) == -1)
				return -1;
			/* Doesn't reach here */
		default:  /* Parent */
			if (waitpid(pid, &status, 0) == pid) {
				int rc = WIFEXITED(status) ? WEXITSTATUS(status) : 0;
				if (rc)
					fprintf(stderr, "who failed with rc=%d\n", rc);
				return rc;
			} else {
				fprintf(stderr, "ut_wrapper: waitpid failed to wait for %d\n",
						pid);
				return -1;
			}
	}
}

/* Open/Create the file @path.
 * Returns the fd, if successful.
 * Exits on error
 */
int open_output_file(char *path)
{
	int fd;
	
	fd = open (path, O_WRONLY|O_CREAT,(S_IRUSR | S_IWUSR));
	if (fd < 0) {
		fprintf(stderr, "oepn : %s failed \n",path);
		exit (1);
	}
	return fd;
}

int main(int argc, char *argv[])
{
	char pts_name[PTSNAME_BUFLEN];
	int pts_master;
	int fd1, fd2; /* For "who"'s output */
	int rc = 0;

	if (argc < 3) {
		fprintf (stderr, "Usage: %s file1 file2\n",
				argv[0]);
		exit(1);
	}

	fd1 = open_output_file(argv[1]);
	fd2 = open_output_file(argv[2]);

	/* STEP 1: Create the pty device */
	if ((pts_master = ptym_open(pts_name)) < 0) {
		fprintf(stderr, "ptym_open failed, exiting..\n");
		rc = 1;
		goto out;
	}

	/* STEP 2: Add an entry */
	if (spawn_utempter(pts_master, "add") != 0) {
		rc = 1; goto out;
	}

	/* STEP 3: "who" for our caller to verify if the entry was added */
	(void)spawn_who(fd1);

	/* STEP 4: Delete the entry */
	if (spawn_utempter(pts_master, "del") != 0) {
		rc = 1 ;  goto out;
	}

	/* STEP 5: "who" to verify the deletion */
	(void)spawn_who(fd2);

out:
	close(pts_master);
	close (fd1);
	close (fd2);
	exit(rc);
}
