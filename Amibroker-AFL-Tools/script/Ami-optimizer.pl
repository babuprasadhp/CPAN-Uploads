#φί§²
use strict;
use warnings;
use Getopt::Long;
use Audio::Beep;
use Carp;

use FindBin;
use lib "$FindBin::Bin/../lib";
require Amibroker::AFL::Optimizer;


=head1 NAME

Ami-optimizer.pl - Auto Optimizer Script that uses Amibroker::AFL::Optimizer framework to run optimization.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    Ami-optimizer.pl -destination C:/finalreports/today
                     -dbpath C:/amibroker/dbpath
                     -opttime NO
                     -timframe 20-minute
                     -symbol IBM
                     -afltemplate C:/amibroker/formulas/custom/myema.afl
                     -optname EMA

=cut

my $periodFile = "$FindBin::Bin\\..\\rules\\PeriodList.txt";
my $MarginFile = "$FindBin::Bin\\..\\rules\\ScriptDetails.txt";

my ( $PERIOD_LIST, $MARGINS_LIST );
#
# Main program goes here
#
sub main() {

    GetOptions(
        "destination=s" => \( my $DEFAULT_DESTINATION = 'C:/temp123' ),
        "database=s"    => \( my $DEFAULT_DATABASE    = 'C:/temp123' ),
        "opttime=s"     => \( my $OPTIMIZE_TIME       = 'YES' ),
        "timeframe=s"   => \( my $TIMEFRAME           = 'ALL' ),
        "symbol=s"      => \( my $SYMBOL              = 'ALL' ),
        "afltemplate=s" => \( my $AFLTEMPLATE         = '' ),
        "optname=s"     => \( my $OPTNAME             = 'opt' ),
        "minwin=s"      => \( my $MINWIN              = 50 ),
        "mintrades=s"   => \( my $MINTRADES           = 25 ),
        "minprofit=s"   => \( my $MINPROFITS          = 50 ),
        "selectindex=s" => \( my $SELECTINDEX         = 5 ),
        "profitfrom=s"  => \( my $PROFITFROM          = 2000 ),
        "profitto=s"    => \( my $PROFITTO            = 22000 ),
        "profitincr=s"  => \( my $PROFITINCR          = 2000 )
    ) or croak('[ERROR] : Error in command line arguments');
    print "\nArguments passed\n---------------------------\n";
    print "DESTINATION     = $DEFAULT_DESTINATION\n";
    print "DATABASE        = $DEFAULT_DATABASE\n";
    print "TEMPLATE        = $AFLTEMPLATE\n";
    print "TIMEFRAME       = $TIMEFRAME\n";
    print "OPTIMIZE TIME   = $OPTIMIZE_TIME\n";
    print "OPT NAME        = $OPTNAME\n";
    print "MIN WIN%        = $MINWIN\n";
    print "MIN PROFIT%     = $MINPROFITS\n";
    print "MIN TRADES      = $MINTRADES\n";
    print "SELECT INDEX    = $SELECTINDEX\n";
    print "SYMBOL          = $SYMBOL\n" if ($SYMBOL);
    print "PROFIT FROM(Rs) = $PROFITFROM\n";
    print "PROFIT TO(Rs)   = $PROFITTO\n";
    print "PROFIT INCR(Rs) = $PROFITINCR\n";
    print "---------------------------\n";

    $PERIOD_LIST  = read_config_file($periodFile);
    $MARGINS_LIST = read_config_file($MarginFile);
    my @SymbolList = ();

    if ( $SYMBOL eq 'ALL' ) {
        foreach ( sort keys %{$MARGINS_LIST} ) {
            push( @SymbolList, $_ );
        }
    }
    else {
        push( @SymbolList, $SYMBOL );
    }
    foreach my $SCRIPT (@SymbolList) {
        print "SCRIPT = $SCRIPT\n";
        my $RESULT_PATH = $DEFAULT_DESTINATION . '/' . $SCRIPT;
        File::Path::make_path( $RESULT_PATH, { verbose => 1 } )
          unless ( -d $RESULT_PATH );
        if ( $TIMEFRAME eq 'ALL' ) {
            foreach my $currentTime ( keys %$PERIOD_LIST ) {
                my $curTimeFrame = $currentTime;
                $curTimeFrame = $curTimeFrame . '-minute'
                  if ( $curTimeFrame =~ /\d+/ );
                print "Running for TimeFrame = $curTimeFrame\n";
                my $Obj = Amibroker::AFL::Optimizer->new(
                    {
                        dbpath             => $DEFAULT_DATABASE,
                        destination_path   => $RESULT_PATH,
                        timeframe          => $curTimeFrame,
                        optimizer_name     => $OPTNAME,
                        afl_template       => $AFLTEMPLATE,
                        symbol             => $SCRIPT,
                        min_win_percent    => $MINWIN,
                        min_profit_percent => $MINPROFITS,
                        min_no_of_trades   => $MINTRADES,
                        selection_index    => $SELECTINDEX,
                        profit_from        => $PROFITFROM,
                        profit_to          => $PROFITTO,
                        profit_incr        => $PROFITINCR,
                        optimize_time      => $OPTIMIZE_TIME,
                        lot_size           => $MARGINS_LIST->{$SCRIPT}->[0],
                        margin_amt         => $MARGINS_LIST->{$SCRIPT}->[1]
                    }
                );
                $Obj->start_optimizer();
            }
        }
        else {
            my $Obj = Amibroker::AFL::Optimizer->new(
                {
                    dbpath             => $DEFAULT_DATABASE,
                    destination_path   => $RESULT_PATH,
                    timeframe          => $TIMEFRAME,
                    optimizer_name     => $OPTNAME,
                    afl_template       => $AFLTEMPLATE,
                    symbol             => $SCRIPT,
                    min_win_percent    => $MINWIN,
                    min_profit_percent => $MINPROFITS,
                    min_no_of_trades   => $MINTRADES,
                    selection_index    => $SELECTINDEX,
                    profit_from        => $PROFITFROM,
                    profit_to          => $PROFITTO,
                    profit_incr        => $PROFITINCR,
                    optimize_time      => $OPTIMIZE_TIME,
                    lot_size           => $MARGINS_LIST->{$SCRIPT}->[0],
                    margin_amt         => $MARGINS_LIST->{$SCRIPT}->[1]
                }
            );
            $Obj->start_optimizer();
        }
    }

    print "\n\n****************************************\n";
    print "\n      ---       COMPLETED       ---     \n";
    print "\n****************************************\n";
    my $beeper = Audio::Beep->new();
    my $music  = "g' f bes' c8 f";
    $beeper->play($music);
    return 1;
}

#
# Read margin file separated by commas
# NOTE: For comments use #
#
sub read_config_file {
    my $file = shift;
    my $hash;
    open( my $fh, "<", $file )
      or croak( '[ERROR] : Can\'t open the file $file: ' . "$!\n" );
    while (<$fh>) {
        chomp($_);
        next if $_ =~ /^$/;
        next if $_ =~ /^#/;
        if ( $_ =~ /\=/ ) {
            my ( $key, $value ) = split( "=", $_ );
            $hash->{$key} = $value;
        }
        elsif ( $_ =~ /\,/ ) {
            my @list = split( ",", $_ );
            $hash->{ shift(@list) } = \@list;
        }
    }
    close($fh);
    return $hash;
}

main();
1;

=head1 AUTHOR

Babu Prasad HP, C<< <bprasad@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-amibroker-afl-optimizer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Amibroker-AFL-Optimizer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Amibroker::AFL::Optimizer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Amibroker-AFL-Optimizer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Amibroker-AFL-Optimizer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Amibroker-AFL-Optimizer>

=item * Search CPAN

L<http://search.cpan.org/dist/Amibroker-AFL-Optimizer/>

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
