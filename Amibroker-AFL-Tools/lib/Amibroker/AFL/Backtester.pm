package Amibroker::AFL::Backtester;

use 5.006;
use strict;
use warnings;
use File::Path qw(remove_tree);
use File::Copy::Recursive;
use File::Slurp;
use Path::Tiny qw(path);
use Math::Round;
use Carp;
use Win32::API;
use Amibroker::OLE::Interface;
use Amibroker::OLE::APXCreator;

my $AMIBROKER_SERVICE_RUNS = 2000;
my $TIMECNTR = 0;

our $VERSION = '0.03';

sub new {
    my @list  = @_;
    my $class = shift @list;
    push @list, {} unless @list and _is_arg( $list[-1] );
    my $self = _check_valid_args(@list);
    croak('[ERROR] : No \'dbpath\' (Database path) supplied to Amibroker (Required Parameter) '. "\n" )  unless $self->{dbpath};
    croak('[ERROR] : Not a directory : \'dbpath\' (Database path) to Amibroker ' . "\n" )  unless -d $self->{dbpath};
    croak('[ERROR] : No \'destination_path\' supplied to Amibroker (Required Parameter) '. "\n" )  unless $self->{destination_path};
    croak('[ERROR] : Not a directory : \'destination_path\' ' . "\n" )  unless -d $self->{destination_path};
    croak('[ERROR] : No \'source_path\' supplied to Amibroker (Required Parameter) '. "\n" )  unless $self->{source_path};
    croak('[ERROR] : Not a directory : \'source_path\' ' . "\n" )  unless -d $self->{source_path};
    croak('[ERROR] : No \'timeframe\' supplied to Amibroker (Required Parameter) '. "\n" )  unless $self->{timeframe};
    croak('[ERROR] : No \'symbol\' supplied to Amibroker (Required Parameter) ' . "\n" )   unless $self->{symbol};

    print '[WARN] : No \'out_of_sample_months\' supplied to Amibroker : Default 3 Months is taken ' . "\n"  unless $self->{out_of_sample_months};
    print '[WARN] : No \'log_path\' supplied to Amibroker             : So, No logging ' . "\n"  unless $self->{log_path};
    print '[WARN] : No \'backtester_name\' supplied to Amibroker      : Default is taken '. "\n"  unless $self->{backtester_name};
    print '[WARN] : No \'margin_amt\' supplied to Amibroker           : By Default Ignoring margin amount ' . "\n" unless $self->{margin_amt};
    print '[WARN] : No \'from or to\' dates are supplied to Amibroker : By Default Ignoring From & To Dates' . "\n" unless ( $self->{from} || $self->{to} );

    bless $self, $class if defined $self;
    $self->init();
    return $self;
}

sub init {
    my $self = shift;
    $self->{backtester_name}      = 'BT';
    $self->{_timestamp}           = $self->getLoggingTime();
    $self->{_sandbox_path}        = $self->getSandboxPath();
    $self->{out_of_sample_months} = 3 unless($self->{out_of_sample_months});
    return 1;
}

