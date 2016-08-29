package Amibroker::AFL::Optimizer;

use 5.006;
use strict;
use warnings;
use File::Path qw(remove_tree);
use File::Copy::Recursive;
use File::Slurp;
use Win32::API;
use Carp;
use Amibroker::OLE::Interface;
use Amibroker::OLE::APXCreator;

our $VERSION = '0.03';

my $AMIBROKER_SERVICE_RUNS = 1000;

sub new {
    my @list  = @_;
    my $class = shift @list;
    push @list, {} unless @list and _is_arg( $list[-1] );
    my $self = _check_valid_args(@list);
    croak(
'[ERROR] : No \'dbpath\' (Database path) supplied to Amibroker (Required Parameter) '
          . "\n" )
      unless $self->{dbpath};
    croak( '[ERROR] : Invalid \'dbpath\' (Database path) to Amibroker ' . "\n" )
      unless -d $self->{dbpath};
    croak(
'[ERROR] : No \'destination_path\' path supplied to Amibroker (Required Parameter) '
          . "\n" )
      unless $self->{destination_path};
    croak(
        '[ERROR] : No \'timeframe\' supplied to Amibroker (Required Parameter) '
          . "\n" )
      unless $self->{timeframe};
    croak( '[ERROR] : No \'symbol\' supplied to Amibroker (Required Parameter) '
          . "\n" )
      unless $self->{symbol};
    croak(
'[ERROR] : No \'afl_template\' supplied to Amibroker (Required Parameter) '
          . "\n" )
      unless $self->{afl_template};
    croak(
        '[ERROR] : No \'lot_size\' supplied to Amibroker, (Required Parameter)'
          . "\n" )
      unless $self->{lot_size};

    print
'[WARN] : No \'log_path\' supplied to Amibroker             : So, No logging '
      . "\n"
      unless $self->{log_path};
    print
'[WARN] : No \'optimizer_name\' supplied to Amibroker       : Default is taken '
      . "\n"
      unless $self->{optimizer_name};
    print
'[WARN] : No \'min_win_percent\' supplied to Amibroker      : Default 40% is taken '
      . "\n"
      unless $self->{min_win_percent};
    print
'[WARN] : No \'min_profit_percent\' supplied to Amibroker   : Default 50% is taken '
      . "\n"
      unless $self->{min_profit_percent};
    print
'[WARN] : No \'min_no_of_trades\' supplied to Amibroker     : Default 10 is taken '
      . "\n"
      unless $self->{min_no_of_trades};
    print
'[WARN] : No \'selection_index\' supplied to Amibroker      : Default 2 is taken '
      . "\n"
      unless $self->{selection_index};
    print
'[WARN] : No \'profit_from\' supplied to Amibroker          : Default 0 is taken '
      . "\n"
      unless $self->{profit_from};
    print
'[WARN] : No \'profit_to\' supplied to Amibroker            : Default 20000 is taken '
      . "\n"
      unless $self->{profit_to};
    print
'[WARN] : No \'profit_incr\' supplied to Amibroker          : Default 5000 is taken '
      . "\n"
      unless $self->{profit_incr};
    print
'[WARN] : No \'optimize_time\' supplied to Amibroker        : By Default No time optimization is done '
      . "\n"
      unless $self->{optimize_time};
    print
'[WARN] : No \'margin_amt\' supplied to Amibroker           : By Default Ignoring margin amount '
      . "\n"
      unless $self->{margin_amt};
    print
'[WARN] : No \'from or to\' dates are supplied to Amibroker : By Default Ignoring From & To Dates'
      . "\n"
      unless ( $self->{from} || $self->{to} );
    bless $self, $class if defined $self;
    $self->init();
    return $self;
}

sub init {
    my $self = shift;
    $self->{optimizer_name}     = 'opt';
    $self->{_timestamp}         = $self->getLoggingTime();
    $self->{_sandbox_path}      = $self->getSandboxPath();
    $self->{min_win_percent}    = 40 unless $self->{min_win_percent};
    $self->{min_profit_percent} = 50 unless $self->{min_profit_percent};
    $self->{min_no_of_trades}   = 10 unless $self->{min_no_of_trades};
    $self->{selection_index}    = 2 unless $self->{selection_index};
    $self->{profit_from}        = 0 unless $self->{profit_from};
    $self->{profit_to}          = 20000 unless $self->{profit_to};
    $self->{profit_incr}        = 5000 unless $self->{profit_incr};
    $self->{optimize_time}      = 'NO' unless $self->{optimize_time};
    return 1;
}

