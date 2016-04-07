#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }

use Locale::gettext;
bindtextdomain("foo", "dirname");
if ((bindtextdomain("foo") eq 'dirname') &&
	(bindtextdomain("foo") eq 'dirname')) {
		ok(1);
} else {
print "[", bindtextdomain("foo"), "]\n";
		ok(0);
}
exit;
__END__
