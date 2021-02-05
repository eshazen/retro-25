#!/usr/bin/perl
#
# simple-minded assembler for HP-25 programming
# usage:  asm25.pl file.txt
# output to file.lst (listing) and file.hex (hex)
#
# input format:
# comments start with "#" either in first column or after statement
# lines must be numbered sequentially starting with 1
# GTO 00 should terminate program
# Here is a sample program:
# 
#   1  : ENTR
#   2  : 1
#   3  : +
#   4  : PSE
#   5  : GTO 01
#   6  : GTO 00
#
# Output listing includes display codes and hex
#   "31"       f6   1  : ENTR
#   "01"       c1   2  : 1
#   "51"       f1   3  : +
#   "14 74"    d5   4  : PSE
#   "13 01"    01   5  : GTO 01
#   "13 00"    00   6  : GTO 00
#   "13 00"    00   7  : GTO 00
#
# Hex is just a list of hex nibbles ready to send:
#   f6c1f1d5010000
#------------------------------------------------------------------------
# table of opcodes
# <hex_code>, <display_name>, <alias>, <display>
my @ops = (
    0x00, "GTO 00", "", "13 00",
    0x10, "GTO 10", "", "13 10",
    0x20, "GTO 20", "", "13 20",
    0x30, "GTO 30", "", "13 30",
    0x40, "GTO 40", "", "13 40",
    0x50, "F FIX 0", "FIX 0", "14 11 00",
    0x60, "F SCI 0", "SCI 0", "14 12 00",
    0x70, "F ENG 0", "ENG 0", "14 13 00",
    0x80, "", "", "",
    0x90, "", "", "",
    0xa0, "F 0 >HMS", ">H.MS", "14 00",
    0xb0, "G 0 >H", ">H>", "15 00",
    0xc0, "0", "", "00",
    0xd0, "F - X<Y", "X<Y", "14 41",
    0xe0, "G - X<0", "X<0", "15 41",
    0xf0, "-", "", "41",
    0x01, "GTO 01", "", "13 01",
    0x11, "GTO 11", "", "13 11",
    0x21, "GTO 21", "", "13 21",
    0x31, "GTO 31", "", "13 31",
    0x41, "GTO 41", "", "13 41",
    0x51, "F FIX 1", "FIX 1", "14 11 01",
    0x61, "F SCI 1", "SCI 1", "14 12 01",
    0x71, "F ENG 1", "ENG 1", "14 13 01",
    0x81, "", "", "",
    0x91, "", "", "",
    0xa1, "F 1 INT", "INT", "14 01",
    0xb1, "G 1 FRAC", "FRAC", "15 01",
    0xc1, "1", "", "01",
    0xd1, "F + X>=Y", "X>=Y", "14 51",
    0xe1, "G + X>=0", "X>=0", "15 51",
    0xf1, "+", "", "51",
    0x02, "GTO 02", "", "13 02",
    0x12, "GTO 12", "", "13 12",
    0x22, "GTO 22", "", "13 22",
    0x32, "GTO 32", "", "13 32",
    0x42, "GTO 42", "", "13 42",
    0x52, "F FIX 2", "FIX 2", "14 11 02",
    0x62, "F SCI 2", "SCI 2", "14 12 02",
    0x72, "F ENG 2", "ENG 2", "14 13 02",
    0x82, "", "", "",
    0x92, "", "", "",
    0xa2, "F 2 SQRT", "SQRT", "14 02",
    0xb2, "G 2 X^2", "X^2", "15 02",
    0xc2, "2", "", "02",
    0xd2, "F X X<>Y", "X<>Y", "14 61",
    0xe2, "G X X<>0", "X<>0", "15 61",
    0xf2, "X", "*", "61",
    0x03, "GTO 03", "", "13 03",
    0x13, "GTO 13", "", "13 13",
    0x23, "GTO 23", "", "13 23",
    0x33, "GTO 33", "", "13 33",
    0x43, "GTO 43", "", "13 43",
    0x53, "F FIX 3", "FIX 3", "14 11 03",
    0x63, "F SCI 3", "SCI 3", "14 12 03",
    0x73, "F ENG 3", "ENG 3", "14 13 03",
    0x83, "", "", "",
    0x93, "", "", "",
    0xa3, "F 3 Y^X", "Y^X", "14 03",
    0xb3, "G 3 ABS", "ABS", "15 03",
    0xc3, "3", "", "03",
    0xd3, "F / X=Y", "Y", "14 71",
    0xe3, "G / X=0", "0", "15 71",
    0xf3, "/", "", "71",
    0x04, "GTO 04", "", "13 04",
    0x14, "GTO 14", "", "13 14",
    0x24, "GTO 24", "", "13 24",
    0x34, "GTO 34", "", "13 34",
    0x44, "GTO 44", "", "13 44",
    0x54, "F FIX 4", "FIX 4", "14 11 04",
    0x64, "F SCI 4", "SCI 4", "14 12 04",
    0x74, "F ENG 4", "ENG 4", "14 13 04",
    0x84, "", "", "",
    0x94, "", "", "",
    0xa4, "F 4 SIN", "SIN", "14 04",
    0xb4, "G 4 ASIN", "ASIN", "15 04",
    0xc4, "4", "", "04",
    0xd4, "F . LSTX", "LSTX", "14 73",
    0xe4, "G . PI", "PI", "15 73",
    0xf4, ".", "", "73",
    0x05, "GTO 05", "", "13 05",
    0x15, "GTO 15", "", "13 15",
    0x25, "GTO 25", "", "13 25",
    0x35, "GTO 35", "", "13 35",
    0x45, "GTO 45", "", "13 45",
    0x55, "F FIX 5", "FIX 5", "14 11 05",
    0x65, "F SCI 5", "SCI 5", "14 12 05",
    0x75, "F ENG 5", "ENG 5", "14 13 05",
    0x85, "", "", "",
    0x95, "", "", "",
    0xa5, "F 5 COS", "COS", "14 05",
    0xb5, "G 5 ACOS", "ACOS", "15 05",
    0xc5, "5", "", "05",
    0xd5, "F R/S PSE", "PSE", "14 74",
    0xe5, "G R/S NOP", "NOP", "15 74",
    0xf5, "R/S", "R/S", "74",
    0x06, "GTO 06", "", "13 06",
    0x16, "GTO 16", "", "13 16",
    0x26, "GTO 26", "", "13 26",
    0x36, "GTO 36", "", "13 36",
    0x46, "GTO 46", "", "13 46",
    0x56, "F FIX 6", "FIX 6", "14 11 06",
    0x66, "F SCI 6", "SCI 6", "14 12 06",
    0x76, "F ENG 6", "ENG 6", "14 13 06",
    0x86, "", "", "",
    0x96, "", "", "",
    0xa6, "F 6 TAN", "TAN", "14 06",
    0xb6, "G 6 ATAN", "ATAN", "15 06",
    0xc6, "6", "", "06",
    0xd6, "", "", "",
    0xe6, "", "", "",
    0xf6, "ENTR", "ENT", "31",
    0x07, "GTO 07", "", "13 07",
    0x17, "GTO 17", "", "13 17",
    0x27, "GTO 27", "", "13 27",
    0x37, "GTO 37", "", "13 37",
    0x47, "GTO 47", "", "13 47",
    0x57, "F FIX 7", "FIX 7", "14 11 07",
    0x67, "F SCI 7", "SCI 7", "14 12 07",
    0x77, "F ENG 7", "ENG 7", "14 13 07",
    0x87, "", "", "",
    0x97, "", "", "",
    0xa7, "F 7 LN", "LN", "14 07",
    0xb7, "G 7 EXP", "EXP", "15 07",
    0xc7, "7", "", "07",
    0xd7, "", "", "",
    0xe7, "G CHS DEG", "DEG", "15 32",
    0xf7, "CHS", "", "32",
    0x08, "GTO 08", "", "13 08",
    0x18, "GTO 18", "", "13 18",
    0x28, "GTO 28", "", "13 28",
    0x38, "GTO 38", "", "13 38",
    0x48, "GTO 48", "", "13 48",
    0x58, "F FIX 8", "FIX 8", "14 11 08",
    0x68, "F SCI 8", "SCI 8", "14 12 08",
    0x78, "F ENG 8", "ENG 8", "14 13 08",
    0x88, "", "", "",
    0x98, "", "", "",
    0xa8, "F 8 LOG", "LOG", "14 08",
    0xb8, "G 8 10^X", "10^X", "15 08",
    0xc8, "8", "", "08",
    0xd8, "F EEX REG", "REG", "14 33",
    0xe8, "G EEX RAD", "RAD", "15 33",
    0xf8, "EEX", "", "33",
    0x09, "GTO 09", "", "13 09",
    0x19, "GTO 19", "", "13 19",
    0x29, "GTO 29", "", "13 29",
    0x39, "GTO 39", "", "13 39",
    0x49, "GTO 49", "", "13 49",
    0x59, "F FIX 9", "FIX 9", "14 11 09",
    0x69, "F SCI 9", "SCI 9", "14 12 09",
    0x79, "F ENG 9", "ENG 9", "14 13 09",
    0x89, "", "", "",
    0x99, "", "", "",
    0xa9, "F 9 >R", ">R", "14 09",
    0xb9, "G 9 >P", ">P", "15 09",
    0xc9, "9", "", "09",
    0xd9, "F CLX STK", "STK", "14 34",
    0xe9, "G CLX GRD", "GRD", "15 34",
    0xf9, "CLX", "", "34",
    0x0a, "STO 0", "", "23 00",
    0x1a, "STO 1", "", "23 01",
    0x2a, "STO 2", "", "23 02",
    0x3a, "STO 3", "", "23 03",
    0x4a, "STO 4", "", "23 04",
    0x5a, "STO 5", "", "23 05",
    0x6a, "STO 6", "", "23 06",
    0x7a, "STO 7", "", "23 07",
    0x8a, "", "",  "", 
    0x9a, "", "", "", 
    0xaa, "", "", "", 
    0xba, "", "", "", 
    0xca, "", "", "", 
    0xda, "F X/Y X/", "MEAN", "14 21",
    0xea, "G X/Y %", "%", "15 21",
    0xfa, "X/Y", "", "21",
    0x0b, "RCL 0", "", "24 00",
    0x1b, "RCL 1", "", "24 01",
    0x2b, "RCL 2", "", "24 02",
    0x3b, "RCL 3", "", "24 03",
    0x4b, "RCL 4", "", "24 04",
    0x5b, "RCL 5", "", "24 05",
    0x6b, "RCL 6", "", "24 06",
    0x7b, "RCL 7", "", "24 07",
    0x8b, "", "", "",
    0x9b, "", "", "",
    0xab, "", "", "",
    0xbb, "", "", "",
    0xcb, "", "", "",
    0xdb, "F RDN S", "S", "14 22",
    0xeb, "G RDN 1/X", "1/X", "15 22",
    0xfb, "RDN", "", "22",
    0x0c, "STO - 0", "", "23 41 00",
    0x1c, "STO - 1", "", "23 41 01",
    0x2c, "STO - 2", "", "23 41 02",
    0x3c, "STO - 3", "", "23 41 03",
    0x4c, "STO - 4", "", "23 41 04",
    0x5c, "STO - 5", "", "23 41 05",
    0x6c, "STO - 6", "", "23 41 06",
    0x7c, "STO - 7", "", "23 41 07",
    0x8c, "", "", "",
    0x9c, "", "", "",
    0xac, "", "", "",
    0xbc, "", "", "",
    0xcc, "", "", "",
    0xdc, "F E+ E-", "E-", "14 25",
    0xec, "G E+ ??", "", "15 25",
    0xfc, "E+", "", "25",
    0x0d, "STO + 0", "", "23 51 00",
    0x1d, "STO + 1", "", "23 51 01",
    0x2d, "STO + 2", "", "23 51 02",
    0x3d, "STO + 3", "", "23 51 03",
    0x4d, "STO + 4", "", "23 51 04",
    0x5d, "STO + 5", "", "23 51 05",
    0x6d, "STO + 6", "", "23 51 06",
    0x7d, "STO + 7", "", "23 51 07",
    0x8d, "", "", "",
    0x9d, "", "", "",
    0xad, "", "", "",
    0xbd, "", "", "",
    0xcd, "", "", "",
    0xdd, "", "", "",
    0xed, "", "", "",
    0xfd, "", "", "",
    0x0e, "STO X 0", "", "23 61 00",
    0x1e, "STO X 1", "", "23 61 01",
    0x2e, "STO X 2", "", "23 61 02",
    0x3e, "STO X 3", "", "23 61 03",
    0x4e, "STO X 4", "", "23 61 04",
    0x5e, "STO X 5", "", "23 61 05",
    0x6e, "STO X 6", "", "23 61 06",
    0x7e, "STO X 7", "", "23 61 07",
    0x8e, "", "", "",
    0x9e, "", "", "",
    0xae, "", "", "",
    0xbe, "", "", "",
    0xce, "", "", "",
    0xde, "", "", "",
    0xee, "", "", "",
    0xfe, "", "", "",
    0x0f, "STO / 0", "", "23 71 00",
    0x1f, "STO / 1", "", "23 71 01",
    0x2f, "STO / 2", "", "23 71 02",
    0x3f, "STO / 3", "", "23 71 03",
    0x4f, "STO / 4", "", "23 71 04",
    0x5f, "STO / 5", "", "23 71 05",
    0x6f, "STO / 6", "", "23 71 06",
    0x7f, "STO / 7", "", "23 71 07",
    0x8f, "", "", "",
    0x9f, "", "", "",
    0xaf, "", "", "",
    0xbf, "", "", "",
    0xcf, "", "", "",
    0xdf, "", "", "",
    0xef, "", "", "",
    0xff, "", "", ""
    );
