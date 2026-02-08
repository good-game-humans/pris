#! /usr/bin/perl -w
#
# elbow.pl
# Victor Liu - mailto:victor@n-gon.com
#
# Accepts request from Pipe applet.
# Several modes of operation, determined by CGI param 'req'
#  =register    Registers this particular applet, and may open the throttle. 
#  =data        Retrieves the data stream.
#  =unregister  Unregisters this applet, and may close the throttle.
# Applet must also send unique ID (CGI param 'id').
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

use File::Find;
use FindBin qw($Bin);
use IO::Socket;

my $SENDMAIL        = '/usr/sbin/sendmail';

#my $SOCK_ADDR       = 'localhost';          # For roy
my $SOCK_ADDR       = 'pris.dyndns.org';    # For ngon
my $SOCK_PORT       = 9001;

my $REGISTRY_DIR    = "$Bin/registry";
my $LINES_DIR       = "$Bin/lines";
my $TIMESTAMP_INCR  = 5;
my $N_SCREEN_LINES  = 24;
my $DEMARC          = "\n-=BEAT=-\n";
my $RESTING_FILE    = "$Bin/resting";
my $RESTING_MSG     = "pris is resting";
my $REBOOTING_FILE  = "$Bin/rebooting";
my $REBOOTING_MSG   = "pris is rebooting";

my $ID;
my $Request;

###############################################################################
# Begin MAIN                                                                  #

&get_form_data;
for ($Request) {
    /^register$/   && do { &register;               last; };
    /^screen$/     && do { &retrieve_screen;        last; };
    /^data$/       && do { &retrieve_datastream;    last; };
    /^unregister$/ && do { &unregister;             last; };
}
exit;

# End of MAIN                                                                 #
###############################################################################

sub get_form_data {
    &parse_form_data(*dat);
    $ID = $dat{'id'};
    $Request = $dat{'req'};
}

##
# Add applet's ID to register.
# Open throttle if necessary.
#
sub register {
    my $id = &generate_id;
    
    open(REGISTER, ">$REGISTRY_DIR/$id") or die $!;
    close(REGISTER);
    
    if (not &is_throttle_open) {
        if (not &open_throttle) {
            $id = 'ERROR: Couldn\'t open throttle.';
        }
    }
    
    &print_text($id);
}

##
# Use $ENV{REMOTE_ADDR} and current time to create a unique id.
#
sub generate_id {
    return $ENV{REMOTE_ADDR}.','.(time);
}

##
# Close throttle, but first check existence of recently updated registry
# items, meaning others could be waiting.
#
sub unregister {
    my $throttle_status;
    unless (&is_recent(&find_youngest_registry_file_not_me($ID), 60)) {
        if (&close_throttle) {
            $throttle_status = 'Throttle has been closed.';
        } else {
            $throttle_status = 'Couldn\'t close throttle.';
        }
    } else {
        $throttle_status = 'Throttle remains open.';
    }
    &print_text($throttle_status);
}

##
# Look for latest data timestamp for this applet and return 
# associated file's contents.
#
sub retrieve_datastream {
    if (&is_pris_resting) {
        return print_text($RESTING_MSG."\n".(${DEMARC}x5));
    }
    if (&is_pris_rebooting) {
        return print_text(("$REBOOTING_MSG\n$DEMARC")x5);
    }
    if (not &is_throttle_open) {
        &open_throttle;
    }
    
    my $timestamp;
    if (-f "$REGISTRY_DIR/$ID") {
        open(REGISTER, "<$REGISTRY_DIR/$ID");
        $timestamp = <REGISTER>; chomp $timestamp if $timestamp;
        close(REGISTER);
    }
    
    # If timestamp doesn't exist, look for latest data file. 
    # Else, look for latest data file after the timestamp.
    # In both cases, retrieve contents and send to applet, 
    # and write timestamp to register.
    my $file = $timestamp ? &find_file_after($timestamp)
                          : &find_youngest_file;
    my $bad_cnt;
    while (not &is_recent($file, 3600)) {
        # Block until have a recently modified file.
        sleep 1;
        if ($bad_cnt++ > 60) {
            print_text("Unsuccessful");
            # Clear timestamp, by setting $file = ''.
            $file = '';
            last;
        }
        $file = $timestamp ? &find_file_after($timestamp)
                           : &find_youngest_file;
    }
    
    ($timestamp = $file) =~ s|.+/lines/(\d\d/\d\d\d\d)\.txt$|$1|;
    open(REGISTER, ">$REGISTRY_DIR/$ID");
    print REGISTER "$timestamp\n";
    close(REGISTER);
    
    return unless $file;
    local $/;
    open(IN, "<$file") or die $!;
    my $buf = <IN>;
    close(IN);
    print_text($buf);
}

