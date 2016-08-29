#!C://DevTools//Perl//bin//perl.exe

use strict;
use warnings;
use Tk;
use Tk::BrowseEntry;
use FindBin;
use Win32::Console;
Win32::Console::Free();

=head1 NAME

RunBacktesterGUI.pl - Auto Bcktester Desktop UI Script to run Backtesting.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

#Global Variables
my $DEFAULT_DATABASE      = 'C:\TradingTools\Amibroker5.90.1';
my $DEFAULT_DATABASE_PATH = 'C:\TradingTools\Amibroker5.90.1\InOutData';
my $DEFAULT_SOURCE        = 'C:\BabuDevProjects\AmiBackTester\Test\Hourly-UZ';
my $DEFAULT_DESTINATION   = 'C:\BabuDevProjects\AmiBackTester\Test\Hourly-UZ';
my $radio_variable        = 'Yes';
my $dest_disable_flag     = 1;
my $SELECTED_TIMEFRAME    = '';           # Default no entries
my $SELECTED_OUT_OF_SAMPLE_MONTHS = '6-Months';

#
# Main GUI Window
#
my $mainFrame = MainWindow->new(
    -background => 'lightyellow',
    -title      => 'Amibroker backtester'
);
my $headerFrame = $mainFrame->Frame();
my $inputFrame  = $mainFrame->Frame( -borderwidth => 5, -relief => 'ridge' );
my $logFrame    = $mainFrame->Frame( -background => 'lightyellow' );

#
# GUI Building Area
#
# Header
my $headLabel = $headerFrame->Label(
    -background => 'lightyellow',
    -text       => 'Amibroker Backtester Software',
    -foreground => 'brown'
);
$headLabel->configure(
    -font => [
        -family => 'CourierNew',
        -size   => 20,
        -weight => 'bold'
    ]
);

# Database
my $dbLabel   = $inputFrame->Label( -text => "Database Path:" );
my $dbTextBox = $inputFrame->Entry( -text => $DEFAULT_DATABASE_PATH, -width => 50 );
my $dbbutton  = $inputFrame->Button( -text => 'Browse DB', -command => \&pick_database );

# Source Directory
my $srcLabel   = $inputFrame->Label( -text => "Source AFL Path:" );
my $srcTextBox = $inputFrame->Entry( -text => $DEFAULT_SOURCE, -width => 80 );
my $srcbutton  = $inputFrame->Button( -text => 'Browse Source', -command => \&pick_source );

# Radio buttons
my $radLabel   = $inputFrame->Label( -text => "Is Destination same as Source ?" );
my $radbutton1 = $inputFrame->Radiobutton(
    -text     => "Yes",
    -value    => "Yes",
    -variable => \$radio_variable,
    -command  => \&disable_destination
);
my $radbutton2 = $inputFrame->Radiobutton(
    -text     => "No",
    -value    => "No",
    -variable => \$radio_variable,
    -command  => \&enable_destination
);

# Combo Box
my @TFitems = (
    '3-Minute',  '5-Minute',  '7-Minute',  '10-Minute',
    '12-Minute', '15-Minute', '20-Minute', 'Hourly',
    'Daily'
);
my $TFCombo = $inputFrame->BrowseEntry(
    -label      => 'TimeFrame :',
    -variable   => \$SELECTED_TIMEFRAME,
    -style      => 'MSWin32',
    -background => 'lightpink',
    -foreground => 'black'
);
my $TFList = $TFCombo->Subwidget('slistbox');
$TFList->insert( 'end', @TFitems );

my @OSItems = (
    '2-Months',  '3-Months',  '4-Months', '5-Months',
    '6-Months',  '7-Months',  '8-Months', '9-Months',
    '10-Months', '11-Months', '12-Months'
);
my $OSCombo = $inputFrame->BrowseEntry(
    -label    => 'Out of Sample Report :',
    -variable => \$SELECTED_OUT_OF_SAMPLE_MONTHS,
    -style    => 'MSWin32'
);
my $OSList = $OSCombo->Subwidget('slistbox');
$OSList->insert( 'end', @OSItems );

# Destination Directory
my $destLabel   = $inputFrame->Label( -text => "Destination Reports Path:" );
my $destTextBox = $inputFrame->Entry( -text => $DEFAULT_DESTINATION, -width => 80, );
my $destbutton  = $inputFrame->Button(
    -text    => 'Browse Destination',
    -command => \&pick_destination
);
$destLabel->configure( -state => 'disabled' );
$destTextBox->configure( -state => 'disabled' );
$destbutton->configure( -state => 'disabled' );

# Logging Area