#
# Main login behind Amibroker Backtester software
#
sub start_backtester {
    my $self    = shift;
    my $aflList = $self->list_afl_files_in_directory( $self->{source_path} );
    $self->{_BT_Count} = 0;
    #
    # Step 1 : Clear Sandbox - to ensure your temp folder is clean
    #
    $self->clear_sandbox();
    #
    # Step 2 : Start Amibroker engine
    #
    print "--------------------------------------\n\n";
    print "Starting the amibroker engine\n";
    my $broker = Amibroker::OLE::Interface->new(
        {
            verbose => 1,
            dbpath  => $self->{dbpath}
        }
    );
    $broker->start_amibroker_engine();
    $self->{_broker} = $broker;
    print "Amibroker Engine Started\n" if ($broker);
    print "--------------------------------------\n\n";
    #
    # Loop through the AFL list
    #
    foreach my $myafl (@$aflList) {
        my @SummaryResults        = ();
        my $totalMonths           = 0;
        my $totalNegativeMonths   = 0;
        my $totalNegMntMinus10    = 0;
        my $totalNegMntMinus20    = 0;
        my $totalNegMntMinus30    = 0;
        my $totalNegMntMinus40    = 0;
        my $totalLossSum          = 0;
        my $totalZeroMonths       = 0;
        my $totalTrades           = 0;
        my $totalWinners          = 0;
        my $totalNetProfitPercent = 0;

        my ( $OUTMntTotalNegativeMonths, $OUTMntTotalNegMntMinus10,
            $OUTMntTotalNegMntMinus20 );
        my ( $OUTMntTotalNegMntMinus30, $OUTMntTotalNegMntMinus40,
            $OUTMntTotalNetProfitPercent );
        my (
            $OUTMntTotalLossSum, $OUTMntTotalZeroMonths,
            $OUTMntTotalTrades,  $OUTMntTotalWinners
        );
        my $OUTMntFlag = 0;

        my $mntCount = keys %{ $self->{'_date_hash'} };
        if ( $mntCount > $self->{out_of_sample_months} ) {
            $OUTMntTotalNegativeMonths   = 0;
            $OUTMntTotalNegMntMinus10    = 0;
            $OUTMntTotalNegMntMinus20    = 0;
            $OUTMntTotalNegMntMinus30    = 0;
            $OUTMntTotalNegMntMinus40    = 0;
            $OUTMntTotalLossSum          = 0;
            $OUTMntTotalZeroMonths       = 0;
            $OUTMntTotalTrades           = 0;
            $OUTMntTotalWinners          = 0;
            $OUTMntTotalNetProfitPercent = 0;
        }
        else {
            $OUTMntTotalNegativeMonths   = 'NA';
            $OUTMntTotalNegMntMinus10    = 'NA';
            $OUTMntTotalNegMntMinus20    = 'NA';
            $OUTMntTotalNegMntMinus30    = 'NA';
            $OUTMntTotalNegMntMinus40    = 'NA';
            $OUTMntTotalLossSum          = 'NA';
            $OUTMntTotalZeroMonths       = 'NA';
            $OUTMntTotalTrades           = 'NA';
            $OUTMntTotalWinners          = 'NA';
            $OUTMntTotalNetProfitPercent = 'NA';
        }
        my ( $filePeriod, $fileTimeFrame ) = $self->getTimeFrame($myafl);
		if ( $self->{_BT_Count} >= $AMIBROKER_SERVICE_RUNS ) {
			$self->service_amibroker();
			$self->dump_to_reports();
		}
        #
        # Step 3 : Create Sandbox path for each AFL
        #
        File::Path::make_path( $self->{_sandbox_path}, { verbose => 0 } );
        #
        # Step 4 : Extract symbol name out of the AFL name
        #
        my $symbol = $self->extract_symbol_name($myafl);
        my ( $lotsize, $marginAmount ) =
          $self->get_stock_margin_details($symbol);
        push( @SummaryResults, $myafl );
        push( @SummaryResults, $symbol );
        push( @SummaryResults, $fileTimeFrame );
        push( @SummaryResults, $lotsize );
        push( @SummaryResults, $marginAmount );
        #
        # Step 5 : Slurp AFL file to a string
        #
        my $afl = File::Slurp::read_file( $self->{source_path} . '/' . $myafl );
        #
        # Step 6 : Loop through the backtest dates ranges
        #
        foreach my $dateRange ( sort keys %{ $self->{'_date_hash'} } ) {
            $OUTMntFlag = 1 if ( $mntCount == $self->{out_of_sample_months} );
            #
            # Step 7 : Extract the exact Date range in order
            #
            my ( $month, $datelist ) =
              split( /\^\^/, $self->{'_date_hash'}->{$dateRange} );
            my ( $from, $to ) = split( /\*\*/, $datelist );
            print "  $self->{_BT_Count}\t$symbol.......$month\n";
            #
            # Step 8 : Get the Sandbox and Result file path
            #
            my $sandbox_xml =
              $self->{_sandbox_path} . '/' . $myafl . '-' . $month . '.apx';
            my $resultFile =
              $self->{_sandbox_path} . '/' . $myafl . '-' . $month . '.csv';
#
# Step 9 : Load APX file for that particular AFL and for that particular Date range
#
    my $apxFile = Amibroker::OLE::APXCreator::create_apx_file(
        {
            apx_file   => $sandbox_xml,
            afl_file   => $self->{source_path} . '/' . $myafl,
            symbol     => $self->{symbol},
            timeframe  => $self->{timeframe},
            from       => $self->{from},
            to         => $self->{to},
            range_type => 3,
            apply_to   => 1
        }
    );
            #
            # Step 10 : Run Backtest
            #
    my $runStatus = $broker->run_analysis(
        {
            action      => 3,
            symbol      => $self->{symbol},
            apx_file    => $apxFile,
            result_file => $resultFile
        }
    );
    print "ERROR in Amibroker Engine - Symbol: " . $self->{symbol} . "\n\n"
      unless ($runStatus);
            #
            # Step 11 : Load the result file generated by amibroker to hash
            #
            my $result_array = $self->load_result_file( $resultFile  );
            print "\n***WARN: Result is empty - Amibroker Didnt run for \n"
              unless (@$result_array);
            print "Symbol = $symbol and DateRange From: $from To: $to\n"
              unless (@$result_array);
            print "Please report to developer - Seems Dates.txt is screwed\n\n"
              unless (@$result_array);
            #
            # Step 12 : Update reporting parameters for ALL
            #
            my $netProfitPercent = $result_array->[2]  || 0; # net profit %
            my $trades           = $result_array->[21] || 0; # number of trades
            my $winners          = $result_array->[25] || 0; # number of winners
            $trades                = $self->clean_value($trades);
            $winners               = $self->clean_value($winners);
            $netProfitPercent      = $self->clean_value($netProfitPercent);
            $totalTrades           = $totalTrades + $trades;
            $totalWinners          = $totalWinners + $winners;
            $totalNetProfitPercent = $totalNetProfitPercent + $netProfitPercent;
            $totalLossSum          = $totalLossSum + $netProfitPercent
              if ( $netProfitPercent < 0 );
            $totalZeroMonths++     if ( $netProfitPercent == 0 );
            $totalNegativeMonths++ if ( $netProfitPercent < 0 );
            $totalNegMntMinus10++  if ( $netProfitPercent < -10 );
            $totalNegMntMinus20++  if ( $netProfitPercent < -20 );
            $totalNegMntMinus30++  if ( $netProfitPercent < -30 );
            $totalNegMntMinus40++  if ( $netProfitPercent < -40 );
            #
            # Step 13 : Insert Monthly profit percent
            #
            push( @SummaryResults,
                Math::Round::nearest( 0.1, $netProfitPercent ) );
            #
            # Step 14 : Update reporting parameters for latest 6 months or so
            #
            if ($OUTMntFlag) {
                $OUTMntTotalZeroMonths++     if ( $netProfitPercent == 0 );
                $OUTMntTotalNegativeMonths++ if ( $netProfitPercent < 0 );
                $OUTMntTotalNegMntMinus10++  if ( $netProfitPercent < -10 );
                $OUTMntTotalNegMntMinus20++  if ( $netProfitPercent < -20 );
                $OUTMntTotalNegMntMinus30++  if ( $netProfitPercent < -30 );
                $OUTMntTotalNegMntMinus40++  if ( $netProfitPercent < -40 );
                $OUTMntTotalLossSum = $OUTMntTotalLossSum + $netProfitPercent
                  if ( $netProfitPercent < 0 );
                $OUTMntTotalTrades  = $OUTMntTotalTrades + $trades;
                $OUTMntTotalWinners = $OUTMntTotalWinners + $winners;
                $OUTMntTotalNetProfitPercent =
                  $OUTMntTotalNetProfitPercent + $netProfitPercent;
            }
            $self->{_BT_Count}++;
            $totalMonths++;
            $mntCount--;
        }
        #
        # Step 15 : Update Total values to hash
        #
        $totalMonths = 1 unless ($totalMonths); # To eliminate divide zero error
        $totalTrades = 1 unless ($totalTrades); # To eliminate divide zero error
        $OUTMntTotalTrades = 1
          unless ($OUTMntTotalTrades);          # To eliminate divide zero error
                                                # Total Sum
        push( @SummaryResults,
            Math::Round::nearest( 0.01, $totalNetProfitPercent ) );

        # Total Average
        push( @SummaryResults,
            Math::Round::nearest( 0.01, $totalNetProfitPercent / $totalMonths )
        );

        # Total Winner %
        push( @SummaryResults,
            Math::Round::nearest( 0.1, ( $totalWinners / $totalTrades ) * 100 )
        );

        # Total Loss Sum
        push( @SummaryResults, Math::Round::nearest( 0.1, $totalLossSum ) );
        push( @SummaryResults, $totalTrades );     # Total Number of Trades
        push( @SummaryResults, $totalZeroMonths ); # Total Number of Zero Months
        push( @SummaryResults, $totalNegativeMonths )
          ;    # Total Number of Negative months
        push( @SummaryResults, $totalNegMntMinus10 )
          ;    # Total Countif-less-than-(minus 10)
        push( @SummaryResults, $totalNegMntMinus20 )
          ;    # Total Countif-less-than-(minus 20)
        push( @SummaryResults, $totalNegMntMinus30 )
          ;    # Total Countif-less-than-(minus 30)
        push( @SummaryResults, $totalNegMntMinus40 )
          ;    # Total Countif-less-than-(minus 40)

        if ($OUTMntFlag) {
            push( @SummaryResults,
                Math::Round::nearest( 0.01, $OUTMntTotalNetProfitPercent ) )
              ;    # Total Sum
            push(
                @SummaryResults,
                Math::Round::nearest(
                    0.01, $OUTMntTotalNetProfitPercent / $self->{out_of_sample_months}
                )
            );     # Total Average
            push(
                @SummaryResults,
                Math::Round::nearest(
                    0.1, ( $OUTMntTotalWinners / $OUTMntTotalTrades ) * 100
                )
            );     # Total Winner %
            push( @SummaryResults,
                Math::Round::nearest( 0.1, $OUTMntTotalLossSum ) )
              ;    # Total Loss Sum
        }
        else {
            push( @SummaryResults, 'NA' );    # Nothing to display
            push( @SummaryResults, 'NA' );    # Nothing to display
            push( @SummaryResults, 'NA' );    # Nothing to display
            push( @SummaryResults, 'NA' );    # Nothing to display
        }
        push( @SummaryResults, $OUTMntTotalTrades );    # Total Number of Trades
        push( @SummaryResults, $OUTMntTotalZeroMonths )
          ;    # Total Number of Zero Months
        push( @SummaryResults, $OUTMntTotalNegativeMonths )
          ;    # Total Number of Negative months
        push( @SummaryResults, $OUTMntTotalNegMntMinus10 )
          ;    # Total Countif-less-than-(minus 10)
        push( @SummaryResults, $OUTMntTotalNegMntMinus20 )
          ;    # Total Countif-less-than-(minus 20)
        push( @SummaryResults, $OUTMntTotalNegMntMinus30 )
          ;    # Total Countif-less-than-(minus 30)
        push( @SummaryResults, $OUTMntTotalNegMntMinus40 )
          ;    # Total Countif-less-than-(minus 40)
        $self->{_SummaryReportHash}->{$myafl} =
          \@SummaryResults;    # One line per symbol in report
    }
    #
    # Step 16 : Dump hash to report file
    #
    $self->dump_to_reports() if (@$aflList);
    return 1;
}
#
# Service Amibroker - by restarting it.
# This will clean up the memory that is being holdup by the engine.
#
sub service_amibroker {
    my $self = shift;
    $self->{_BT_Count} = 0;    # reseting the count
    my $broker = $self->{_broker};
    print "--------------------------------------\n";
    print "Restarting Amibroker Engine\n";
    $broker->shutdown_amibroker_engine();
    sleep(30);    #Sleep for half minute and let the amibroker engine relax

    print "Starting the amibroker engine\n";
    my $newbroker = Amibroker::OLE::Interface->new(
        {
            verbose => 1,
            dbpath  => $self->{dbpath}
        }
    );
    $newbroker->start_amibroker_engine();
    $self->{_broker} = $newbroker;
    print "Amibroker Engine Re-Started again\n" if ($newbroker);
    print "--------------------------------------\n\n";
    return 1;
}