sub start_optimizer {
    my $self   = shift;
    my $script = $self->{symbol};
    $self->{_BT_Count} = 0;
    #
    # Step 1 : Start Amibroker engine
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
    #
    # Step 2 : Create Sandbox path if it doesnt exists
    #
    File::Path::make_path( $self->{_sandbox_path}, { verbose => 1 } );
    #
    # Step 3:  a copy of AFL Template file
    #
    my $copiedFile = $self->copy_file(
        $self->{afl_template}, $self->{destination_path},
        $self->{timeframe},    $self->{optimizer_name},
        $self->{symbol}
    );
    my $copyAfl = File::Slurp::read_file($copiedFile);
    #
    # Step 4: Replace STOCK NAME and LOT SIZE for the copied AFL File
    #
    $copyAfl =~ s/LOT_SIZE\=XXXX\;/LOT_SIZE\=$self->{lot_size}\;/g;
    $copyAfl =~ s/STOCK_NAME\=\"XXXX\"\;/STOCK_NAME\=\"$script\"\;/g;
    #
    # Step 5: Save the Copied AFL file
    #
    File::Slurp::write_file( $copiedFile, $copyAfl );
    #
    # Step 6: Run for STRATEGY optimized two variables
    #
    if ( $copyAfl =~ /optimize/g ) {
        my $status1 =
          $self->run_optimize_engine( 'BASIC', $broker, $copiedFile, $script );

        # No results, so skip optimization for this Afl
        # 99 is user-defined number - check for the called function
        #
        return 1 if ( $status1 == 99 );
    }
    #
    # Step 7: Now get ready for time based optimization
    #
    if ( $self->{optimize_time} =~ /YES/i ) {
        my $copy2Afl = File::Slurp::read_file($copiedFile);
        my $firstTime =
"FirstTradeTime = optimize(\"FirstTradeTime\",093000,091500,123000,001000);";
        my $lastTime =
"LastTradeTime  = optimize(\"LastTradeTime\",151500,140000,153000,001000);";
        $copy2Afl =~ s/FirstTradeTime.*/$firstTime/;
        $copy2Afl =~ s/LastTradeTime.*/$lastTime/;
        File::Slurp::write_file( $copiedFile, $copy2Afl );
        #
        # Step 8: Run for Time parameters optimized two variables
        #
        my $status2 =
          $self->run_optimize_engine( 'TIME', $broker, $copiedFile, $script );

        # No results, so skip optimization for this Afl
        # 99 is user-defined number - check for the called function
        #
        return 1 if ( $status2 == 99 );
    }
    #
    # Step 20: Now insert profit limits to the AFL and save the files
    #
    $self->save_profit_limit_afls( $script, $copiedFile, $self->{lot_size} );
    return 1;
}
#
# Create multiple afl files with different profit limits for backtesting
#
sub save_profit_limit_afls {
    my ( $self, $script, $afl, $lotsize ) = @_;
    my $copy3Afl    = Utils::slurp_afl($afl);
    my $destination = $self->{destination_path};
    my $optname     = $self->{optimizer_name};

    for (
        my $i = $self->{profit_from} ;
        $i <= $self->{profit_to} ;
        $i = $i + $self->{profit_incr}
      )
    {
        my $tempFile =
            $destination . '\\'
          . $script . '-'
          . $self->{timeframe} . '-'
          . $optname . '-'
          . $i . '.afl';
        my $tempcopy     = $copy3Afl;
        my $value        = $i / $lotsize;
        my $searchString = "\/\/PROFITPOINTSKEYWORD";
        my $replaceString =
          "ApplyStop\(stopTypeProfit\,stopModePoint\,$value\,True\,True\)\;";
        $tempcopy =~ s/$searchString/$replaceString/;
        Utils::Write_to_file( $tempFile, $tempcopy );
    }
    return 1;
}

