# $Id: test.pl,v 1.2 2002/07/14 16:33:41 marcus Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::Telnet::Netscreen;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use Term::ReadKey;
$^W = 1;

use constant PASS	  =>  1;
use constant FAIL	  =>  0;
use constant SKIP	  => -1;
use constant WEIRD_PASS	  => -2;

use vars qw/$FW $PASSWD $LOGIN $SESSION/;

my $i      = 1;
my $badbad = 0;

foreach my $cref ( qw(t2 t3 t4 t5 t6) ) {

    if ( ++$i >= 3 and not $SESSION ) {
	print "not ok $i\n";
	next;
    }

    my $ret = $cref->();

    if ( $ret == PASS ) {
	print "ok $i\n";
    } elsif ( $ret == FAIL or not defined $ret ) {
	print "not ok $i\n";
	$badbad = 1;
    } elsif ( $ret == SKIP ) {
	print "skipped $i\n";
    } elsif ( $ret == WEIRD_PASS ) {
	print "unexpected success $i\n";
    } else {
	die "test.pl may be broken. Bailing out.\n";
    }
}

$SESSION and $SESSION->close;

if ( $badbad ) {
    warn "test.pl experienced some problems. See test.log for details.\n";
} elsif ( -e "test.log" ) {
    unlink "test.log" or warn "Can't remove test.log: $!";
}

exit 0;

#------------------------------
# tests.
#------------------------------

sub t2 {
    print <<EOB;

Net::Telnet::Netscreen needs to log into a firewall
to perform it\'s full set to tests. To log in, we
need a test fw, a login, and a password. To
skip these tests, hit "return" at any point.

EOB

    print "\Firewall: ";
    $FW ||= <STDIN>;
    chomp $FW;
    return SKIP unless $FW;

    print "Login: ";
    $LOGIN ||= <STDIN>;
    chomp $LOGIN;
    return SKIP unless $LOGIN;

    print "Passwd: ";

    if ( $Term::ReadKey::VERSION ) {
	ReadMode( 'noecho' );
	$PASSWD ||= ReadLine(0);
	chomp $PASSWD;
	ReadMode( 'normal' );
	print "\n";
    } else {
	$PASSWD = <STDIN>;
	chomp $PASSWD;
    }

    return SKIP unless $PASSWD;

    $SESSION = Net::Telnet::Netscreen->new( Errmode   => 'return',	
					 Host	   => $FW,
					 Timeout   => 45,
					 Input_log  => 'test.log',
				      ) or return FAIL;

    my $ok = $SESSION->login( $LOGIN, $PASSWD );
    unless ( $ok ) {
	warn "Can't login to firewall with your login and pass.\n";
	return FAIL;
    }
    return PASS;
}

sub t3 {
    my @out = $SESSION->ping( 'www.perl.com' );
    return $SESSION->errmsg ? FAIL : PASS;
}

sub t4 {
    $SESSION->errmsg('');	# reset errmsg to noerr.
    my @out = $SESSION->getValue( 'domain' );
    return FAIL if $SESSION->errmsg;
    return @out ? PASS : FAIL;
}

sub t5 {
    my $success = undef;
    $SESSION->errmode( sub { $success = 1 } );
    my @out = $SESSION->cmd( 'asdmnbvzvctoiubqwerhgadfhg' );
    return $success ? PASS : FAIL;
}

sub t6 {
    my $ok = $SESSION->exit();
    return $ok ? PASS : FAIL;
}
