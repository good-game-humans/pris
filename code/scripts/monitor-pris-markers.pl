#!/usr/bin/perl
#
# monitor-pris-markers.pl
# Victor Liu - mailto:victor@n-gon.com
#
# Emails the markers placed on pris.

$LS_CMD    = 'ssh -lroot pris ls -lct /pris/markers';
$SENDMAIL  = '/usr/sbin/sendmail';

###############################################################################
# Begin MAIN                                                                  #

my $ls = &ls_pris_markers;
&send_email($ls);
exit;

# End of MAIN                                                                 #
###############################################################################

sub ls_pris_markers {
    return `$LS_CMD`;
}

sub send_email {
    my $ls = shift;
    open(MAIL, "| $SENDMAIL victor\@n-gon.com");
    print MAIL "From: monitor-pris-markers\@n-gon.com\n";
    print MAIL "Subject: pris markers\n\n";
    print MAIL "$ls\n";
    close(MAIL);
}