#------------------------------------------------------------------------

my $line;
my $n = 1;
my $errz = 0;

# lookup opcode, return index
sub lookup {
    my $str = shift @_;
    for( my $i=0; $i<256; $i++) {
	return $i
	    if( ($ops[4*$i+2] eq $str) || ($ops[4*$i+1] eq $str));
    }
    return -1;
}

my $outs = "";

my $na = $#ARGV+1;

if( $na < 1) {
    print "Usage: asm25.pl <input_file>\n";
    exit;
}

my $fn = $ARGV[0];
my ($base,$type) = $fn =~ /(.*)\.(\w+)$/;
if( length( $type) < 1) {
    print "Unknown file type in $fn, aborting...\n";
    exit;
}

my $flist = "$base.lst";
my $fhex = "$base.hex";

print ">  List to $flist\n";
print ">   Hex to $fhex\n";

open FI, "< $fn" or die "opening $fn: $!";
open FL, "> $flist" or die "opening $flist: $!";
open FH, "> $fhex" or die "opening $fhex: $!";

while( $line = <FI>) {
    chomp $line;

    if( $line =~ /^#/) {	# comment
	print FL "$line\n";
    } else {
	my ($lnum, $inst) = $line =~ /^\s*(\d+)\s*:\s*([^#]+)/;
	$inst =~ s/\s+$//g;
	if( $n != $lnum) {
	    print "Line number mismatch.  Input line $n, file line $lnum\n";
	    ++$errz;
	}	
	my $opfn = lookup( $inst);
	if( $opfn < 0) {
	    print "Invalid opcode \"$inst\" in line $lnum\n";
	    ++$errz;
	} else {
	    my $fc = $ops[4*$opfn];
	    my $dpy = "\"$ops[4*$opfn+3]\"";
	    $outs .= sprintf "%02x", $fc;
	    printf FL "%-10s %02x  %s\n", $dpy, $fc, $line;
	}
	++$n;
    }
}

print "$errz errors\n";
print FH $outs, "\n";
