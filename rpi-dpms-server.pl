#!/usr/bin/perl

#
# Raspberry Pi "DPMS" like tcp/ip server
#
# Version 0.1
#

use POSIX 'setsid';
use IO::Socket;

##
# Signals to Trap and Handle
##
$SIG{'INT' } = 'interrupt';
$SIG{'HUP' } = 'interrupt';
$SIG{'ABRT'} = 'interrupt';
$SIG{'QUIT'} = 'interrupt';
$SIG{'TRAP'} = 'interrupt';
$SIG{'STOP'} = 'interrupt';
$SIG{'TERM'} = 'interrupt';
#ignore child processes to prevent zombies
$SIG{CHLD} = 'IGNORE';

# setup variables
my $PORT = 9102;
my $pidfile = "/var/run/rpi-dpms-server.pid";

#
# Daemonize
#
sub daemonize {
    chdir '/'                 or die "Can't chdir to /: $!";
    open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
    open STDOUT, '>>/dev/null' or die "Can't write to /dev/null: $!";
    open STDERR, '>>/dev/null' or die "Can't write to /dev/null: $!";
    defined(my $pid = fork)   or die "Can't fork: $!";
    exit if $pid;
    setsid                    or die "Can't start a new session: $!";
    umask 0;
    #write pidfile
    open (PIDFILE, '>' . $pidfile);
    print PIDFILE $$ . "\n";
    close (PIDFILE); 
}

#
# Standard trim
#
sub trim($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

##
# Interrupt: Simple interrupt handler
##
sub interrupt {
    die;
}


#
# Client service function
#
sub serviceClient {
    my $client = $_[0];
    while ( $line = <$client> ) {
	if ($line =~ /SLEEP/i) {
	    system("/opt/vc/bin/tvservice -o");
	    print $client "OK";
	    close $client;
	    exit(0);
	}
	if ($line =~ /WAKE/i) {
	    system("/opt/vc/bin/tvservice -p");
		system("fbset -depth 8");
		system("fbset -depth 16");
		system("chvt 6");
		system("chvt 7");
	    print $client "OK";
	    close $client;
	    exit(0);
	}
    }
    return;
}


#
# MAIN
#

$server = IO::Socket::INET->new(Proto     => 'tcp',
				timeout => "10",
				LocalPort => $PORT,
				Listen    => SOMAXCONN,
				Reuse     => 1);

die $log->error("Can't setup server") unless $server;

&daemonize();

while ($client = $server->accept()) 
{

    my $child;
    # perform the fork or exit
    die "Can't fork: $!" unless defined ($child = fork());
    if ($child == 0)
    {   #i'm the child!

        #close the child's listen socket, we dont need it.
        $server->close;

        #call the main child rountine
		serviceClient($client);

        #if the child returns, then just exit;
        exit 0;
    } 
    else
    {   #i'm the parent!

        #close the connection, the parent has already passed
        #   it off to a child.
        $client->close();

    }
    #go back and listen for the next connection!
}