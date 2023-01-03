#!usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
my $fin = "/project/gccri/CPRIT_PDX/hef_folder/9.re_sequencing/3.snv/filter/remove_PON";
my $fout = "/project/gccri/CPRIT_PDX/hef_folder/9.re_sequencing/3.snv/filter/merge_vcf.tumor_normal";
my $ref = "/home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta";
`mkdir -p $fout sh_merge`;
my @method = qw/pindel strelka mutect varscan/;
while(<>){
	chomp;
	my $sample = $_;
	open SH, ">sh_merge/$sample.sh" or die $!;
	print SH "picard UpdateVcfSequenceDictionary SD=$ref I=$fin/$sample.varscan.vcf O=$fout/$sample.varscan.add.vcf;picard SortVcf I=$fout/$sample.varscan.add.vcf O=$fout/$sample.varscan.sorted.vcf.gz;/bin/rm -rf $fout/$sample.varscan.add.vcf\n";
	print SH "picard UpdateVcfSequenceDictionary SD=$ref I=$fin/$sample.pindel.vcf O=$fout/$sample.pindel.add.vcf;picard SortVcf I=$fout/$sample.pindel.add.vcf O=$fout/$sample.pindel.sorted.vcf.gz;/bin/rm -rf $fout/$sample.pindel.add.vcf\n";
	print SH "picard UpdateVcfSequenceDictionary SD=$ref I=$fin/$sample.mutect.vcf O=$fout/$sample.pindel.add.vcf;picard SortVcf I=$fin/$sample.strelka.vcf O=$fout/$sample.strelka.sorted.vcf.gz\n";
	print SH "picard UpdateVcfSequenceDictionary SD=$ref I=$fin/$sample.strelka.vcf O=$fout/$sample.pindel.add.vcf;picard SortVcf I=$fin/$sample.mutect.vcf O=$fout/$sample.mutect.sorted.vcf.gz\n";
	
	foreach my $method (@method){
		open OUT, ">$fout/$sample.$method.name" or die $!;
		print OUT "Normal_$method\nTumor_$method\n";
		print SH "bcftools reheader -s $fout/$sample.$method.name $fout/$sample.$method.sorted.vcf.gz>$fout/$sample.$method.vcf.gz\ngunzip -f $fout/$sample.$method.vcf.gz\n"; 
	}
	print SH "java -Xmx16g -jar ~/Tools/GenomeAnalysisTK.jar -T CombineVariants -R $ref -genotypeMergeOptions PRIORITIZE --rod_priority_list mutect,varscan,strelka,pindel --variant:mutect $fout/$sample.mutect.vcf --variant:varscan $fout/$sample.varscan.vcf --variant:strelka $fout/$sample.strelka.vcf --variant:pindel $fout/$sample.pindel.vcf -o $fout/$sample.merged.vcf\n";
print SH "/bin/rm -rf $fout/$sample*name $fout/$sample*sorted* $fout/$sample*varscan* $fout/$sample*mutect* $fout/$sample*strelka* $fout/$sample*pindel* $fout/$sample*add*;\n";
}