##
# Retrieve last screen-full of data.
#
sub retrieve_screen {
    if (&is_pris_resting) {
        return print_text(("$RESTING_MSG\n"x22).$RESTING_MSG);
    }
    if (&is_pris_rebooting) {
        return print_text(("$REBOOTING_MSG\n"x22).$REBOOTING_MSG);
    }
    if (not &is_throttle_open) {
        &open_throttle;
    }
    
    my $youngest_file = &find_youngest_file;
    
    # Block unless within last hour.
    my $bad_cnt;
    while (not &is_recent($youngest_file, 3600)) {
        sleep 1;
        if ($bad_cnt++ > 60) {
            print_text("Unsuccessful");
            # Clear timestamp, by setting $youngest_file = ''.
            $youngest_file = '';
            last;
        }
        $youngest_file = &find_youngest_file;
    }
    
    # Write timestamp of youngest file to registry.
    my $timestamp;
    ($timestamp = $youngest_file) =~ s|.+/lines/(\d\d/\d\d\d\d)\.txt$|$1|;
    open(REGISTER, ">$REGISTRY_DIR/$ID");
    print REGISTER "$timestamp\n";
    close(REGISTER);
    
    # Now loop through files, going backwards in time, adding lines until
    # we get a screen-full.
    return unless ($youngest_file && $timestamp);
    local $/;
    my $file = $youngest_file;
    my ($hh, $mm, $ss) = &parse_timestamp($timestamp);
    return unless (defined $hh && defined $mm && defined $ss);
    # Only check last hour's data.
    my @screen_lines = ();
    my $n_tries = 3600 / $TIMESTAMP_INCR;
    my $cnt;
    for ($cnt = 0; $cnt < $n_tries; $cnt++) {
        if (-f $file && &is_recent($file, 3600)) {
            open(IN, "<$file");
            my $buf = <IN>;
            close(IN);
            $buf =~ s/$DEMARC//go;
            unshift(@screen_lines, split(/\n/, $buf));
            if (@screen_lines >= $N_SCREEN_LINES-1) {
                while (@screen_lines > $N_SCREEN_LINES-1) {
                    shift(@screen_lines);
                }
                last;
            }
        }
        ($hh, $mm, $ss) = &decr_time($hh, $mm, $ss);
        $file = sprintf("$LINES_DIR/%02d/%02d%02d.txt", $hh, $mm, $ss);
    }
    if ($cnt == $n_tries) {
        print STDERR localtime, 
                     "Couldn't retrieve screen after $n_tries tries.\n";
        &send_warning_email;
    }
    print_text(join("\n", @screen_lines));
}

##
# Determines if throttle is open by looking for youngest file, 
# and checking whether it really is young.
#
sub is_throttle_open {
    return &is_recent(&find_youngest_file, 5); # Within last 5 secs.
}

sub open_throttle {
    return &send_to_socket('open');
}

sub close_throttle {
    # [20050513] Just leave it open.
    # return &send_to_socket('unopen');
}

sub send_to_socket {
    my $cmd = shift;
    return unless $cmd;
    my $socket = IO::Socket::INET->new(PeerAddr => $SOCK_ADDR,
                                       PeerPort => $SOCK_PORT,
                                       Proto    => 'tcp',
                                       Type     => SOCK_STREAM)
        or return 0;
    print $socket "$cmd\n";
    close($socket);
    return 1;
}

sub is_recent {
    my ($file, $since) = @_;
    return unless $file;
    $since ||= 300; # 5 minutes
    return ((stat($file))[9] >= time - $since);
}

