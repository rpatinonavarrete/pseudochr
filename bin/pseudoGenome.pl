#!/usr/bin/perl

use Getopt::Std;

my $usage="Generates a pseudo genome from a mpileup and a vcf file based on a reference genome\n
		Usage: $0 -m mpileup -v my.vcf -myOutput.fasta
		-p mpileup file generated with samtools mpileup [output all positions required -a]
		-v vcfFile
		-o output file
		-x min coverage (default = 10)
		-h help message\n\n";


our ($opt_p, $opt_v, $opt_o, $opt_x, $opt_h);
getopts('p:v:o:x:h') || die "$usage\n";

if (defined($opt_h)) {
	die "$usage\n";
}

if (!$opt_p || !$opt_v) {
	print "please supply the required items:\n";
	if (!$opt_p) {
		print "not mpileup file\n";
	}
	if (!$opt_v) {
		print "not vcf file\n";
	}
	exit;
}

# create the variable for the mpileup file
my $mpileup = $opt_p;
chomp $mpileup;
# name the output, in case no -o use the name of the mpileup file
my @pathpileup = split (/\//, $mpileup);
my $pileupName = pop(@pathpileup);
$pileupName =~ s/\.mpileup//;
if ((! defined($opt_o)) || ($opt_o eq '')) {
	$opt_o = $pileupName."fasta";
}

# coverage, in case no -c default is 10
my $coverage = '';
if (! defined($opt_x)) {
	$coverage = 10;
} else {
	$coverage = $opt_x;
}

# open vcf file, put all variant lines in an array
my $vcffile = $opt_v;

open (VCF, $vcffile) || die "Cannot open $vcffile\n";

my @variants = ();
while (<VCF>) {
	chomp $_;
	next if ($_ =~ /^#/);
	push @variants, $_;
}
close (VCF);


# check the mpileup file
# open
open (IN, $mpileup) || die "Cannot open $mpileup\n";
#create output file
system (">$opt_o");
open (OUT, ">>$opt_o");

# create first line of the ouput
# use the name of the 
print OUT ">".$pileupName."\n";

@variantline = split (/\t/, $variants[0]);


while (<IN>) {
	chomp $_;
	my @line = split (/\t/, $_);

	if ($line[3] < $coverage) {
		print OUT "-";
		if ($line[1] == $variantline[1]){
			shift @variants;
			@variantline = split (/\t/, $variants[0]);
		}
		next;
	} else {
		if ($line[1] == $variantline[1]){
			print OUT $variantline[4];
			shift @variants;
			@variantline = split (/\t/, $variants[0]);
			next;
		} else {
		print OUT $line[2];
		next;
		}
	}
}

print OUT "\n";

close (OUT);
close (IN);

exit;
