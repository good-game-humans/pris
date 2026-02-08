#!/usr/bin/perl
#
# throttle-push-d.pl
# Victor Liu - mailto:victor@n-gon.com
#
# Pushes (via sftp) pris lines to applet's server.
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

use File::Find;
use FindBin qw($Bin);
use Net::SFTP;

$INTERVAL  = 1;
$SCP_CNT   = 5;
$GRANULE   = $SCP_CNT * $INTERVAL;
$SCP_DEST  = 'ngon@www.n-gon.com:public_html/pris';
$SFTP_HOST = 'www.n-gon.com';
$SFTP_USER = 'ngon';
$SFTP_PASS = 'REDACTED';
$SFTP_DEST = 'public_html/pris/lines';
$BURST_DATA_SZ = 80 * 24;
$LOG_DIR   = '/mnt/Media/Scratch/throttle-d/logs';

###############################################################################
# Begin MAIN                                                                  #

my $Callback_Called = 0;
$SIG{ALRM} = sub { die "timeout" };
&push_lines;
exit;

# End of MAIN                                                                 #
###############################################################################

sub push_lines {
    my $sftp = Net::SFTP->new($SFTP_HOST, 
                              user => $SFTP_USER, 
                              password => $SFTP_PASS);
    my $t0 = time; # current timestamp
    my $n_fails = 0;
LOOP:
    while (1) {
        # Rest if not ready.
        while (! &is_open || &is_resting || &is_rebooting) {
            sleep $GRANULE;
            print "zzz\n";
            undef $sftp;
            undef $t0;
        }
        
        # If waking up, re-initialize.
        if (not defined $sftp) {
            $sftp = Net::SFTP->new($SFTP_HOST, 
                                   user => $SFTP_USER, 
                                   password => $SFTP_PASS);
        }
        if (not defined $t0) {
            $t0 = time;
        }
        
        # If this is a newly opened throttle,
        # do a burst of files enough for a screen-full of text.
        if (! defined($Last_Push_T0) or 
                ($t0 - $Last_Push_T0 > 2 * $GRANULE)) { # do burst
            
            print "Burst\n";
            
            # Find most recent files in this hour's and last hour's paths.
            # Push enough of them to add up to a screen-full of data.
            my @burst_files = ();
            my $burst_files_sz = 0;
            my $order_by_rev_mtime = 
                sub {
                    return sort { (stat($b))[9] <=> (stat($a))[9] } @_;
                };
            my $find_burst = 
                sub {
                    return if $burst_files_sz > $BURST_DATA_SZ; # end cond
                    return if -d $_;
                    return if $t0 - (stat($_))[9] > 7200; # over 2 hrs old
                    my $sz = (stat($_))[7] - 50; # don't count demarc's
                    $sz = 0 if $sz < 0;
                    $burst_files_sz += $sz;
                    my $dir = substr($File::Find::dir, -2); # dir has form %02d
                    push(@burst_files, [ $dir, $_ ]);
                };
            my ($this_hr) = (localtime($t0))[2];
            find({ preprocess => $order_by_rev_mtime,
                   wanted => $find_burst }, 
                 "$Bin/lines/$this_hr");
            if ($burst_files_sz < $BURST_DATA_SZ) { # continue with prev hr
                my $prev_hr = sprintf("%02d", (($this_hr-1+24) % 24));
                find({ preprocess => $order_by_rev_mtime,
                       wanted => $find_burst }, 
                     "$Bin/lines/$prev_hr");
            }
            
            if (@burst_files > 0) {
                for (@burst_files) {
                    next unless @$_ == 2;
                    my ($hr, $file) = @$_;
                    next unless defined $hr and defined $file;
                    # Push.  Handle exceptions by die'ing.
                    print "  $hr/$file ";
                    $Callback_Called = 0; # only call callback once
                    eval {
                        alarm(30); # don't let this run longer than 30 sec
                        $sftp->put(
                            "$Bin/lines/$hr/$file", "$SFTP_DEST/$hr/$file", 
                            \&callback);
                        alarm(0);
                    };
                    if ($@) {
                        alarm(0);
                        die "$@";
                    }
                    print " pushed\n";
                }
            }
            
            $Last_Push_T0 = $t0; # ensures we don't burst next time
            next LOOP; # unnecessary, but clearer
        
        } else { # push file normally (not burst)
            
            # Look for file corresponding to current timestamp.
            my ($sec, $min, $hr) = (localtime($t0))[0,1,2];
            $sec = ((int($sec/$GRANULE)) * $GRANULE); # Round to nearest grain.
            my $path = sprintf "%02d", $hr;
            my $filename = sprintf "%02d%02d.txt", $min, $sec;
            my $file = "$Bin/lines/$path/$filename";
            
            print "$filename ";
            
            # Make sure the file is really newer than the timestamp.
            my $n_tries = 0;
            my $mtime;
            while (not (($mtime = (stat($file))[9]) && 
                        ($mtime >= $t0-$GRANULE))) {
                print ".";
                if ($n_tries++ > $SCP_CNT) {
                    # Throttle status may have changed.
                    if (! &is_open || &is_resting || &is_rebooting) { 
                        next LOOP;
                    }
                    print "Ack!\n";
                    if ($n_fails++ > 2) {
                        print "Restarting throttle-data-d\n";
                        &restart_data_d;
                        $n_fails = 0;
                        $t0 = time;
                    }
                    # Skip.
                    $t0 += $GRANULE;
                    next LOOP;
                }
                sleep 1;
            }
            
            # Ready to push.  Handle exceptions by die'ing.
            $Callback_Called = 0; # only call callback once
            eval {
                alarm(30); # don't let this run longer than 30 sec
                $sftp->put($file, "$SFTP_DEST/$path/$filename", \&callback);
                alarm(0);
            };
            if ($@) {
                alarm(0);
                die "$@";
            }
            
            print " pushed\n";
            
            $Last_Push_T0 = $t0;
            $t0 += $GRANULE; # advance to next timestamp
            sleep 1; # be nice
        }
    }
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

sub restart_data_d {
    system 'killall throttle-data-d.pl';
    system "$Bin/throttle-data-d.pl >>$LOG_DIR/data.log".' 2>&1 &';
}

sub callback {
    return if $Callback_Called; # only print this once per PUT
    my ($sftp, $data, $offset, $size) = @_;
    print "[$size]";
    $Callback_Called = 1;
}

