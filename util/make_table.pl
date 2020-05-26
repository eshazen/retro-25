#!/usr/bin/perl
#
# read table of codes and make a C++ translator table
#
use strict;

my $line;
while( $line = <>) {
    chomp $line;
    if( $line =~ /\+----/) {
	my $l1 = <>;
	my @l1 = split /\|/, $l1;
	my $l2 = <>;
	my @l2 = split /\|/, $l2;
	my $l3 = <>;
	my @l3 = split /\|/, $l3;
	my ($lsb) = $l2 =~ /^\s*(\w+)/;
	my $n = $#l1;
#	print "Got a group, with LSB=$lsb len=$n\n";
	for( my $i=1; $i<17; $i++) {
	    $l1[$i] =~ s/ //g;
	    $l2[$i] =~ s/ //g;
	    $l3[$i] =~ s/ //g;
	    my $cell = uc($l1[$i]) . " " . uc($l2[$i]) . " " . uc($l3[$i]);
	    $cell =~ s/^ //g;
	    $cell =~ s/ $//g;
	    my $hx = sprintf "0x%x%x", $i-1, hex($lsb);
	    #	    print "cell $hx \"$cell\"\n";
	    print "$hx, \"$cell\", \"\",\n";
	    exit if( $hx eq "0xff");
	}
    }
}