#
# Get the lotsize and margin details of the selected stock symbol
#
sub get_stock_margin_details {
    my ( $self, $symbol ) = @_;
    foreach my $script ( sort keys %{ $self->{'_margin_hash'} } ) {
        if ( $symbol eq $script ) {
            my ( $lotsize, $marginAmt ) =
              split( /\~/, $self->{'_margin_hash'}->{$script} );
            return ( $lotsize, $marginAmt );
        }
    }
    return ( 'NA', 'NA' );
}
#
# Determine the timeframe for which the backtester should run
# Timeframe provided in the AFL file name takes the higher precedence over the one passed thru args.
#
sub getTimeFrame {
    my ( $self, $afl ) = @_;
    print "AFL file  = $afl\n";

#   If the file name has time frame then that gets highest precedence compared to input args
    my $fileTimeFrame = Utils::get_time_period_from_file_name($afl);
    if ($fileTimeFrame) {
        print "AFL TimeFrame = $fileTimeFrame\n";
        my $filePeriod = $self->get_backtest_periodicity( $fileTimeFrame,
            $self->{'_period_list'} );
        unless ( $fileTimeFrame =~ /hourly|daily/i ) {
            $fileTimeFrame .= '-Minute';
        }
        return ( $filePeriod, $fileTimeFrame );
    }
    else {
        return ( $self->{'_periodicity'}, $self->{'_current_period'} );
    }
}
#
# Get the periodicity value as per Amibroker guide
# These periodicity values are stored in a file - just read it and split it
#
sub get_backtest_periodicity {
    my ( $self, $timeframe, $PERIOD ) = @_;
    chomp($timeframe);
    my $digit;
    if ( $timeframe =~ /(^\d+)/ ) {
        $digit = $1;
    }
    elsif ( $timeframe =~ /(^\w+)/ ) {
        $digit = lc($1);
    }
    else {
        $digit = 111;
    }
    foreach my $per ( keys %$PERIOD ) {
        return $PERIOD->{$per} if ( $digit eq $per );
    }

    # 111 is random number chosen to detect unknown period as 0 is valid period
    return (111);
}
#
# Clear the sanbox area for next backtesting
#
sub clear_sandbox {
    my $self = shift;
    File::Path::remove_tree( $self->{_sandbox_path}, { verbose => 1 } );
    print "Sandbox cleaned up\n";
    return 1;
}
#
# Keep a copy of sandbox in the logs foler for later debugging
#
sub copy_sandbox {
    my $self = shift;
    if ( $self->{log_path} ) {
        my $logPath = $self->{log_path} . '/' . $self->{_timestamp};
        File::Copy::Recursive::dircopy( $self->{_sandbox_path}, $logPath )
          or print("WARN: Could not copy Sandbox log: $!\n");
        print "Sandbox copy completed\n";
    }
    return 1;
}
#
# Clean the variable
#
sub clean_value {
    my ( $self, $value ) = @_;
    $value =~ s/[\/a-zA-Z]+/0/g;
    $value =~ s/^\s+|\s+$//g;
    return $value;
}
#
# Get the header for the report file that gets printed to excel file
#
sub get_report_header {
    my $self = shift;
    my @DateHeader;
    push( @DateHeader, 'FileName' );
    push( @DateHeader, 'Symbol' );
    push( @DateHeader, 'TimeFrame' );
    push( @DateHeader, 'LotSize' );
    push( @DateHeader, 'MarginAmount' );
    foreach my $dateRange ( sort keys %{ $self->{'_date_hash'} } ) {
        my ( $month, $datelist ) =
          split( /\^\^/, $self->{'_date_hash'}->{$dateRange} );
        push( @DateHeader, $month );
    }
    push( @DateHeader, 'TOTAL' );
    push( @DateHeader, 'AVERAGE' );
    push( @DateHeader, 'Total Winners%' );
    push( @DateHeader, 'Total Losses' );
    push( @DateHeader, 'Total Trades' );
    push( @DateHeader, 'Count Zero' );
    push( @DateHeader, 'Count Neg Mnts' );
    push( @DateHeader, 'Count (-10)' );
    push( @DateHeader, 'Count (-20)' );
    push( @DateHeader, 'Count (-30)' );
    push( @DateHeader, 'Count (-40)' );
    push( @DateHeader, 'OUT(TOTAL)' );
    push( @DateHeader, 'OUT(AVERAGE)' );
    push( @DateHeader, 'OUT(Winners%)' );
    push( @DateHeader, 'OUT(Losses Sum)' );
    push( @DateHeader, 'OUT(Trades)' );
    push( @DateHeader, 'OUT(Count Zero)' );
    push( @DateHeader, 'OUT(Count Neg Mnts)' );
    push( @DateHeader, 'OUT(Count -10)' );
    push( @DateHeader, 'OUT(Count -20)' );
    push( @DateHeader, 'OUT(Count -30)' );
    push( @DateHeader, 'OUT(Count -40)' );
    return \@DateHeader;
}
#
# Dump the hash to report excel file
#
sub dump_to_reports {
    my $self  = shift;
    my $report_header = $self->get_report_header();
    my $report_path   = $self->{destination_path} . '/' . $self->{_timestamp}.'_'.$TIMECNTR;
	$TIMECNTR++;
    File::Path::make_path( $self->{destination_path}, { verbose => 1 } )  unless ( -d $self->{destination_path} );
    $report_path = $report_path . '_Summary.csv';
    unlink $report_path or croak('[ERROR] : could not write to Report file: '."$!\n")  if ( -f $report_path );
    open( my $SFH, '>', $report_path )  or croak('[ERROR] : Could not open file '.$report_path." $!\n");
    $self->dump_header_and_data( $SFH, $report_header );
    close $SFH;
    return 1;
}
#
# Dump both header and data
#
sub dump_header_and_data {
    my ( $self, $FH, $reportHeader ) = @_;

    print $FH join ",", @$reportHeader;
    print $FH "\n";
    my $data = $self->{_SummaryReportHash};
    $self->{_SummaryReportHash} = undef;  # reset this high memory eating hash
    foreach my $symb ( sort keys %$data ) {
        print $FH join ",", @{ $data->{$symb} };
        print $FH "\n";
    }
    return 1;
}
#
# Load the result file that amibroker has generated and grep for the symbol of our choice
#
sub load_result_file {
    my ( $self, $resultFile ) = @_;
    my @result = ();
    my @raw = File::Slurp::read_file($resultFile);
    my @selected = grep { /$self->{symbol}/ } @raw;
    @result = split( ',', $selected[0] ) if (@selected);
    return \@result;
}