##
# Use File::Find to find the youngest file.
#
sub find_youngest_file {
    my ($file, $age) = ('', -1);
    my $youngest_sub = 
        sub {
            return if -d $_;
            return if defined $age && $age > (stat($_))[9];
            $age = (stat($_))[9];
            $file = ${File::Find::name};
        };
    find($youngest_sub, $LINES_DIR); # For ngon
#    find({ wanted => $youngest_sub, follow_fast => 1 }, $LINES_DIR); # For roy
    return $file;
}

##
# Use File::Find to find the youngest file in the $REGISTRY_DIR,
# but not including me.
#
sub find_youngest_registry_file_not_me {
    my $me = shift;
    my ($file, $age) = ('', -1);
    my $youngest_not_me_sub = 
        sub {
            return if -d $_;
            return if $_ eq $me;
            return if defined $age && $age > (stat($_))[9];
            $age = (stat($_))[9];
            $file = ${File::Find::name};
        };
    find($youngest_not_me_sub, $REGISTRY_DIR);
    return $file;
}

##
# Find file coming after the given file.
#
sub find_file_after {
    my $given = shift;
    my ($hh, $mm, $ss) = &parse_timestamp($given);
    return undef unless (defined $hh && defined $mm && defined $ss);
    ($hh, $mm, $ss) = &incr_time($hh, $mm, $ss);
    my $file = sprintf("%02d/%02d%02d.txt", $hh, $mm, $ss);
    if (-f "$LINES_DIR/$file") {
        return "$LINES_DIR/$file";
    } else {
        return undef;
    }
}

##
# Files are of the form HH/MMSS.
#
sub parse_timestamp {
    my $timestamp = shift;
    $timestamp =~ m|(\d\d)/(\d\d)(\d\d)|;
    return ($1, $2, $3);
}

sub incr_time {
    my ($hh, $mm, $ss) = @_;
    $ss += $TIMESTAMP_INCR;
    if ($ss == 60) { 
        $ss = 0;
        $mm += 1;
        if ($mm == 60) {
            $mm = 0;
            $hh += 1;
            if ($hh == 24) {
                $hh = 0;
            }
        }
    }
    return ($hh, $mm, $ss);
}

sub decr_time {
    my ($hh, $mm, $ss) = @_;
    $ss -= $TIMESTAMP_INCR;
    if ($ss < 0) { 
        $ss += 60;
        $mm -= 1;
        if ($mm == -1) {
            $mm = 59;
            $hh -= 1;
            if ($hh == -1) {
                $hh = 23;
            }
        }
    }
    return ($hh, $mm, $ss);
}

sub is_pris_resting {
    return -f $RESTING_FILE;
}

sub is_pris_rebooting {
    return -f $REBOOTING_FILE;
}

sub send_warning_email {
    open(MAIL, "| $SENDMAIL victor\@n-gon.com");
    print MAIL "From: elbow\@n-gon.com\n";
    print MAIL "Subject: NO ACTIVITY\n\n";
    print MAIL "No recent updates from pris.\n";
    close(MAIL);
}

##
# CGI routines.
#
sub parse_form_data {
    local(*FORM_DATA) = @_;
    local($request_method, $query_string, @pairs, $key_value, $key, $value);

    $request_method = $ENV{'REQUEST_METHOD'} ? $ENV{'REQUEST_METHOD'} : '';
    $query_string = "";

    if ($request_method eq "GET") {
        $query_string = $ENV{'QUERY_STRING'};
    }
    elsif ($request_method eq "POST") {
        read(STDIN, $query_string, $ENV{'CONTENT_LENGTH'});
    }
    else {
        # Error
        # die("Unsupported REQUEST_METHOD:$request_method\n");
    }

    @pairs = split(/&/, $query_string);

    foreach $key_value (@pairs) {
        ($key, $value) = split (/=/, $key_value);
        $key =~ tr/+/ /;
        $key =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack("C", hex($1))/eg;
        $value =~ tr/+/ /;
        $value =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack("C", hex($1))/eg;

        # Prepare for pairs with multiple entries
        if (defined($FORM_DATA{$key})) {
            $FORM_DATA{$key} = join("\, ", $FORM_DATA{$key}, $value);
        }
        else {
            $FORM_DATA{$key} = $value;
        }
    }
}

sub print_text {
    print "Content-type: text/plain\n\n";
    print "$_[0]\n";
}

