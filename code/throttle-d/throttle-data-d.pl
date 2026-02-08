#!/usr/bin/perl
#
# throttle-data-d.pl
# Victor Liu - mailto:victor@n-gon.com
#
# Opens a port and attempts to get pris (via ssh) to tail her log to this port.
# After parsing, copies (via sftp) the files to n-gon.com.  Hence, the user
# running this script (proabably root) should have password-less access to 
# both roy and ngon.
#
# Copyright (C) 2004-2005 Victor Liu
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. 
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details. 
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

$| = 1;

use FindBin qw($Bin);
use IO::Select;
use Net::SSH::Perl;
use Socket;

$DEBUG     = 1;

$PORT      = 9000;
$INTERVAL  = 1;
$SCP_CNT   = 5;
$GRANULE   = $SCP_CNT * $INTERVAL;
$BUF_SZ    = 8192;
$DEMARC    = "\n-=BEAT=-\n";
$SCP_DEST = 'ngon@www.n-gon.com:public_html/pris';
$TAIL_CMD  = 'ssh -f -lroot pris /pris/pris-tail.sh';
#$SSH_LOGIN = 'root';
#$SSH_PASS  = 'REDACTED';
#$SSH_HOST  = 'pris';
#$TAIL_CMD  = '/pris/pris-tail.sh';
$IDLE_CNT  = 3600; # 60 mins
$REBOOT_T  = 180;
$SENDMAIL  = '/usr/sbin/sendmail';

###############################################################################
# Begin MAIN                                                                  #

do {
    &init_sock;
    &init_tail;
} while (&main);
exit;

# End of MAIN                                                                 #
###############################################################################

sub init_sock {
    # Set up tcp server (see Perl Cookbook 17.2)
    socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
    setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
    bind(SERVER, sockaddr_in($PORT, INADDR_ANY))
        or die "Couldn't bind to port $PORT : $!\h";
    listen(SERVER, SOMAXCONN)
        or die "Couldn't listen on port $PORT : $!\n";
}

sub init_tail {
    my $pid;
    if ($pid = `ps -C '$TAIL_CMD' -o pid=`)
      system "kill $pid";
    system $TAIL_CMD;
    my $st = ($? >> 8);
#    print STDERR "\$? = $?, \$st = $st\n";
    while ($st) {
        print STDERR "Failed tail command: $!\n";
        # pris may be rebooting, sleep for a bit.
        sleep $GRANULE;
        if ($pid = `ps -C '$TAIL_CMD' -o pid=`)
          system "kill $pid";
        system $TAIL_CMD;
        $st = ($? >> 8);
    }
}

sub init_tail_new {
    my $ssh = Net::SSH::Perl->new($SSH_HOST);
    $ssh->login($SSH_LOGIN, 'REDACTED');
    my ($stdout, $stderr, $exit) = $ssh->cmd($TAIL_CMD);
    while ($stderr) {
        print STDERR $stderr; 
        # pris may be rebooting, sleep for a bit.
        sleep 5;
        ($stdout, $stderr, $exit) = $ssh->cmd($TAIL_CMD);
    }
}

sub main {
    while (my $client_address = accept(CLIENT, SERVER)) {
        my ($client_port, $client_packed_ip) = sockaddr_in($client_address);
        my $client_dotted_quad = inet_ntoa($client_packed_ip);
        print '['.(localtime)."] Client $client_dotted_quad accepted by $0\n";
        my $sel = new IO::Select(\*CLIENT);
        my $t0 = time + $INTERVAL;
        my $cnt = 0;
        my $pris_idle_cnt = 0;
        my $read_buf;
        my $out_buf;
        while (1) {
            if ($sel->can_read($INTERVAL)) {
                my $n_read = sysread(CLIENT, $read_buf, $BUF_SZ);
                # Check close of socket by reading 0 bytes.
                unless ($n_read) {
                    print "[".(localtime)."] Client unconnected\n";
                    $sel->remove(*CLIENT);
                    close CLIENT;
                    sleep 60;
                    # Try re-opening connection by returning nonzero.
                    return 1;
                }
                unless (!defined($n_read) && $! == EAGAIN) {
                    # Remove / replace certain chars.
                    $read_buf =~ s/\t/ /go;
                    $read_buf =~ 
                        tr/a-zA-Z0-9,.\/<>?;':"[]\{}|`~!@#$%^&*()-=_+ \n//cd;
                    # (The following are console codes.)
                    $read_buf =~ s/\[0m|\[\d\d;01m//go;
                   
                    $out_buf .= $read_buf;
                    $pris_idle_cnt = 0 if $read_buf;
                }
            }
            if (time >= $t0) {
                # Print demarcation between intervals of text.
                $out_buf .= $DEMARC;
                $t0 += $INTERVAL;
                
                if (++$cnt >= $SCP_CNT) {
                    # Ready to transport.
                    # Create date string.
                    my ($sec, $min, $hr) = (localtime($t0))[0,1,2];
                    # Round to nearest grain.
                    $sec = ((int($sec/$GRANULE)) * $GRANULE); 
                    $path = sprintf "%02d", $hr;
                    my $filename = sprintf "%02d%02d.txt", $min, $sec;
                    my $file = "$Bin/lines/$path/$filename";
                    
                    # Replace right-align codes.  Can't do this previously
                    # since these codes span 2 lines, and hence may span
                    # more than one $read_buf.
                    $out_buf =~ s/\n($DEMARC)*\[A\[-7G/$1/go;
                    $out_buf =~ s/^\[A\[-7G//go;
                    
                    # Split output into lines of 80 chars or less.
                    $out_buf =~ s/(.{80})(?!\n)/$1\n/go;
                    
                    open(OUT, ">$file");
                    print OUT $out_buf;
                    close(OUT);
                    # NB: Push done by separate daemon.
                    # For bad traffic situations, backgrounding caused
                    # processes to pile up, and scp would eventually fail.
#                    system "scp $file $SCP_DEST/lines/$path/ \&";
#                    system "scp $file $SCP_DEST/lines/$path/";
                    
                    print $out_buf if $DEBUG;
                    $out_buf = '';
                    $cnt = 0;
                    
                    while (&is_resting) {
                        sleep $INTERVAL;
                        print "zzz\n" if $DEBUG;
                        $t0 += $INTERVAL;
                    }
                }
                
                if (++$pris_idle_cnt > $IDLE_CNT) {
                    print "IDLE for $IDLE_CNT ticks!  Restarting\n";
                    open(MAIL, "| $SENDMAIL victor\@n-gon.com");
                    print MAIL "From: throttle-data-d\@n-gon.com\n";
                    print MAIL "Subject: PRIS IDLE\n\n";
                    print MAIL "pris has been idle for $IDLE_CNT ticks.\n";
                    close(MAIL);
                    $sel->remove(*CLIENT);
                    close CLIENT;
                    return -1;
                }
            }
            
            print "In while(1)\n" if $DEBUG;
        }
        print "Waiting for accept\n" if $DEBUG;
    }
    return 0;
}

sub is_open {
    return -f "$Bin/open";
}

sub is_resting {
    return -f "$Bin/rest";
}

sub is_rebooting {
    return -f "$Bin/reboot";
}

