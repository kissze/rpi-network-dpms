#!/usr/bin/perl

# Example client script for rpi-dpms-server.pl server
# It built for RaspberryPi based LTSP clients

use IO::Socket;
use threads;

my $server = $ENV{LTSP_CLIENT};
my $port = 9102;
# dpm timeout in seconds
my $dpms_sleep_timeout = 1800;

sub waiter_msg {
    my $message = shift;
    my $wait = shift;
    $SIG{'KILL'} = sub { threads->exit(); };
    sleep($wait);
    send_message($message);
    threads->exit();
}

sub send_message {
    my $message = shift;
    # Thread 'cancellation' signal handler
    $socket = new IO::Socket::INET (
	PeerAddr  => $server,
	PeerPort  =>  $port,
	Proto => 'tcp',
    ) or die "Couldn't connect to Server\n";
    $socket->send($message . "\n\r");
    $socket->close;
}

my $blanked = 0; 
my $thr;

open (IN, "xscreensaver-command -watch |"); 
while (<IN>) { 
    if (m/^(BLANK|LOCK)/) { 
	if (!$blanked) { 
	    # start the "timer thread"
	    $thr = threads->create(\&waiter_msg,"SLEEP",$dpms_sleep_timeout);
	    $blanked = 1;
	    $thr->detach;
	}
    } elsif (m/^UNBLANK/) {
	    # if any thread exists then kill it, then send WAKE if the client in SLEEP
	    if ($thr->is_running()) {
			$thr->kill('KILL');
			$blanked = 0;
			my $thr;
	    }
	    if ($blanked) {
		send_message("WAKE");
		$blanked = 0;
	    }
	}
}