#
# Extract the symbol name
#
sub extract_symbol_name {
    my ( $self, $afl ) = @_;
    return $1 if ( $afl =~ /(^[a-zA-Z&]+)/ );
    return 0;
}
#
# create a timestamp for log files
#
sub getLoggingTime {
    my $self = shift;
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);
    my $nice_timestamp = sprintf(
        "%04d%02d%02d-%02d%02d%02d",
        $year + 1900,
        $mon + 1, $mday, $hour, $min, $sec
    );
    return $nice_timestamp;
}

sub getSandboxPath {
    my $self = shift;
    my $GetTempAPI =
      Win32::API->new( 'kernel32', 'GetTempPath', [ 'N', 'P' ], 'N' );

    my $lpBuffer = " " x 80;
    my $length   = $GetTempAPI->Call( 80, $lpBuffer );
    my $tempPath = substr( $lpBuffer, 0, $length );

    $tempPath .= 'sandbox-' . $self->{_timestamp};
    print "Temp directory: $tempPath\n";
    return $tempPath;
}

sub _is_arg {
    my ($arg) = @_;
    return ( ref $arg eq 'HASH' );
}

sub _check_valid_args {
    my @list = @_;
    my %args_permitted = map { $_ => 1 } (
        qw|
          dbpath
          destination_path
          out_of_sample_months
          source_path
          timeframe
          symbol
          lot_size
          log_path
          backtester_name
          margin_amt
          from
          to
          |
    );
    my @bad_args = ();
    my $arg      = pop @list;
    for my $k ( sort keys %{$arg} ) {
        push @bad_args, $k unless $args_permitted{$k};
    }
    croak("Unrecognized option(s) passed to Amibroker OLE: @bad_args")
      if @bad_args;
    return $arg;
}

