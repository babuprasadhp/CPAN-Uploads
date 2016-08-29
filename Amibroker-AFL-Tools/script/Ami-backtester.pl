#!C://DevTools//Perl//bin//perl.exe

use strict;
use warnings;
use Getopt::Long;
use Audio::Beep;
use FindBin;
use lib "$FindBin::Bin/../lib";
require Amibroker::AFL::Backtester;

=head1 NAME

Ami-optimizer.pl - Auto Optimizer Script that uses Amibroker::AFL::Optimizer framework to run optimization.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    Ami-backtester.pl -destination C:/finalreports/today
                      -source C:/finalreports/today
                      -dbpath C:/amibroker/dbpath
                      -timframe 20-minute
                      -symbol IBM
					  -from 12-05-2010
					  -to 31-03-2014

=cut

my $periodFile = "$FindBin::Bin/rules/PeriodList.txt";
my $MarginFile = "$FindBin::Bin/rules/ScriptDetails.txt";

my $periodFile  = "$FindBin::Bin/Rules/Periodicity.txt";
my $DatesFile   = "$FindBin::Bin/Rules/Dates.txt";
my $MarginFile  = "$FindBin::Bin/Rules/MarginDetails.txt";

my ( $PARAMS, $PERIOD_LIST, $DATES_LIST, $MARGINS_LIST );
#
# Main programs starts here
#
sub main() {

    GetOptions(
        "source=s"      => \( my $DEFAULT_SOURCE       = $SandBox ),
        "destination=s" => \( my $DEFAULT_DESTINATION  = $SandBox ),
        "database=s"    => \( my $DEFAULT_DATABASE     = $SandBox ),
        "timeframe=s"   => \( my $TIMEFRAME            = '' ),
        "outofsample=s" => \( my $OUT_OF_SAMPLE_MONTHS = '6-Months' ),
        "help"          => \&help
    ) or die "Error in command line arguments";
    print "\nArguments passed\n---------------------------\n";
    print "SOURCE        = $DEFAULT_SOURCE\n";
    print "DESTINATION   = $DEFAULT_DESTINATION\n";
    print "DATABASE      = $DEFAULT_DATABASE\n";
    print "TIMEFRAME     = $TIMEFRAME\n";
    print "OUTSAMPLE MNT = $OUT_OF_SAMPLE_MONTHS\n";
    print "---------------------------\n";
    Utils::clean_old_logs($LogPath);
    $PERIOD_LIST  = Utils::read_configuration_file($periodFile);
    $DATES_LIST   = Utils::read_configuration_file($DatesFile);
    $MARGINS_LIST = Utils::read_configuration_file($MarginFile);

    my $period = Utils::get_backtest_periodicity( $TIMEFRAME, $PERIOD_LIST );
    print "Amibroker Periodicity = $period\n";
    if ( $period == 111 ) {
        print
"WARN: No such period exists for \"$TIMEFRAME\" and unknown time format\n";
        print "WARN: Seems like no options are passed to this program\n\n";
        help();
        return;
    }
    my $dirList = Utils::list_directories_in_dir($DEFAULT_SOURCE);
    if ( scalar @$dirList ) {
        foreach my $newSrcDirPath (@$dirList) {
            my $newDestDirPath =
                $DEFAULT_SOURCE eq $DEFAULT_DESTINATION
              ? $newSrcDirPath
              : $DEFAULT_DESTINATION;
            my $Obj = BT->new(
                $TIMEFRAME,     $PERIOD_LIST,    $timestamp,
                $LogPath,       $SandBox,        $apxTemplate,
                $newSrcDirPath, $newDestDirPath, $DEFAULT_DATABASE,
                $period,        $DATES_LIST,     $MARGINS_LIST,
                $OUT_OF_SAMPLE_MONTHS
            );
            $Obj->start_recursive_backtest();
        }
    }
    else {
        print "FYI -- Only one folder present\n";
        my $Obj = BT->new(
            $TIMEFRAME,        $PERIOD_LIST,
            $timestamp,        $LogPath,
            $SandBox,          $apxTemplate,
            $DEFAULT_SOURCE,   $DEFAULT_DESTINATION,
            $DEFAULT_DATABASE, $period,
            $DATES_LIST,       $MARGINS_LIST,
            $OUT_OF_SAMPLE_MONTHS
        );
        $Obj->start_recursive_backtest();
    }
    print "\n\n****************************************\n";
    print "\n      ---       COMPLETED       ---     \n";
    print "\n****************************************\n";
    my $beeper = Audio::Beep->new();
    my $music  = "g' f bes' c8 f d4 c8 f d4 bes c g f2";
    $beeper->play($music);
    return 1;
}
#
# Helper function
#
main();
1;

=head1 AUTHOR

Babu Prasad HP, C<< <bprasad@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-amibroker-afl-backtester at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Amibroker-AFL-Backtester>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Amibroker::AFL::Backtester


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Amibroker-AFL-Backtester>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Amibroker-AFL-Backtester>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Amibroker-AFL-Backtester>

=item * Search CPAN

L<http://search.cpan.org/dist/Amibroker-AFL-Backtester/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Mr.Pannag for helping me in developing this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Babu Prasad HP.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut