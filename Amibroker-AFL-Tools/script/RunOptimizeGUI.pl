#!C://DevTools//Strawberry//Perl//bin//perl.exe

use strict;
use warnings;
use Tk;
use Tk::BrowseEntry;
use Tk::Dialog;
use FindBin;
use Win32::Console;

=head1 NAME

RunOptimizeGUI.pl - Auto Optimizer Desktop UI Script to run optimization.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

#
# Global Variables
#
$FindBin::Bin                  =~ s/\//\\/g;    # Replace slashes as per windows convinence
my $DEFAULT_DATABASE           = "$FindBin::Bin";
my $DEFAULT_DATABASE_PATH      = "$FindBin::Bin";
my $DEFAULT_DESTINATION_PATH   = "$FindBin::Bin";
my $DEFAULT_AFL_TEMPLATE_PATH  = "$FindBin::Bin";
my $SELECTED_TIMEFRAME         = 'ALL';    # Default no entries
my $MARGIN_FILE_PATH           = "$FindBin::Bin\\..\\rules\\ScriptDetails.txt";
my $SELECTED_SYMBOL            = '';
my $STRATEGY_TEXT              = '';
my $SELECTED_SEL_INDEX         = 'Default';
my $SELECTED_MIN_WINNERS       = 'Default';
my $SELECTED_MIN_PROFITS       = 'Default';
my $SELECTED_MIN_TRADES        = 'Default';
my $SELECTED_PROFITS_FROM      = 'Default';
my $SELECTED_PROFITS_TO        = 'Default';
my $SELECTED_PROFITS_INCREMENT = 'Default';
my $OPTIMIZE_TIME              = 'Yes';

#
# Main GUI Window
#
my $mainFrame = MainWindow->new(
    -background => 'lightblue',
    -title      => 'Amibroker Optimizer'
);
my $headerFrame = $mainFrame->Frame();
my $inputFrame  = $mainFrame->Frame( -borderwidth => 5, -relief => 'ridge' );
my $logFrame    = $mainFrame->Frame( -background => 'lightblue' );

#
# GUI Building Area
#
# Header
my $headLabel = $headerFrame->Label(
    -background => 'lightblue',
    -text       => 'Amibroker Optimizer Program',
    -foreground => 'brown'
);
$headLabel->configure(
    -font => [
        -family => 'CourierNew',
        -size   => 20,
        -weight => 'bold'
    ]
);
#
# Enter Database Path
#
my $dbLabel   = $inputFrame->Label( -text => "Database Path:" );
my $dbTextBox = $inputFrame->Entry( -text => $DEFAULT_DATABASE_PATH, -width => 80 );
my $dbbutton  = $inputFrame->Button( -text => 'Browse DB', -command => \&pick_database );
#
# Enter Destination Directory
#
my $destLabel   = $inputFrame->Label( -text => "Destination AFL Dump Path:" );
my $destTextBox = $inputFrame->Entry( -text => $DEFAULT_DESTINATION_PATH, -width => 80 );
my $destbutton  = $inputFrame->Button( -text => 'Browse Path', -command => \&pick_destination );
#
# Enter Source Directory
#
my $tempLabel   = $inputFrame->Label( -text => "AFL Template Path:" );
my $tempTextBox = $inputFrame->Entry( -text => $DEFAULT_AFL_TEMPLATE_PATH, -width => 80 );
my $tempbutton  = $inputFrame->Button( -text => 'Pick File', -command => \&pick_templdate );
#
# Enter Strategy Abbrevated name
#
my $StrategyLabel = $inputFrame->Label( -text => 'Stategy Name :' );
my $StrategyInput = $inputFrame->Text( -width => 30, -height => 1 );
#
# Radio buttons
#
my $optTimeLabel   = $inputFrame->Label( -text => "Optimize for Entry Time?" );
my $optTimebutton1 = $inputFrame->Radiobutton(
    -text     => "Yes",
    -value    => "Yes",
    -variable => \$OPTIMIZE_TIME,
);
my $optTimebutton2 = $inputFrame->Radiobutton(
    -text     => "No",
    -value    => "No",
    -variable => \$OPTIMIZE_TIME,
);
#
# Pick TimeFrame [Combo Box]
#
my @TFitems = (
    'ALL',       '3-Minute',  '5-Minute',  '7-Minute',
    '10-Minute', '12-Minute', '15-Minute', '20-Minute',
    'Hourly'
);
my $TFCombo = $inputFrame->BrowseEntry(
    -label    => 'TimeFrame :',
    -variable => \$SELECTED_TIMEFRAME,
    -style    => 'MSWin32'
);
my $TFList = $TFCombo->Subwidget('slistbox');
$TFList->insert( 'end', @TFitems );
$TFList->configure( -height => 9 );
#
# Pick Symbol [Combo Box]
#
my @SymbolList   = ();
my $MARGINS_LIST = read_config_file($MARGIN_FILE_PATH);
foreach ( sort keys %{$MARGINS_LIST} ) {
    push( @SymbolList, $_ );
}