#
# List all the AFL files in a given source directory
#
sub list_afl_files_in_directory {
    my ($self, $mydir) = @_;
    print "My Source directory = $mydir\n";
    my @list = File::Slurp::read_dir($mydir);
    my @afls = grep { /\.afl$/ && -f "$mydir/$_" } @list;
    return \@afls;
}

#
# Explicitly call the destructor
#
sub DESTROY {
    my $self   = shift;
    my $broker = $self->{_broker};
    $broker->shutdown_amibroker_engine() if ( $self->{_broker} );
    $self->copy_sandbox();
    $self->clear_sandbox();
    return 1;
}
1; # End of Amibroker::AFL::Backtester

__END__


=head1 NAME

Amibroker::AFL::Backtester - Auto Backtester framework for ALL Stocks/Futures/Options/Spot/Commodities across ALL timeframe in Amibroker.

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Amibroker::AFL::Backtester;

	my $obj1 = Amibroker::AFL::Backtester->new( { 
								dbpath => 'C:\TradingTools\Amibroker5.90.1\InOutData',
								destination_path => 'C:\TradingTools',
								source_path => 'C:\TradingTools',
								timeframe => '5-minute',
								symbol => 'NIFTY-I',
								from => '12-05-2010',
								to => '31-12-2014'
	} );
    $obj->start_backtester();

