#!usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
my $cn_folder = "/project/gccri/CPRIT_PDX/hef_folder/z.result/reseq_20221221/pureCN";
my $fout = "/project/gccri/CPRIT_PDX/hef_folder/9.re_sequencing/3.snv/filter/SGZ.tumor_only/data";
`mkdir -p $fout`;

my %purity;
my %ploidy;
open PUR, "</home/hef/2.project/1.PDX/final_purity_ploidy.txt" or die $!;
while(<PUR>){
	chomp;
	next if (/Patient/);
	my @t = split /\t/;
	my $patient_id = $t[0];
	if ($t[4] ne "NA"){
		$purity{"$patient_id\_PDX_WES"} = $t[4];
		$ploidy{"$patient_id\_PDX_WES"} = $t[6];
	}
	if ($t[5] ne "NA"){
		$purity{"$patient_id\_PT_WES"} = $t[5];
                $ploidy{"$patient_id\_PT_WES"} = $t[7];
	}
}
#
open IN, "$ARGV[0]" or die $!;
while(<IN>){
        chomp;
        next unless (/WES/);
	next if (/1853_PDX/);
	next if (/512_PDX/);
	my ($patient_id, $id, $tbam) = split /\t/;
	open OUT, ">$fout/$id.cna_calls.txt" or die $!;
	print OUT "CHR\tsegStart\tsegEnd\tmafPred\tCN\tsegLR\tsegMAF\tnumMAtumorPred\tnumLRProbes\tnumAFProbes\tpurity\tbaseLevel\n";
	open OUT2, ">$fout/$id.pathology_purity.txt" or die $!;
	print OUT2 "NA";
	
	print "$id\n";
	open CN, "<$cn_folder/$id\_loh.csv" or die;
	while(<CN>){
		chomp;
		next if (/maf\.expected/);

		my @t = split /,/;
		my $chr = $t[1];
		my $st = $t[2];
		my $ed = $t[3];
		my $maf_exp = $t[-2];
		my $maf_obs = $t[-1];
		my $cn = $t[5];
		my $cn_minor = $t[6];
		my $seg_ratio = $t[8];
		my $num_prob = $t[9];
		my $num_snps = $t[10];
		
		next if ($cn_minor eq "NA");
		my $baselevel = $purity{$id}*$ploidy{$id} + (1-$purity{$id})*2;
		print OUT "$chr\t$st\t$ed\t$maf_exp\t$cn\t$seg_ratio\t$maf_obs\t$cn_minor\t$num_prob\t$num_snps\t$purity{$id}\t$baselevel\n";
	}
} 
