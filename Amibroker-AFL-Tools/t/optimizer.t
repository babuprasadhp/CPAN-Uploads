#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { use_ok('Amibroker::AFL::Optimizer'); }
#
# Checking with right parameters
#
my $obj1 = Amibroker::AFL::Optimizer->new( { 
								dbpath => 'C:\TradingTools\Amibroker5.90.1\InOutData',
								destination_path => 'C:\TradingTools',
								timeframe => '5-minute',
								optimizer_name => 'EMA',
								afl_template=> 'C:/amibroker/formulas/custom/myema.afl',
								symbol => 'NIFTY-I',
								lot_size => '50'
	} );
isa_ok( $obj1, 'Amibroker::AFL::Optimizer' );


#
# Wrong parameters passed
#
eval { my $obj3 = Amibroker::AFL::Optimizer->new( { test => 1 } ); };
pass('Not accepting wrong parameters') if ($@);

done_testing();

