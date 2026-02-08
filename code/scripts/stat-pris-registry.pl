#!/usr/bin/perl -w
#
# stat-registry.pl
# Victor Liu - mailto:victor@n-gon.com
#
# Script to stat registry of pris visitors. 

use FindBin qw($Bin);
use Getopt::Long;

my $REGISTRY_DIR    = "$Bin/registry";
my @IGNORE_IP_ADDRS = ( '66.108.18.34','209.191.132.162' );
my $SENDMAIL        = '/usr/sbin/sendmail';

my %Stats;
my $Cutoff_Time;    # Only stat (& clean) files before this time.
my $Do_Clean;       # Remove files as we go.
my @Files_To_Clean;

###############################################################################
# Begin MAIN                                                                  #

&get_args;
&get_stats;
&send_email;
&clean if $Do_Clean;
exit;

# End of MAIN                                                                 #
###############################################################################

sub get_args {
    my $cutoff = 0;
    &GetOptions('cutoff=i' => \$cutoff,
                'clean'    => \$Do_Clean);
    $Cutoff_Time = time - $cutoff;
}

sub get_stats {
    opendir(REGISTRY, $REGISTRY_DIR) or die $!;
    my @files = grep { /^[^\.]/ } readdir(REGISTRY);
    closedir(REGISTRY);
    
    for my $file (@files) {
        # Files are of the form '<ip-addr>,<visit-time>'.
        my ($ip_addr, $visit_time) = split(/,/, $file);
        my @inode = stat("$REGISTRY_DIR/$file") 
            or die "couldn't stat $file : $!";
        my $mtime = $inode[9];
        my $sz    = $inode[7];
        next if $mtime > $Cutoff_Time;
        unless (grep(/^$ip_addr$/, @IGNORE_IP_ADDRS)){
            push(@{ $Stats{$ip_addr} }, [ $visit_time, $mtime, $sz ]);
        }
        if ($Do_Clean and $visit_time) {
            push(@Files_To_Clean, $file);
        }
    }
    
    # Within an IP address, order visits.
    for my $ip_addr (keys %Stats) {
        my @visit_order = sort { $a->[0] <=> $b->[0] } @{ $Stats{$ip_addr} };
        $Stats{$ip_addr} = \@visit_order;
    }
}

sub send_email {
    open(MAIL, "| $SENDMAIL victor\@n-gon.com");
    print MAIL "From: stat-registry\@n-gon.com\n";
    print MAIL "Subject: pris registry\n\n";
    
    # Sort by first visit time, but group by IP address.
    my @ip_order = sort { $Stats{$a}->[0]->[0] <=> $Stats{$b}->[0]->[0] }
                        keys %Stats;
    my $format = "%-16s %-25s %-25s %8s %2s\n";
    printf MAIL $format, 'IP address', 
                         'Visit time', 
                         'Depart time',
                         'Elapsed',
                         'Sz';
    for my $ip_addr (@ip_order) {
        my $i = 0;
        for my $visit (@{ $Stats{$ip_addr} }) {
            printf MAIL $format, 
                        ($i++ == 0) ? $ip_addr : ' 'x(length($ip_addr)),
                        scalar(localtime($visit->[0])),
                        scalar(localtime($visit->[1])),
                        &get_elapsed($visit->[1], $visit->[0]),
                        $visit->[2];
        }
    }
    
    close(MAIL);
}

sub clean {
    return unless $Do_Clean and @Files_To_Clean;
    for my $file (@Files_To_Clean) {
        unlink "$REGISTRY_DIR/$file";
    }
}

sub get_elapsed {
    my ($later, $earlier) = @_;
    my $diff;
    $diff = $later - $earlier;
    my $sec = $diff % 60;
    $diff = ($diff - $sec) / 60;
    my $min = $diff % 60;
    $diff = ($diff - $min) / 60;
    my $hrs = $diff % 24;
    my $s = '';
    $s .= sprintf("%2d:", $hrs) if $hrs;
    $s .= sprintf("%02d:", $min) if $min;
    $s .= sprintf("%02d", $sec) if $sec;
    return $s;
#    return sprintf("%2d:%02d:%02d", $hrs, $min, $sec);
}

