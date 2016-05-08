#
# Class::Singleton test script
#
# Andy Wardley <abw@wardley.org>
#

use strict;
use warnings;
use Test::More tests => 29;
use lib qw( lib ../lib );
use Class::Singleton;

# the final test is run by a destructor which is called after Test::Builder
# would normally print the test summary, so we disable that
Test::More->builder->no_ending(1);

ok(1, 'loaded Class::Singleton');

#------------------------------------------------------------------------
# define 'DerivedSingleton', a class derived from Class::Singleton 
#------------------------------------------------------------------------

package DerivedSingleton;
use base 'Class::Singleton';


#------------------------------------------------------------------------
# define 'AnotherSingleton', a class derived from DerivedSingleton 
#------------------------------------------------------------------------

package AnotherSingleton;
use base 'DerivedSingleton';

sub x {
    shift->{ x };
}


#------------------------------------------------------------------------
# define 'ListSingleton', which uses a list reference as its type
#------------------------------------------------------------------------

package ListSingleton;
use base 'Class::Singleton';

sub _new_instance {
    my $class  = shift;
    bless [], $class;
}


#------------------------------------------------------------------------
# define 'ConfigSingleton', which has specific configuration needs.
#------------------------------------------------------------------------

package ConfigSingleton;
use base 'Class::Singleton';

sub _new_instance {
    my $class  = shift;
    my $config = shift || { };
    my $self = {
        'one' => 'This is the first parameter',
        'two' => 'This is the second parameter',
        %$config,
    };
    bless $self, $class;
}

#-----------------------------------------------------------------------
# define 'DestructorSingleton' which has a destructor method
#-----------------------------------------------------------------------

package DestructorSingleton;
use base 'Class::Singleton';

sub DESTROY {
    main::ok(1, 'destructor called' );
}


#========================================================================
#                                -- TESTS --
#========================================================================

package main;

# call Class::Singleton->instance() twice and expect to get the same 
# reference returned on both occasions.

ok( ! Class::Singleton->has_instance(), 'no Class::Singleton instance yet' );

my $s1 = Class::Singleton->instance();
ok( $s1, 'created Class::Singleton instance 1' );

my $s2 = Class::Singleton->instance();
ok( $s2, 'created Class::Singleton instance 2' );

is( $s1, $s2, 'both instances are the same object' );
is( Class::Singleton->has_instance(), $s1, 'Class::Singleton has instance' );

# call MySingleton->instance() twice and expect to get the same 
# reference returned on both occasions.

ok( ! DerivedSingleton->has_instance(), 'no DerivedSingleton instance yet' );

my $s3 = DerivedSingleton->instance();
ok( $s3, 'created DerivedSingleton instance 1' );

my $s4 = DerivedSingleton->instance();
ok( $s4, 'created DerivedSingleton instance 2' );

is( $s3, $s4, 'both derived instances are the same object' );
is( DerivedSingleton->has_instance(), $s3, 'DerivedSingleton has instance' );


# call MyOtherSingleton->instance() twice and expect to get the same 
# reference returned on both occasions.

my $s5 = AnotherSingleton->instance( x => 10 );
ok( $s5, 'created AnotherSingleton instance 1' );
is( $s5->x, 10, 'first instance x is 10' );

my $s6 = AnotherSingleton->instance();
ok( $s6, 'created AnotherSingleton instance 2' );
is( $s6->x, 10, 'second instance x is 10' );

is( $s5, $s6, 'both another instances are the same object' );


#------------------------------------------------------------------------
# having checked that each instance of the same class is the same, we now
# check that the instances of the separate classes are actually different 
# from each other 
#------------------------------------------------------------------------

isnt( $s1, $s3, "Class::Singleton and DerviedSingleton are different");
isnt( $s1, $s5, "Class::Singleton and AnotherSingleton are different");
isnt( $s3, $s5, "DerivedSingleton and AnotherSingleton are different");


#------------------------------------------------------------------------
# test ListSingleton
#------------------------------------------------------------------------

my $ls1 = ListSingleton->instance();
ok( $ls1, 'created ListSingleton instance 1' );

my $ls2 = ListSingleton->instance();
ok( $ls2, 'created ListSingleton instance 2' );

is( $ls1, $ls2, 'both list instances are the same object' );
ok( $ls1 =~ /ARRAY/, "ListSingleton is a list reference");



#------------------------------------------------------------------------
# test ConfigSingleton
#------------------------------------------------------------------------

# create a ConfigSingleton
my $config = { 'foo' => 'This is foo' };
my $cs1 = ConfigSingleton->instance($config);
ok( $cs1, 'created ConfigSingleton instance 1' );

# add another parameter to the config
$config->{'bar'} = 'This is bar';

# shouldn't call new() so changes to $config shouldn't matter
my $cs2 = ConfigSingleton->instance($config);
ok( $cs2, 'created ConfigSingleton instance 2' );

is( $cs1, $cs2, 'both config instances are the same object' );
is( scalar(keys %$cs1), 3, "ConfigSingleton 1 has 3 keys");
is( scalar(keys %$cs2), 3, "ConfigSingleton 2 has 3 keys");


#-----------------------------------------------------------------------
# test DestructorSingleton
#-----------------------------------------------------------------------

my $ds1 = DestructorSingleton->instance();