my $logLabel = $logFrame->Label( -text => "Log info:", -background => 'grey' );
my $logTextArea = $logFrame->Scrolled(
    'Text',
    -width      => 85,
    height      => 12,
    -scrollbars => 'soe',
    -foreground => 'blue',
    -background => 'white',
    -wrap       => 'none'
);
my $startApp = $logFrame->Button(
    -height      => 2,
    -width       => 20,
    -borderwidth => 3,
    -text        => 'READY',
    -command     => \&start_app
);
my $runApp = $logFrame->Button(
    -height      => 2,
    -width       => 20,
    -borderwidth => 3,
    -text        => 'RUN BACKTEST',
    -command     => \&run_app
);
$runApp->configure( -state => 'disabled' );
my $cancelApp = $logFrame->Button(
    -height      => 2,
    -width       => 20,
    -borderwidth => 3,
    -text        => 'ABORT',
    -command     => sub { exit }
);

#
# Geometry Management
#
$mainFrame->geometry('980x650+20+20');
$headerFrame->grid(
    -row        => 1,
    -column     => 1,
    -columnspan => 2,
    -padx       => 30,
    -pady       => 30,
    -sticky     => 'n'
);
$inputFrame->grid(
    -row        => 2,
    -column     => 1,
    -columnspan => 2,
    -padx       => 30,
    -pady       => 20
);
$logFrame->grid(
    -row        => 3,
    -column     => 1,
    -columnspan => 2,
    -padx       => 30,
    -pady       => 10,
    -sticky     => 's'
);

# Sub Grid 1 - Header
$headLabel->grid( -row => 1, -column => 1 );

