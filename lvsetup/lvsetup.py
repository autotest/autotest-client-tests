"""
Test that automatically takes shapshots from existing logical volumes
or creates them using a given policy.

For details about the policy see below.
"""

from autotest.client import test, lv_utils
from autotest.client.shared import error


class lvsetup(test.test):
    """
    Test class inheriting from test with main method run_once().
    """
    version = 1

    def run_once(self, vg_name='autotest_vg', lv_name='autotest_lv',
                 lv_size='1G', lv_snapshot_name='autotest_sn',
                 lv_snapshot_size='1G',
                 # size in MB
                 ramdisk_vg_size = "40000",
                 ramdisk_basedir = "/tmp",
                 ramdisk_sparse_filename = "virtual_hdd",
                 override_flag=0):
        """
        General logical volume setup.

        The main part of the lvm setup checks whether the provided volume group
        exists and if not, creates one from the ramdisk. It then creates a logical
        volume if there is no logical volume, takes a snapshot from the logical
        if there is logical volume but no snapshot, and merges with the snapshot
        if both the snapshot and the logical volume are present.

        @param vg_name: Name of the volume group.
        @param lv_name: Name of the logical volume.
        @param lv_size: Size of the logical volume as string in the form "#G"
                (for example 30G).
        @param lv_snapshot_name: Name of the snapshot with origin the logical
                volume.
        @param lv_snapshot_size: Size of the snapshot with origin the logical
                volume also as "#G".
        @param override_flag: Flag to override default policy. Override flag
                can be set to -1 to force remove, 1 to force create, and 0
                for default policy.
        """
        # if no virtual group is defined create one based on ramdisk
        if not lv_utils.vg_check(vg_name):
            lv_utils.vg_ramdisk(vg_name, ramdisk_vg_size,
                                ramdisk_basedir,
                                ramdisk_sparse_filename)

        # if no snapshot is defined start fresh logical volume
        if override_flag == 1 and lv_utils.lv_check(vg_name, lv_name):
            lv_utils.lv_remove(vg_name, lv_name)
            lv_utils.lv_create(vg_name, lv_name, lv_size)
        elif override_flag == -1 and lv_utils.lv_check(vg_name, lv_name):
            lv_utils.lv_remove(vg_name, lv_name)
        else:

            # perform normal check policy
            if (lv_utils.lv_check(vg_name, lv_snapshot_name)
                and lv_utils.lv_check(vg_name, lv_name)):
                lv_utils.lv_revert(vg_name, lv_name, lv_snapshot_name)
                lv_utils.lv_take_snapshot(vg_name, lv_name,
                                          lv_snapshot_name,
                                          lv_snapshot_size)

            elif (lv_utils.lv_check(vg_name, lv_snapshot_name)
                  and not lv_utils.lv_check(vg_name, lv_name)):
                raise error.TestError("Snapshot origin not found")

            elif (not lv_utils.lv_check(vg_name, lv_snapshot_name)
                  and lv_utils.lv_check(vg_name, lv_name)):
                lv_utils.lv_take_snapshot(vg_name, lv_name,
                                          lv_snapshot_name,
                                          lv_snapshot_size)

            else:
                lv_utils.lv_create(vg_name, lv_name, lv_size)
