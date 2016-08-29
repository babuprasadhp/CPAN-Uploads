use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Amibroker::AFL::Tools',
    AUTHOR           => q{Babu Prasad HP <bprasad@cpan.org>},
    VERSION_FROM     => 'lib/Amibroker/AFL/Tools.pm',
    ABSTRACT_FROM    => 'lib/Amibroker/AFL/Tools.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => { 'script/Ami-optimizer.pl', 
						  'script/Ami-backtester.pl',  
						  'script/RunOptimizerGUI.pl', 
						  'script/RunBackterGUI.pl'},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
		'File::Path' => 2.09,
		'File::Copy::Recursive' => 0.38,
		'File::Slurp'	=> 9999.19,
		'Win32::API'  => 0.79,
		'Path::Tiny'  => 0.061,
		'Math::Round' => 0.07,
		'Carp' => 0,
		'Getopt::Long' => 2.44,
		'Audio::Beep' => 0.11,
		'Tk' => 804.003,
		'Tk::BrowseEntry' => 0,
		'Tk::Dialog' => 4.005,
		'Win32::Console' => 0.10,
		'Amibroker::OLE::Interface'  => 0.03,
		'Amibroker::OLE::APXCreator' => 0.03
    },
	TEST_REQUIRES => {
		'Test::More' => 1.001014,
		'FindBin'	 => 0,
	},
	test => {
		'TESTS' => "t/*.t",
	},	
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Amibroker-AFL-Tools-*' },
);