# Sub Grid 2 - Input
$dbLabel->grid(
    -row    => 1,
    -column => 1,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$dbTextBox->grid(
    -row    => 1,
    -column => 2,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$dbbutton->grid(
    -row    => 1,
    -column => 3,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$srcLabel->grid(
    -row    => 2,
    -column => 1,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$srcTextBox->grid(
    -row    => 2,
    -column => 2,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$srcbutton->grid(
    -row    => 2,
    -column => 3,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$radLabel->grid(
    -row    => 3,
    -column => 1,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$radbutton1->grid(
    -row    => 3,
    -column => 2,
    -sticky => 'w',
    -padx   => 10,
    -pady   => 5
);
$radbutton2->grid(
    -row    => 3,
    -column => 2,
    -sticky => 'e',
    -padx   => 90,
    -pady   => 5
);
$TFCombo->grid(
    -row    => 4,
    -column => 2,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$OSCombo->grid(
    -row    => 5,
    -column => 2,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$destLabel->grid(
    -row    => 6,
    -column => 1,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$destTextBox->grid(
    -row    => 6,
    -column => 2,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$destbutton->grid(
    -row    => 6,
    -column => 3,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);

# Sub Grid 3 - Logging
$logLabel->grid( -row => 1, -column => 1 );
$logTextArea->grid( -row => 2, -column => 1 );
$startApp->grid(
    -row    => 2,
    -column => 2,
    -sticky => 'nw',
    -padx   => 15,
    -pady   => 5
);
$runApp->grid( -row => 2, -column => 2, -padx => 15, -pady => 5 );
$cancelApp->grid(
    -row    => 2,
    -column => 2,
    -sticky => 'sw',
    -padx   => 15,
    -pady   => 5
);

MainLoop;    ### MAIN GUI APP ENDS HERE ###

sub start_app {
    $SELECTED_TIMEFRAME = $SELECTED_TIMEFRAME || 'NONE-SELECTED';
    $dbLabel->configure( -state => 'disabled' );
    $dbTextBox->configure( -state => 'disabled' );
    $dbbutton->configure( -state => 'disabled' );
    $srcLabel->configure( -state => 'disabled' );
    $srcTextBox->configure( -state => 'disabled' );
    $srcbutton->configure( -state => 'disabled' );
    $destLabel->configure( -state => 'disabled' );
    $destTextBox->configure( -state => 'disabled' );
    $destbutton->configure( -state => 'disabled' );
    $radLabel->configure( -state => 'disabled' );
    $radbutton1->configure( -state => 'disabled' );
    $radbutton2->configure( -state => 'disabled' );
    $TFCombo->configure( -state => 'disabled' );
    $OSCombo->configure( -state => 'disabled' );
    $startApp->configure( -state => 'disabled' );
    $runApp->configure(
        -state      => 'normal',
        -foreground => 'Blue',
        -background => 'Green'
    );

    $logTextArea->insert( 'end',
        "DATABASE PATH     : $DEFAULT_DATABASE_PATH\n" );
    $logTextArea->insert( 'end', "SOURCE PATH       : $DEFAULT_SOURCE\n" );
    $logTextArea->insert( 'end', "DESTINATION PATH  : $DEFAULT_DESTINATION\n" );
    $logTextArea->insert( 'end', "TIMEFRAME         : $SELECTED_TIMEFRAME\n" );
    $logTextArea->insert( 'end',
        "OUT-OF-SAMPLE MNT : $SELECTED_OUT_OF_SAMPLE_MONTHS\n" );

    my $status = $logFrame->Label(
        -text       => "BACKTEST READY\n",
        -background => 'lightyellow',
        -foreground => 'Red'
    );
    $status->grid( -row => 2, -column => 2, -sticky => 'nw', -padx => 12 );
    $status->configure(
        -font => [ -size => 12, -family => 'Cambria', -weight => 'bold' ] );
    return 1;        
}

sub run_app {
    my $answer = $mainFrame->Dialog(
        -title   => 'Please Reply',
        -text    => 'Would you like to continue?',
        -buttons => [ 'YES', 'NO' ],
        -bitmap  => 'question'
    )->Show();
    if ( $answer eq 'YES' ) {
        my $command =
            "$FindBin::Bin\\Backtester.pl  "
          . "-database     $DEFAULT_DATABASE_PATH  "
          . "-source       $DEFAULT_SOURCE  "
          . "-destination  $DEFAULT_DESTINATION  "
          . "-timeframe    $SELECTED_TIMEFRAME  "
          . "-outofsample  $SELECTED_OUT_OF_SAMPLE_MONTHS  ";
        $logTextArea->insert( 'end', "\nRunning command\n$command\n" );
        system("perl $command");
        enable_all();
    }
    elsif ( $answer eq 'NO' ) {
        my $status = $logFrame->Label(
            -text       => "TEST ABORTED***",
            -background => 'lightyellow',
            -foreground => 'Brown'
        );
        $status->grid( -row => 2, -column => 2, -sticky => 'nw', -padx => 12 );
        $status->configure(
            -font => [ -size => 12, -family => 'Cambria', -weight => 'bold' ] );
    }
    return 1;
}

sub enable_all {
    my $status = $logFrame->Label(
        -text       => "   COMPLETED   ",
        -background => 'lightyellow',
        -foreground => 'DarkGreen'
    );
    $status->grid( -row => 2, -column => 2, -sticky => 'nw', -padx => 12 );
    $status->configure(
        -font => [ -size => 14, -family => 'Cambria', -weight => 'bold' ] );
    $dbLabel->configure( -state => 'normal' );
    $dbTextBox->configure( -state => 'normal' );
    $dbbutton->configure( -state => 'normal' );
    $srcLabel->configure( -state => 'normal' );
    $srcTextBox->configure( -state => 'normal' );
    $srcbutton->configure( -state => 'normal' );
    $radLabel->configure( -state => 'normal' );
    $radbutton1->configure( -state => 'normal' );
    $radbutton2->configure( -state => 'normal' );
    $TFCombo->configure( -state => 'normal' );
    $OSCombo->configure( -state => 'normal' );
    $startApp->configure( -state => 'normal' );
    return 1;
}

sub enable_destination {
    $dest_disable_flag = 0;
    $destLabel->configure( -state => 'normal' );
    $destTextBox->configure( -state => 'normal' );
    $destbutton->configure( -state => 'normal' );
    return 1;
}

sub disable_destination {
    $dest_disable_flag = 1;
    $destTextBox->delete( 0, 100 );
    $destTextBox->insert( 0, $srcTextBox->get() );
    $destLabel->configure( -state => 'disabled' );
    $destTextBox->configure( -state => 'disabled' );
    $destbutton->configure( -state => 'disabled' );
    return 1;
}

sub pick_database {
    my $mypick = browse_folder($DEFAULT_DATABASE);
    if ($mypick) {
        $mypick =~ s/\//\\/g;
        $dbTextBox->delete( 0, 100 );
        $dbTextBox->insert( 0, $mypick );
        $DEFAULT_DATABASE_PATH = $mypick;
    }
    return 1;    
}

sub pick_source {
    my $mypick = browse_folder($DEFAULT_SOURCE);
    if ($mypick) {
        $mypick =~ s/\//\\/g;
        $srcTextBox->delete( 0, 100 );
        $srcTextBox->insert( 0, $mypick );
        $DEFAULT_SOURCE = $mypick;
        if ($dest_disable_flag) {
            $destTextBox->configure( -state => 'normal' );
            $destTextBox->delete( 0, 100 );
            $destTextBox->insert( 0, $mypick );
            $destTextBox->configure( -state => 'disabled' );
            $DEFAULT_DESTINATION = $mypick;
        }
    }
    return 1;    
}

sub pick_destination {
    my $mypick = browse_folder($DEFAULT_DESTINATION);
    if ($mypick) {
        $mypick =~ s/\//\\/g;
        $destTextBox->delete( 0, 100 );
        $destTextBox->insert( 0, $mypick );
        $DEFAULT_DESTINATION = $mypick;
    }
    return 1;    
}

sub browse_folder {
    my $defaultDir = shift;
    my $dir        = $mainFrame->chooseDirectory(
        -initialdir => $defaultDir,
        -title      => 'Choose a folder'
    );
    if ( !defined $dir ) {
        return 0;
    }
    return $dir;
}
