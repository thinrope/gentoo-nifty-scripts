#!/usr/bin/perl
use warnings;
use strict;

=head1 NAME

  FTKI-deuglify.pl

=head1 DESCRIPTION

  A simple script to convert the timestamps within FTK Imager output (TSV)

=head1 AUTHOR

  Copyright (c) 2018-2024 by Kalin KOZHUHAROV <kalin@thinrope.net>

=head1 LICENSE

  GPL-3 https://www.gnu.org/licenses/gpl.html

=head1 SYNOPSIS

  Usage:
        ./FTKI-deuglify.pl <input_filename> <output_filename>

  Example:
        ./FTKI-deuglify.pl FTKI_out.csv proper_format.tsv
 
  Notes:
        * Output files are OVERWRITTEN without prompt!
        * This script is not optimized for speed!
        * FTKI outputs TSV files in UTF-16LE (hard-coded below)
=cut

die( "\n[ERROR] Invalid number of arguments [", scalar @ARGV, "]!\n",
     "Usage:\n\t$0 <input_filename> <output_filename>\n")
	unless ( scalar @ARGV == 2 );

my $Mons = 'Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec';
my %M = ( Jan => '01', Feb => '02', Mar => '03', Apr => '04',
	  May => '05', Jun => '06', Jul => '07', Aug => '08',
	  Sep => '09', Oct => '10', Nov => '11', Dec => '12' );

open( my $in_fh, '<:raw:encoding(UTF-16LE):crlf', $ARGV[0] )
	or die("$! , exitting");
open( my $out_fh, '>:raw:encoding(UTF-16LE):crlf', $ARGV[1] )
	or die("$! , exitting");

while (defined( my $line = <$in_fh>))
{
	no warnings qw/uninitialized/;	# since not all timestamps have nanoseconds

	# best, IMHO: convert to ISO-8601:2009
	$line =~ s/\t(\d\d\d\d-)(${Mons})(-\d\d) (\d\d:\d\d:\d\d)(\.\d+){0,1} UTC/\t${1}$M{$2}${3}T${4}${5}+0000/g;

	# alternative A: standard, minimal replacement
	#$line =~ s/(\s+\d\d\d\d-)(${Mons})(-\d\d \d\d:\d\d:\d\d)/${1}$M{$2}${3}/g;

	# alternative B: split dates from times with tab
	#$line =~ s/(\s+\d\d\d\d-)(${Mons})(-\d\d) (\d\d:\d\d:\d\d)/${1}$M{$2}${3}\t${4}/g;

	print $out_fh $line;
}

close($out_fh)
	or die("$! , exitting");
close($in_fh)
	or die("$! , exitting");

__END__
