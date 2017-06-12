use strict;
use warnings;

# Based on Mornfall's md2tex for DIVINE papers

use IPC::Open2;

my @envs = ( "figure", "columns" );
my @groups = ( "caption" );
my @words = ();
my @nonbreak = ( "ref", "cite" );

local $/;
my $text = <STDIN>;

sub nonbreak
{
    my $cmd = shift;
    $text =~ s/[\n ]\\$cmd/~\\$cmd/gsm;
}

sub env2pd
{
    my $env = shift;
    $text =~ s,\\(begin|end){$env},\\pandoc$1\\$env,gsm;
};

sub pd2env
{
    my $env = shift;
    $text =~ s,\\pandoc(begin|end)\\$env,\\$1\{$env\},gsm;
}

sub pd2group
{
    my $env = shift;
    $text =~ s,\\pandocbegin\\$env(.*?)\\pandocend\\$env,\\$env\{$1\},gsm;
}

sub word2tex
{
    my $word = shift;
    my $cmd = $word;
    $cmd =~ tr,[A-Z],[a-z],;
    $text =~ s,$word,\\$cmd,gsm;
}

sub include {
    my ( $file, $optsStr ) = @_;
    $optsStr = "" unless defined $optsStr;
    my @optsArr = split( /\s*,\s*/, $optsStr );
    my %opts;
    for my $o ( @optsArr ) {
        if ( $o =~ /^([^=]*)=([^=]*)$/ ) {
            $opts{ $1 } = $2;
        }
        else {
            $opts{ $o } = "";
        }
    }
    local $/ = "\n";

    my $mdopts = "";
    $mdopts .= " .numberLines" if exists $opts{numberLines};

    $opts{ type } = "cpp" unless exists $opts{ type };
    my $out = "```{." . $opts{type} . "$mdopts}\n";
    open( my $h, $file );
    my $i = 1;
    while ( <$h> ) {
        next if exists $opts{ from } && $i < ($opts{ from } + 0);
        last if exists $opts{ to } && $i > ($opts{ to } + 0);
        $out .= $_;
    } continue {
        $i++;
    }
    close( $h );
    $out .= "```\n";
    return $out;
}

env2pd( $_ ) for ( @envs, @groups );

$text =~ s/\\includeCode\{([^}]*)\}/include($1)/gsme;
$text =~ s/\\includeCode\[([^]]*)\]\{([^}]*)\}/include($2, $1)/gsme;

open( my $TMP, ">md2tex.tmp.$$" );
print $TMP $text;
close( $TMP );

open( my $PD, "pandoc -i md2tex.tmp.$$ @ARGV |" );
$text = <$PD>;
close( $PD );
unlink( "md2tex.tmp.$$" );

pd2env( $_ ) for ( @envs );
pd2group( $_ ) for ( @groups );
word2tex( $_ ) for ( @words );
nonbreak( $_ ) for ( @nonbreak );

$text =~ s/\\begin\{itemize\}\[<\+->\]/\\begin{itemize}/g;
$text =~ s/\\begin\{enumerate\}\[<\+->\]/\\begin{enumerate}/g;
$text =~ s/\\begin\{description\}\[<\+->\]/\\begin{description}/g;
$text =~ s/\\begin\{frame\}\{/\\begin{frame}\[fragile\]{/g;
$text =~ s/numbers=left/numbers=left,numbersep=5pt/g;

print $text;
