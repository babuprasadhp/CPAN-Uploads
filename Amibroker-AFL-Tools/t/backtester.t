#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { use_ok('Amibroker::AFL::Backtester'); }
#
# Checking with right parameters
#
my $obj1 = Amibroker::AFL::Backtester->new( { 
								dbpath => 'C:\TradingTools\Amibroker5.90.1\InOutData',
								destination_path => 'C:\TradingTools',
								source_path => 'C:\TradingTools',
								timeframe => '5-minute',
								backtester_name => 'EMA',
								symbol => 'NIFTY-I',
	} );
isa_ok( $obj1, 'Amibroker::AFL::Backtester' );


#
# Wrong parameters passed
#
eval { my $obj3 = Amibroker::AFL::Backtester->new( { test => 1 } ); };
pass('Not accepting wrong parameters') if ($@);

done_testing();

