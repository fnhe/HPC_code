#!usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
my $cn_folder = "/project/gccri/CPRIT_PDX/hef_folder/z.result/reseq_20221221/pureCN";
my $fout = "/project/gccri/CPRIT_PDX/hef_folder/9.re_sequencing/3.snv/filter/SGZ.tumor_only/data";

my %mut;
open MAF, "</project/gccri/CPRIT_PDX/hef_folder/z.result/reseq_20221221/tumor_only.reseq.txt" or die $!;
while(<MAF>){
	chomp;
        next if (/^Hugo/);
	my @t = split /\t/;

	my $sample = $t[114];
	my $gene = $t[0];
	my $chr = $t[4];
	my $st = $t[5];
	my $t_vaf = $t[126];
	my $depth = $t[39];

	my $transcript = $t[37];
	my $mut_c = $t[34];
	my $mut_p = $t[36];
	my $strand = $t[59];

	my $mut_change = "$gene:$transcript:$mut_c\_$mut_p";
	my $pos = "$chr:$st";
	my $mut_type = $t[8];

	$mut{$sample}{$mut_change} = "$t_vaf:$depth:$pos:$strand:$mut_type";

}
#print Dumper(\%mut);
#
foreach my $id(sort keys %mut){
	open OUT,">$fout/$id.mut_aggr.full.txt" or die $!;
	print OUT "#sample\tmutation\tfrequency\tdepth\tpos\tstatus\tstrand\teffect\n";

	foreach my $snp (sort keys %{$mut{$id}}){
		my ($t_vaf, $depth, $chr, $st, $strand, $mut_type) = split /:/, $mut{$id}{$snp};
		if ($strand == "-1"){
			$strand = "-";
		}
		elsif ($strand == "1"){
			$strand = "+";
		}
=cut		
		my $type;
		if ($mut_type =~ /Missense/){
			$type = "missense";
		}
		elsif ($mut_type =~ /Splice/){
			$type = "splice";
		}
		elsif ($mut_type =~ /Nonsense/){
			$type = "nonsense";
	}
=cut
		print OUT "$id\t$snp\t$t_vaf\t".int($depth)."\t$chr:$st\tunknown\t$strand\t$mut_type\n";
	}
}
