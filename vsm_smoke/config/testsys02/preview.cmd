# CIS preview.cmd template version 3.0
# Template file updated: Apr 24 2007 (Suitable for SAM-QFS 4.6)

# For additional information about the format of the preview.cmd file,
# type "man preview.cmd".
#

# Global priorities.
# Note: vsn_priority and age_priority are always global
# regardless of place in preview.cmd

vsn_priority = 2000.0
age_priority = 1.0

# CIS - give staging priority until you are above LWM,
#       then increase archiving priority
#       to minimize the chance of of staying above HWM.

# Define global High / Low Water Mark archiving priority for all filesystems

###  When FS below the LWM, decrease archiving priority in preference to stage
lwm_priority =  -1000.0

### When filling up, (between L and H) increase archiving versus
#       staging priority
lhwm_priority = 20000.0

### When emptying, (between H and L) increase archiving versus staging priority
hlwm_priority = 30000.0

# If above HWM, increase archiving priority
hwm_priority =  40000.0

# Define Water Mark priorities per filesystem

#fs = samqfs1
#lhwm_priority = 20000.0
#hlwm_priority = 30000.0
#hwm_priority =  40000.0

#fs = samqfs2
#lhwm_priority = 60000.0
#hlwm_priority = 70000.0
#hwm_priority =  80000.0
