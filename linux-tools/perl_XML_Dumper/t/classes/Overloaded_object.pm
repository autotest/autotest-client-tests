use overload
	q{ "" }	=> sub { my $self = shift; return $self->value(); };
package Overloaded_object;
sub new { return bless { value => $_ }, 'Overloaded_object'; }

sub value { my $self = shift; return $self->{ value }; }
1;
