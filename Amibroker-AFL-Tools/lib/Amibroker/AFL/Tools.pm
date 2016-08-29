package Amibroker::AFL::Tools;

use 5.006;
use strict;
use warnings

=head1 NAME

Amibroker::AFL::Tools - Auto Optimizer and Auto Backtester framework for Amibroker

=head1 VERSION

Version 0.03

=head1 DESCRIPTION

Amibroker::AFL::Tools comprises of both Optimizer and Backtester framework, that helps perform continous
Optimizing and backtesting for all Stocks/Futures/Options/Commodities/Spot and for all Timeframes.

Amibroker::AFL::Optimizer  - Optimizer framework to perform continous Optimization
Amibroker::AFL::Backtester - Backtester framework to perform continous Backtesting

Backtesting is manily useful when you want to perform contract wise backtesting and check for monthly actual profits/losses.
The results are acurate and provide a clear insight on the capability of your strategy.

Please check these below modules for more information:

Amibroker::AFL::Optimizer  - L<http://search.cpan.org/~bprasad/Amibroker-AFL-Tools-0.01/lib/Amibroker/AFL/Optimizer.pm>
Amibroker::AFL::Backtester - L<http://search.cpan.org/~bprasad/Amibroker-AFL-Tools-0.01/lib/Amibroker/AFL/Backtester.pm>

To understand the power of contious automotive framework, please download the scripts,

Ami-Optimizer.pl
Ami-Backtester.pl

There are two more scripts that has desktop UI written using Perl TK.

RunOptimizeGUI.pl
RunBacktestGUI.pl

=cut

our $VERSION = '0.03';

1;    # End of Amibroker::AFL::Tools