my $SymbolCombo = $inputFrame->BrowseEntry(
    -label      => 'Symbol :',
    -variable   => \$SELECTED_SYMBOL,
    -style      => 'MSWin32',
    -background => 'lightpink',
    -foreground => 'black'
);
my $SymbolList = $SymbolCombo->Subwidget('slistbox');
$SymbolList->insert( 'end', 'ALL' );
$SymbolList->insert( 'end', @SymbolList );
#
# Pick SelectionIndex [Combo Box]
#
my @SIItems = ( '3', '6', '9', '10', '12', '15', '17', '20' );
my $SICombo = $inputFrame->BrowseEntry(
    -label    => 'Selection Index (No.):',
    -variable => \$SELECTED_SEL_INDEX,
    -style    => 'MSWin32'
);
my $SIList = $SICombo->Subwidget('slistbox');
$SIList->insert( 'end', @SIItems );
$SIList->configure( -height => 5 );
#
# Pick Minimum Win [Combo Box]
#
my @MinWinItems = ( '45', '50', '55', '60', '65', '70', '75' );
my $MinWinCombo = $inputFrame->BrowseEntry(
    -label    => 'Minimum Win%     :',
    -variable => \$SELECTED_MIN_WINNERS,
    -style    => 'MSWin32'
);
my $MinWinList = $MinWinCombo->Subwidget('slistbox');
$MinWinList->insert( 'end', @MinWinItems );
$MinWinList->configure( -height => 7 );
#
# Pick Minimum Profit [Combo Box]
#
my @MinProfItems = ( '25', '50', '75', '100', '125', '150', '200', '250' );
my $MinProfCombo = $inputFrame->BrowseEntry(
    -label    => 'Minimum Profits%  :',
    -variable => \$SELECTED_MIN_PROFITS,
    -style    => 'MSWin32'
);
my $MinProfList = $MinProfCombo->Subwidget('slistbox');
$MinProfList->insert( 'end', @MinProfItems );
$MinProfList->configure( -height => 8 );
#
# Pick Minimum Trades [Combo Box]
#
my @MinTradesItems = ( '25', '30', '50', '80', '100', '150', '200' );
my $MinTradesCombo = $inputFrame->BrowseEntry(
    -label    => 'Minimum Trades   :',
    -variable => \$SELECTED_MIN_TRADES,
    -style    => 'MSWin32'
);
my $MinTradesList = $MinTradesCombo->Subwidget('slistbox');
$MinTradesList->insert( 'end', @MinTradesItems );
$MinTradesList->configure( -height => 7 );
#
# Pick Profits From (Rs) [Combo Box]
#
my @ProfitsFromItems = ( '0', '1000', '2000', '3000', '4000', '5000' );
my $ProfitsFromCombo = $inputFrame->BrowseEntry(
    -label    => 'Profits From (Rs) :',
    -variable => \$SELECTED_PROFITS_FROM,
    -style    => 'MSWin32'
);
my $ProfitsFromList = $ProfitsFromCombo->Subwidget('slistbox');
$ProfitsFromList->insert( 'end', @ProfitsFromItems );
$ProfitsFromList->configure( -height => 6 );
#
# Pick Profits To (Rs) [Combo Box]
#
my @ProfitsToItems =
  ( '10000', '15000', '20000', '25000', '30000', '35000', '40000' );