=head2 new() [constructor]

Minimum 7 mandatory parameters are required for the amibroker backtester to run.

    my $obj = Amibroker::AFL::Backtester->new( {
							dbpath => 'amibroker_database_path',
							destination_path => 'final_path_where_reports_will_be_dumped',
							source_path => 'source_path_where_afls_are_present',
							timeframe => 'timeframe',
							symbol => 'symbol',
							from => 'from_date',
							to => 'to_date'
						});

=head3 Required Parameters

=over 7

=item B<dbpath>

	Amibroker database path

=item B<destination_path>

	Amibroker destination_path is where finally the reports are dumped.

=item B<source_path>

	Amibroker source_path is where the afls are present and the system needs to read them.
	
=item B<timeframe>

You have to specifiy to which timeframe do you want to run the Backtester
    Default available timeframe with Amibroker.
    yearly    
    quarterly  
    monthly   
    weekly    
    daily     
    day/night 
    hourly     
    15-minute 
    5-minute 
    1-minute   
    3-minute 
    7-minute  
    10-minute
    12-minute 
    20-minute 

=item B<symbol>

Accepts any symbols name as present in your amibroker database.
B<CAUTION:> Symbol names should exactly match the symbols present in your amibroker database, else this backtesting will fail.

=item B<from>

From date

=item B<to>

To date, 
either specify both from and to dates or none should be specified.

=back

=head3 Optional Parameters

=over 1

=item B<log_path>

Path to the logs. If this parameter is not specified, then no logs will be stored.
The logs will contain all the results of the amibroker run and the apx file that was sent to the engine, 
so it helps in verifying the parameters that were passed to the amibroker engine and the output results.

=back

=head2 start_backtester()

	$obj->start_backtester();

Starts the backtester. It internally calls Amibroker::OLE::Interface to connect to Amibroker engine.
Usually every run takes around 1 minute to 5 minute, depending on the size of your amibroker database.

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
