#!/usr/bin/perl
#
# throttle-sgnl-d.pl
# Victor Liu - mailto:victor@n-gon.com
#
# Opens a port and listens to signals from either n-gon.com or pris.
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
use Socket;

$PORT     = 9001;

###############################################################################
# Begin MAIN                                                                  #

&init_sock;
&main;
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

sub main {
    while (my $client_address = accept(CLIENT, SERVER)) {
        my ($client_port, $client_packed_ip) = sockaddr_in($client_address);
        my $client_dotted_quad = inet_ntoa($client_packed_ip);
        print '['.(localtime)."] Client $client_dotted_quad accepted by $0\n";
        my $cmd = <CLIENT>; chomp $cmd;
        print " => $cmd\n";
        for ($cmd) {
            /^open$/   && &touch('open');
            /^unopen$/ && &untouch('open');
            # /^rest$/   && &touch_twice('rest') && &untouch('open');
            /^rest$/   && &touch_twice('rest');
            /^unrest$/ && &untouch_twice('rest');
#            /^unrest$/ && &untouch('rest'); # Good for testing on days of rest.
            /^reboot$/   && &touch_twice('reboot');
            /^unreboot$/ && &untouch_twice('reboot') && &restart_data_d;
        }
        print "Finished with command $cmd\n";
    }
}

sub touch_twice {
    my $cmd = shift;
    &touch($cmd);
    system "ssh -lngon www.n-gon.com touch public_html/pris/${cmd}ing";
}

sub untouch_twice {
    my $cmd = shift;
    &untouch($cmd);
    system "ssh -lngon www.n-gon.com rm public_html/pris/${cmd}ing";
}

sub touch {
    my $cmd = shift;
    return unless $cmd;
    open(TOUCH, ">$Bin/$cmd");
    close(TOUCH);
}

sub untouch {
    my $cmd = shift;
    return unless $cmd;
    unless (unlink("$Bin/$cmd")) {
        print "Couldn't remove $Bin/$cmd!\n";
    }
}

sub restart_data_d {
    system 'killall throttle-data-d.pl';
    system "$Bin/throttle-data-d.pl >>$Bin/logs/data.log".' 2>&1 &';
}