#
# Main logic of the tool goes here
#
sub run_optimize_engine {
    my ( $self, $type, $broker, $copiedFile, $script ) = @_;
    $self->service_amibroker()
      if ( $self->{_BT_Count} >= $AMIBROKER_SERVICE_RUNS );
    #
    # Step 10 : Slurp AFL Template file to a string
    #
   # my $slurpAfl = File::Slurp::read_file($copiedFile);
    #
    # Step 11 : Get the Sandbox and Result file path
    #
    my $sandbox_xml =
        $self->{_sandbox_path} . '/'
      . $script . '-'
      . $self->{timeframe} . '-'
      . $self->{optimizer_name} . '-'
      . $type . '.apx';
    my $resultFile =
        $self->{_sandbox_path} . '/'
      . $script . '-'
      . $self->{timeframe} . '-'
      . $self->{optimizer_name} . '-'
      . $type . '.csv';
    #
    # Step 12 : Create APX file
    #
    my $range = 0;    # by default range_type is all quotes
	
	# if from & to dates are supplied, then go for From_and_To
    if ( $self->{from} && $self->{to} ) {
		$range = 3;
	}
	else {
		$self->{from} = '01-01-2000';
		$self->{to}   = '31-12-2015';
	}
	print "====================================================\n";
	print "sandbox_xml = $sandbox_xml\n";
	print "copiedFile = $copiedFile\n";
	print "timeframe = $self->{timeframe}\n";	
	print "from = $self->{from}\n";	
	print "to = $self->{to}\n";	
	print "range_type = $range\n";	
	print "apply_to = 1\n";	
	
	print "====================================================\n";
    my $apxFile = Amibroker::OLE::APXCreator::create_apx_file(
        {
            apx_file   => $sandbox_xml,
            afl_file   => $copiedFile,
            symbol     => $script,
            timeframe  => $self->{timeframe},
            from       => $self->{from},
            to         => $self->{to},
            range_type => $range,
            apply_to   => 1
        }
    );
    #
    # Step 13 : Run Amibroker Optimizer
    #
	print "apx_file = $apxFile\n";
	print "result_file = $resultFile\n";
	print "symbol = $self->{symbol}\n";
	
    my $runStatus = $broker->run_analysis(
        {
            action      => 5,
            symbol      => $self->{symbol},
            apx_file    => $apxFile,
            result_file => $resultFile
        }
    );
    print "ERROR in Amibroker Engine - Symbol: " . $script . "\n\n"
      unless ($runStatus);
    #
    # Step 14 : Load the result file generated by amibroker to hash
    #
    my $result_array = $self->load_result_file( $resultFile, $script );
    print
      "\n***WARN: Result is empty - Amibroker Didnt run for Symbol = $script\n"
      unless (@$result_array);
    print "Please report to developer - Seems Dates.txt is screwed\n\n"
      unless (@$result_array);
    $self->save_result_file( $type, $result_array, $script, 'RAW' );
    #
    # Step 15: Filter Result array
    #
    my $minprofit = $self->{min_profit_percent};
    my $mintrades = $self->{min_no_of_trades};
    my $minwinner = $self->{min_win_percent};
    my $resultSet =
      $self->filter_results( $type, $minprofit, $mintrades, $minwinner,
        $result_array );
    #
    # Step 16: To  sure we have sufficient data for selection
    #
    my $countFlg = 0;
    while ($#$resultSet < ( $self->{selection_index} * 3 )
        && $countFlg < ( $self->{selection_index} * 3 ) )
    {
        $minprofit = $minprofit - 3;
        $mintrades = $mintrades - 1;
        $minwinner = $minwinner - 1;
        $resultSet =
          $self->filter_results( $type, $minprofit, $mintrades, $minwinner,
            $result_array );
        $countFlg++;
    }

    # Step 17: If result set is less, then ignore that selection itself
    #

    if ( $#$resultSet < $self->{selection_index} ) {
        my $copyOptAfl_default = File::Slurp::read_file($copiedFile);
        my $selected =
          $self->get_the_default_values( $resultSet->[0], $copyOptAfl_default );
        $self->update_optimized_params(
            $selected,             # Values to update the afl
            $resultSet->[0],       # Header info of the result set
            $copiedFile,           # File path and the physical file
            $copyOptAfl_default    # File contents that needs modification
        );
        return 99;                 # No results number (user-defined)
    }
    #
    # Step 18: Save filtered list to file
    #
    $self->save_result_file( $type, $resultSet, $script, 'Filtered' );
    my ( $selected, $sorted_array ) = $self->sort_and_select($resultSet);
    $self->save_result_file( $type, $sorted_array, $script, 'Sorted' );
    #
    # Step 19: Copy again the AFL file and update the parameters in the file.
    #
    my $copyOptAfl = File::Slurp::read_file($copiedFile);
    $self->update_optimized_params(
        $selected,          # Values to update the afl
        $resultSet->[0],    # Header info of the result set
        $copiedFile,        # File path and the physical file
        $copyOptAfl         # File contents that needs modification
    );
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
# Supports only Two parameters updation
#
sub update_optimized_params {
    my ( $self, $selected, $header, $file, $slurpData ) = @_;
    my $paramName1  = $header->[3];
    my $paramName2  = $header->[4];
    my $paramValue1 = $selected->[3];
    my $paramValue2 = $selected->[4];
    $slurpData =~ s/optimize\(\"$paramName1\".*;/$paramValue1\;/;
    $slurpData =~ s/optimize\(\"$paramName2\".*;/$paramValue2\;/;

    File::Slurp::write_file( $file, $slurpData );
    return 1;
}

sub get_the_default_values {
    my ( $self, $header, $slurpData ) = @_;
    my $paramName1 = $header->[3];
    $slurpData =~ /$paramName1.*",([A-Za-z0-9]+)\,/;
    my $paramValue1 = $1;
    my $paramName2  = $header->[4];
    $slurpData =~ /$paramName2.*",([A-Za-z0-9]+)\,/;
    my $paramValue2 = $1;
    my @selected = ( 0, 0, 0, $paramValue1, $paramValue2 );
    return \@selected;
}

# Sorts the result set and selects only one row.
# Default sort is done for Profit% - You can add more in next release
#
sub sort_and_select {
    my ( $self, $result ) = @_;
    my $header = shift @$result;
    my @sorted = sort { $b->[0] <=> $a->[0] } @$result;
    my $selection;
    if ( $#sorted < $self->{selection_index} ) {
        $selection = $sorted[$#sorted];
    }
    else {
        $selection = $sorted[ $self->{selection_index} - 1 ];
    }
    unshift @$result, $header;
    return ( $selection, \@sorted );
}
#
# To save the results of hash to csv separated file.
#
sub save_result_file {
    my ( $self, $type, $result_array, $script, $extn ) = @_;
    my $file =
        $self->{_sandbox_path} . '\\'
      . $script . '-'
      . $self->{timeframe} . '-'
      . $type . '-'
      . $self->{optimizer_name} . '-'
      . $extn . '.csv';
    File::Path::make_path( $self->{_sandbox_path}, { verbose => 1 } )
      unless ( -d $self->{_sandbox_path} );
    open( my $SFH, '>', $file )
      or croak( '[ERROR] : Could not open file ' . $file . " $!\n" );
    $self->dump_data_to_file( $SFH, $result_array );
    close $SFH;
    return 1;
}
#
# Saving the data to file
#
sub dump_data_to_file {
    my ( $self, $FH, $result_array ) = @_;
    foreach (@$result_array) {
        print $FH join ",", @$_;
        print $FH "\n";
    }
    return 1;
}
#
# Logic to filter the result set
#
sub filter_results {
    my ( $self, $type, $minprofit, $mintrades, $minwinner, $result_array ) = @_;
    if ( $type eq 'TIME' ) {
        $result_array = $self->clear_unwanted_timings( $result_array, 3 )
          ;    # clean FirstTradeTime
        $result_array = $self->clear_unwanted_timings( $result_array, 4 )
          ;    # clean LastTradeTime
    }
    #
    # Filter minimum profits % - array index is 0
    $result_array = $self->recursive_filter( $result_array, $minprofit, 0 );
    #
    # Filter minimum number of trades - array index is 1
    $result_array = $self->recursive_filter( $result_array, $mintrades, 1 );
    #
    # Filter minimum winners % - array index is 2
    $result_array = $self->recursive_filter( $result_array, $minwinner, 2 );
    return $result_array;
}
#
# Optimization results has timings that are from 1 to 100, we want just 1 to 60.
#
sub clear_unwanted_timings {
    my ( $self, $result_array, $index ) = @_;
    my @temp = @$result_array;
    for ( my $i = $#temp ; $i > 0 ; $i-- ) {
        unless ( $self->check_if_in_time_range( \@temp, $i, $index ) ) {
            splice( @temp, $i, 1 );
        }
    }
    return \@temp;
}

sub check_if_in_time_range {
    my ( $self, $temp, $i, $index ) = @_;
    return 1
      if ( $temp->[$i]->[$index] >= 91500 && $temp->[$i]->[$index] <= 95500 );
    return 1
      if ( $temp->[$i]->[$index] >= 100000 && $temp->[$i]->[$index] <= 105500 );
    return 1
      if ( $temp->[$i]->[$index] >= 110000 && $temp->[$i]->[$index] <= 115500 );
    return 1
      if ( $temp->[$i]->[$index] >= 120000 && $temp->[$i]->[$index] <= 125500 );
    return 1
      if ( $temp->[$i]->[$index] >= 130000 && $temp->[$i]->[$index] <= 135500 );
    return 1
      if ( $temp->[$i]->[$index] >= 140000 && $temp->[$i]->[$index] <= 145500 );
    return 1
      if ( $temp->[$i]->[$index] >= 150000 && $temp->[$i]->[$index] <= 151000 );
    return 0;    # return 0 if nothing fits
}

#
# Call the filtering engine
#
sub recursive_filter {
    my ( $self, $result_array, $min_value, $index ) = @_;
    my @temp = @$result_array;

    for ( my $i = $#temp ; $i > 0 ; $i-- ) {
        splice( @temp, $i, 1 ) if ( $temp[$i]->[$index] < $min_value );
    }
    return \@temp;
}

#
# Copy a given file
#
sub copy_file {
    my ( $self, $source, $destination, $timeframe, $optname, $script ) = @_;
    my $final =
        $destination . '\\'
      . $script . '-'
      . $timeframe . '-'
      . $optname . '.afl';
    File::Copy::copy( $source, $final )
      or croak( '[ERROR] : Copy failed: ' . "$!" );
    return $final;
}

#
# Clean up the sandbox for allowing fresh optimize to run
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
# Load the result file generated by Amibroker engine
#
sub load_result_file {
    my ( $self, $resultFile ) = @_;
    my @raw = File::Slurp::read_file($resultFile);
    my @result;
    foreach (@raw) {
        chomp($_);
        my @temp = split( /,/, $_ );
        splice @temp, 0, 2;
        splice @temp, 1, 18;
        splice @temp, 2, 4;
        splice @temp, 3, 10;
        push( @result, \@temp );
    }
    return \@result;
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
          timeframe
          symbol
          afl_template
          lot_size
          log_path
          optimizer_name
          min_win_percent
          min_profit_percent
          min_no_of_trades
          selection_index
          profit_from
          profit_to
          profit_incr
          optimize_time
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
# Explicitly call the destructor
#
sub DESTROY {
    my $self   = shift;
    my $broker = $self->{_broker};
    $broker->shutdown_amibroker_engine() if ( $self->{_broker} );
    $self->copy_sandbox();
 #   $self->clear_sandbox();
    return 1;
}

1;    # End of Amibroker::AFL::Optimizer

__END__


=head1 NAME

Amibroker::AFL::Optimizer - Auto Optimizer framework for ALL Stocks across ALL timeframe in Amibroker.

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Amibroker::AFL::Optimizer;

    my $obj = Amibroker::AFL::Optimizer->new( {
								dbpath => 'C:/amibroker/dbpath',
								destination_path => 'C:/finalreports/today',
								timeframe => '5-minute',
								optimizer_name => 'EMA',
								afl_template=> 'C:/amibroker/formulas/custom/myema.afl',
								symbol => 'NIFTY-I',
								lot_size => '50',
	});
    $obj->start_optimizer();

=head2 new() [constructor]

Minimum 7 mandatory parameters are required for the amibroker optimizer to run.

    my $obj = Amibroker::AFL::Optimizer->new( {
							dbpath => 'amibroker_database_path',
							destination_path => 'final_path_where_afls_will_be_dumped',
							timeframe => 'timeframe',
							optimizer_name => 'Name_for_this_optimization',
							afl_template=> 'afl_template_file_that_requires_optimization',
							symbol => 'symbol',
							lot_size => 'symbol_lot_size',
						});

=head3 Required Parameters

=over 6

=item B<dbpath>

	Amibroker database path

=item B<destination_path>

	Amibroker destination_path is where finally the optimized afls are dumped.

=item B<timeframe>

You have to specifiy to which timeframe do you want to run the optimizer
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
	ALL

	ALL - Timeframe is supported, this will optimize the afl for all the above given timeframes

=item B<symbol>

Accepts any symbols name as present in your amibroker database.
B<CAUTION:> Symbol names should exactly match the symbols present in your amibroker database, else this optimization will fail.

=item B<afl_template>

AFL template file that needs auto optimization, you have give the complete path to that afl_template file.

=item B<lot_size>

Lot size for that symbol

=back

=head3 Optional Parameters

=over 13

=item B<log_path>

Path to the logs. If this parameter is not specified, then no logs will be stored.
The logs will contain all the results of the amibroker run and the apx file that was sent to the engine, 
so it helps in verifying the parameters that were passed to the amibroker engine and the output results.

=item B<optimizer_name>

You can give any name, but it should be relevant to the optimize that you are running.
	Eg: If you are running for ATR then give the name as optimizer_name => 'ATR'
	    Similarly for EMA, BollingerBands ..etc, it is just user-defined variable, which helps in identifying the optimization run
		All the AFL files generated will have this optimizer_name appended to your AFL file name, so this helps in easy identification.

=item B<min_win_percent>

Provide the minimum winning percentage you are expecting from the afl template optimization.
Default will be 40%

=item B<min_profit_percent>

Provide the minimum profit percentage you are expecting from the afl template optimization.
Default will be 50%

=item B<min_no_of_trades>

Provide the minimum number of trades you are expecting from the afl template optimization.
Default will be 10

=item B<selection_index>

The row that you want to pick up in the optimization result.
As a normal practise, it is advised not to pick up trades that gives the maximum profit as it will result in curve-fitting.
And the optimized values will not behave as expected in the optimized results.
So, it is better to give a range from 5 to 15.
Default will be 2

=item B<profit_from>

when lotsize is multiplied with the price then we get the actual profit/loss.
profit/loss is in currency. For ease, i will take INR (indian rupees), 
B<NOTE:> It works for all currencies

During optimization process, we specifiy profit limits, so that our trades gets squared off when the profit limit is reached.
Now, we do not know at what profit levels do we get the best profitable results.
So, during optimization we want to create files that ranges for different profit levels, so that when we run backtest for that afl, 
we get to see the actual backtested results.

profit_from specifies the lowest profit limit
Default will be 0

=item B<profit_to>

profit_from specifies the highest profit limit
Default will be 20000 (so the maximum profit per trade is 20000 INR in this case)

=item B<profit_incr>

profit_incr specifies the increment value.
Default will be 5000
So, AFL files will be created with trade profit targets for every 5000 INR.

=item B<optimize_time>

If you want to optimize the AFL for different timeframe then give 'YES', else ignore it.
	Eg: If your strategy works between 2:00 PM to 3:00 PM, then use this parameter, 
	It will tell you which is the best timeframe during which your afl gave maximum profits.

=item B<margin_amt>

Margin amount as for that symbol as specified by broker/exchange.

=item B<from>

From date

=item B<to>

To date, 
either specify both from and to dates or none should be specified.

=back

=head2 start_optimizer()

	$obj->start_optimizer();

Starts the optimizer. It internally calls Amibroker::OLE::Interface to connect to Amibroker engine.
Usually every run takes around 1 minute to 5 minute, depending on the size of your amibroker database.

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