my $ProfitsToCombo = $inputFrame->BrowseEntry(
    -label    => 'Profits To (Rs) :',
    -variable => \$SELECTED_PROFITS_TO,
    -style    => 'MSWin32'
);
my $ProfitsToList = $ProfitsToCombo->Subwidget('slistbox');
$ProfitsToList->insert( 'end', @ProfitsToItems );
$ProfitsToList->configure( -height => 7 );
#
# Pick Profits in Increments (Rs) [Combo Box]
#
my @ProfitsIncrItems = ( '0', '500', '1000', '1500', '2000', '3000', '4000', '5000' );
my $ProfitsIncrCombo = $inputFrame->BrowseEntry(
    -label    => 'Profits Incr(Rs) :',
    -variable => \$SELECTED_PROFITS_INCREMENT,
    -style    => 'MSWin32'
);
my $ProfitsIncrList = $ProfitsIncrCombo->Subwidget('slistbox');
$ProfitsIncrList->insert( 'end', @ProfitsIncrItems );
$ProfitsIncrList->configure( -height => 6 );
#
# Logging Area
#
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
    -text        => 'RUN OPTIMIZER',
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
    -pady       => 20,
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
#
# Sub Grid 1 - Header
#
$headLabel->grid( -row => 1, -column => 1 );
#
# Sub Grid 2 - Input
#
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
$destLabel->grid(
    -row    => 2,
    -column => 1,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$destTextBox->grid(
    -row    => 2,
    -column => 2,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$destbutton->grid(
    -row    => 2,
    -column => 3,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$tempLabel->grid(
    -row    => 3,
    -column => 1,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$tempTextBox->grid(
    -row    => 3,
    -column => 2,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$tempbutton->grid(
    -row    => 3,
    -column => 3,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$optTimeLabel->grid(
    -row    => 4,
    -column => 1,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$optTimebutton1->grid(
    -row    => 4,
    -column => 2,
    -sticky => 'w',
    -padx   => 10,
    -pady   => 5
);
$optTimebutton2->grid(
    -row    => 4,
    -column => 2,
    -sticky => 'e',
    -padx   => 90,
    -pady   => 5
);
$StrategyLabel->grid(
    -row    => 5,
    -column => 1,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$StrategyInput->grid(
    -row    => 5,
    -column => 2,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$TFCombo->grid(
    -row    => 5,
    -column => 2,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$SymbolCombo->grid(
    -row    => 6,
    -column => 2,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$SICombo->grid(
    -row    => 6,
    -column => 2,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$MinWinCombo->grid(
    -row    => 7,
    -column => 2,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$MinProfCombo->grid(
    -row    => 8,
    -column => 2,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$MinTradesCombo->grid(
    -row    => 9,
    -column => 2,
    -sticky => 'w',
    -padx   => 5,
    -pady   => 5
);
$ProfitsFromCombo->grid(
    -row    => 7,
    -column => 2,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$ProfitsToCombo->grid(
    -row    => 8,
    -column => 2,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
$ProfitsIncrCombo->grid(
    -row    => 9,
    -column => 2,
    -sticky => 'e',
    -padx   => 5,
    -pady   => 5
);
#
# Sub Grid 3 - Logging
#
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
    $STRATEGY_TEXT = $StrategyInput->get( '1.0', 'end-1c' );

    $dbLabel->configure( -state => 'disabled' );
    $dbTextBox->configure( -state => 'disabled' );
    $dbbutton->configure( -state => 'disabled' );
    $destLabel->configure( -state => 'disabled' );
    $destTextBox->configure( -state => 'disabled' );
    $destbutton->configure( -state => 'disabled' );
    $tempLabel->configure( -state => 'disabled' );
    $tempTextBox->configure( -state => 'disabled' );
    $tempbutton->configure( -state => 'disabled' );
    $optTimeLabel->configure( -state => 'disabled' );
    $optTimebutton1->configure( -state => 'disabled' );
    $optTimebutton2->configure( -state => 'disabled' );
    $TFCombo->configure( -state => 'disabled' );
    $SymbolCombo->configure( -state => 'disabled' );
    $SICombo->configure( -state => 'disabled' );
    $MinWinCombo->configure( -state => 'disabled' );
    $StrategyLabel->configure( -state => 'disabled' );
    $StrategyInput->configure(
        -state      => 'disabled',
        -background => 'lightgrey'
    );
    $MinProfCombo->configure( -state => 'disabled' );
    $MinTradesCombo->configure( -state => 'disabled' );
    $ProfitsFromCombo->configure( -state => 'disabled' );
    $ProfitsToCombo->configure( -state => 'disabled' );
    $ProfitsIncrCombo->configure( -state => 'disabled' );

    $startApp->configure( -state => 'disabled' );
    $runApp->configure(
        -state      => 'normal',
        -foreground => 'Blue',
        -background => 'Green'
    );

    insert_settings_details_into_text_area();
    my $status = $logFrame->Label(
        -text       => "OPTIMIZE READY\n",
        -background => 'lightblue',
        -foreground => 'Red'
    );
    $status->grid( -row => 2, -column => 2, -sticky => 'nw', -padx => 12 );
    $status->configure(
        -font => [ -size => 12, -family => 'Cambria', -weight => 'bold' ] );
    return 1;
}

sub run_app {
    $STRATEGY_TEXT = $StrategyInput->get( '1.0', 'end-1c' );
    insert_settings_details_into_text_area();
    my $answer = $mainFrame->Dialog(
        -title   => 'Please Reply',
        -text    => 'Would you like to continue?',
        -buttons => [ 'YES', 'NO' ],
        -bitmap  => 'question'
    )->Show();
    if ( $answer eq 'YES' ) {
        my $command =
            "$FindBin::Bin\\Ami-optimizer.pl "
          . " -database    $DEFAULT_DATABASE_PATH "
          . " -destination $DEFAULT_DESTINATION_PATH "
          . " -symbol      $SELECTED_SYMBOL "
          . " -optname     $STRATEGY_TEXT "
          . " -afltemplate $DEFAULT_AFL_TEMPLATE_PATH ";
        $command .= " -opttime      $OPTIMIZE_TIME "         if ( $OPTIMIZE_TIME !~ /Yes/i );
        $command .= " -timeframe    $SELECTED_TIMEFRAME "    if ( $SELECTED_TIMEFRAME !~ /ALL/i );
        $command .= " -selectindex  $SELECTED_SEL_INDEX "    if ( $SELECTED_MIN_WINNERS !~ /default/i );
        $command .= " -minwin       $SELECTED_MIN_WINNERS "  if ( $SELECTED_MIN_WINNERS !~ /default/i );
        $command .= " -mintrades    $SELECTED_MIN_TRADES "   if ( $SELECTED_MIN_TRADES !~ /default/i );
        $command .= " -minprofit    $SELECTED_MIN_PROFITS "  if ( $SELECTED_MIN_PROFITS !~ /default/i );
        $command .= " -profitfrom   $SELECTED_PROFITS_FROM " if ( $SELECTED_PROFITS_FROM !~ /default/i );
        $command .= " -profitto     $SELECTED_PROFITS_TO "   if ( $SELECTED_PROFITS_TO !~ /default/i );
        $command .= " -profitincr   $SELECTED_PROFITS_INCREMENT "   if ( $SELECTED_PROFITS_INCREMENT !~ /default/i );

        unless ( $STRATEGY_TEXT
            && $SELECTED_SYMBOL
            && -d $DEFAULT_DATABASE_PATH
            && -d $DEFAULT_DESTINATION_PATH
            && -e $DEFAULT_AFL_TEMPLATE_PATH )
        {
            $logTextArea->delete( '0.0', 'end' );
            $logTextArea->insert( 'end',
                "ERROR -- STRATEGY field is empty !!!\n" )
              unless ($STRATEGY_TEXT);
            $logTextArea->insert( 'end',
                "ERROR -- NO Symbol is selected !!!\n" )
              unless ($SELECTED_SYMBOL);
            $logTextArea->insert( 'end',
                "ERROR -- Database path does not exists !!!\n" )
              unless ( -d $DEFAULT_DATABASE_PATH );
            $logTextArea->insert( 'end',
                "ERROR -- Destination path does not exists !!!\n" )
              unless ( -d $DEFAULT_DESTINATION_PATH );
            $logTextArea->insert( 'end',
                "ERROR -- Selected AFL is NOT a file !!!\n" )
              unless ( -e $DEFAULT_AFL_TEMPLATE_PATH );
            $logTextArea->insert( 'end',
                "\nPlease provide appropriate values \n\n" );
            $logTextArea->insert( 'end', 
                "Please select the options again and run \"RUN OPTIMIZER\" !!!\n"
            );
            enable_all();
            return 1;
        }
        $logTextArea->insert( 'end', "\nRunning command\n$command\n" );
        system("perl $command");
        my $status = $logFrame->Label(
            -text       => "   COMPLETED   ",
            -background => 'lightblue',
            -foreground => 'DarkGreen'
        );
        $status->grid( -row => 2, -column => 2, -sticky => 'nw', -padx => 12 );
        $status->configure(
            -font => [ -size => 14, -family => 'Cambria', -weight => 'bold' ] );
        enable_all();
    }
    elsif ( $answer eq 'NO' ) {
        my $status = $logFrame->Label(
            -text       => "OPTIMIZE ABORT",
            -background => 'lightblue',
            -foreground => 'Brown'
        );
        $status->grid( -row => 2, -column => 2, -sticky => 'nw', -padx => 12 );
        $status->configure(
            -font => [ -size => 12, -family => 'Cambria', -weight => 'bold' ] );
        enable_all();
    }
    return 1;
}

sub insert_settings_details_into_text_area {
    $logTextArea->delete( '0.0', 'end' );
    $logTextArea->insert( 'end', "DATABASE PATH     : $DEFAULT_DATABASE_PATH\n" );
    $logTextArea->insert( 'end', "DESTINATION PATH  : $DEFAULT_DESTINATION_PATH\n" );
    $logTextArea->insert( 'end', "STRATEGY AFL PATH : $DEFAULT_AFL_TEMPLATE_PATH\n" );
    $logTextArea->insert( 'end', "TIMEFRAME         : $SELECTED_TIMEFRAME\n" );
    $logTextArea->insert( 'end', "SYMBOL            : $SELECTED_SYMBOL\n" );
    $logTextArea->insert( 'end', "STRATEGY NAME     : $STRATEGY_TEXT\n" );
    $logTextArea->insert( 'end', "SELECTION INDEX   : $SELECTED_SEL_INDEX\n" );
    $logTextArea->insert( 'end', "MINIMUM WINNERS % : $SELECTED_MIN_WINNERS\n" );
    $logTextArea->insert( 'end', "MINIMUM PROFITS % : $SELECTED_MIN_PROFITS\n" );
    $logTextArea->insert( 'end', "MINIMUM TRADES    : $SELECTED_MIN_TRADES\n" );
    $logTextArea->insert( 'end', "PROFITS FROM (Rs) : $SELECTED_PROFITS_FROM\n" );
    $logTextArea->insert( 'end', "PROFITS TO   (Rs) : $SELECTED_PROFITS_TO\n" );
    $logTextArea->insert( 'end', "PROFITS INCR (Rs) : $SELECTED_PROFITS_INCREMENT\n" );
    $logTextArea->insert( 'end', "OPTIMIZE FOR TIME : $OPTIMIZE_TIME\n" );
    return 1;
}

sub enable_all {
    $dbLabel->configure( -state => 'normal' );
    $dbTextBox->configure( -state => 'normal' );
    $dbbutton->configure( -state => 'normal' );
    $destLabel->configure( -state => 'normal' );
    $destTextBox->configure( -state => 'normal' );
    $destbutton->configure( -state => 'normal' );
    $TFCombo->configure( -state => 'normal' );
    $SICombo->configure( -state => 'normal' );
    $startApp->configure( -state => 'normal' );
    $tempLabel->configure( -state => 'normal' );
    $tempTextBox->configure( -state => 'normal' );
    $tempbutton->configure( -state => 'normal' );
    $optTimeLabel->configure( -state => 'normal' );
    $optTimebutton1->configure( -state => 'normal' );
    $optTimebutton2->configure( -state => 'normal' );
    $SymbolCombo->configure( -state => 'normal' );
    $MinWinCombo->configure( -state => 'normal' );
    $StrategyLabel->configure( -state => 'normal' );
    $StrategyInput->configure( -state => 'normal', -background => 'white' );
    $MinProfCombo->configure( -state => 'normal' );
    $MinTradesCombo->configure( -state => 'normal' );
    $ProfitsFromCombo->configure( -state => 'normal' );
    $ProfitsToCombo->configure( -state => 'normal' );
    $ProfitsIncrCombo->configure( -state => 'normal' );
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

sub pick_destination {
    my $mypick = browse_folder($DEFAULT_DESTINATION_PATH);
    if ($mypick) {
        $mypick =~ s/\//\\/g;
        $destTextBox->delete( 0, 100 );
        $destTextBox->insert( 0, $mypick );
        $DEFAULT_DESTINATION_PATH = $mypick;
    }
    return 1;
}

sub pick_templdate {
    my $mypick = $mainFrame->getOpenFile(
        -initialdir => $DEFAULT_AFL_TEMPLATE_PATH,
        -title      => 'Choose a file'
    );
    if ($mypick) {
        $mypick =~ s/\//\\/g;
        $tempTextBox->delete( 0, 100 );
        $tempTextBox->insert( 0, $mypick );
        $DEFAULT_AFL_TEMPLATE_PATH = $mypick;
        if($mypick =~ /.*\\(\w+).*\.afl/) {
            $StrategyInput->insert( 'end', $1 );
        }
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

sub read_config_file {
    my $file = shift;
    my $hash;
    open( my $fh, "<", $file )
      or croak( '[ERROR] : Can\'t open the file $file: ' . "$!\n" );
    while (<$fh>) {
        chomp($_);
        next if $_ =~ /^$/;
        next if $_ =~ /^#/;
		if ( $_ =~ /\,/ ) {
            my @list = split( ",", $_ );
            $hash->{ shift(@list) } = \@list;
        }
    }
    close($fh);
    return $hash;
}
