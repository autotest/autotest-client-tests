use strict;

sub gen {
	my ($domain) = @_;

	my $messages;
	unless (open(LOCALE, "locale|")) {
		doskip();
	}
	while (<LOCALE>) {
		if (/^LC_MESSAGES=\"(.*)\"$/) {
			$messages = $1;
			last;
		} elsif (/^LC_MESSAGES=(.*)$/) {
			$messages = $1;
		}
	}
	close LOCALE;
	if ($? != 0) {
		doskip();
	}

	if ($messages eq 'C') {
		skip("cannot run test in the C locale", 0);
		exit 0;
	}
	if ($messages eq 'POSIX') {
		skip("cannot run test in the POSIX locale", 0);
		exit 0;
	}

	mkdir "test_data/" . $messages, 0755 unless (-d "test_data/" . $messages);
	mkdir "test_data/" . $messages . "/LC_MESSAGES", 0755
		unless (-d "test_data/" . $messages . "/LC_MESSAGES");
	unless (-r ("test_data/" . $messages . "/LC_MESSAGES/" . $domain . ".mo")) {
		system "msgfmt", "-o", "test_data/" . $messages . "/LC_MESSAGES/" .
			$domain . ".mo",
			"test_data/" . $domain . ".po";
		if ($? != 0) {
			doskip();
		}
	}
}

sub doskip {
	skip("could not generate test data, skipping test", 0);
	exit 0;
}

1;
