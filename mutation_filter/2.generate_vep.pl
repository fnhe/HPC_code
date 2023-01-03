#!usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

my $ASSEMBLY = "GRCh38";
my $VEP  = "/home/hef/Tools/miniconda3/bin/vep";
my $VEP_CACHE_DIR = "/home/hef/Data/hg38/vep/v88";
my $VEP_GENOME = "/home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta";
my $fout = "/project/gccri/CPRIT_PDX/hef_folder/9.re_sequencing/3.snv/filter/MAF";
`mkdir -p $fout`;
open IN, "<$ARGV[0]" or die $!;
while(<IN>){
	chomp;
	my ($prefix, $vcf) = split /\t/;
	my @id = split /\./, $prefix;
	my @t = split /_/, $id[0];
	#print "perl $VEP --buffer_size 300 --offline --cache --dir $VEP_CACHE_DIR --assembly ${ASSEMBLY} --fasta $VEP_GENOME --fork 8 --no_progress --no_stats --sift b --ccds --uniprot --hgvs --symbol --numbers --domains --canonical --protein --biotype --uniprot --tsl --pubmed --variant_class --shift_hgvs 1 --check_existing --total_length --allele_number --no_escape --xref_refseq --failed 1 --minimal --flag_pick_allele --force_overwrite --pick_order canonical,tsl,biotype,rank,ccds,length --format vcf --vcf -i $vcf -o $prefix.vep.vcf\n";
	my $id = $t[0];
	if ($t[0] =~ /-/){
		my @k = split /-/, $t[0];
		$id = $k[0];
	}
	if ($prefix =~ /tumoronly/){
		print "perl -wlni.bak -e 'if(/^#/){if(/^#CHROM/){s/FORMAT\\t.*\$/FORMAT\\tNORMAL\\tTUMOR/;print}else{print}}else{\@F=split(\"\\t\"); if(scalar \@F==10){\$F[7]=~s/\$/\\;set=tumoronly/; \$F[8]=~s/\$/\\t\\.\\/\\./}; print join(\"\\t\",\@F)}' $vcf;";
		print "/home/hef/Tools/miniconda3/bin/perl /home/hef/Tools/mskcc-vcf2maf-754d68a/vcf2maf.pl --input-vcf $vcf --output-maf $fout/$prefix.vep.maf --ref-fasta $VEP_GENOME --tumor-id TUMOR --normal-id NORMAL  --vep-forks 10\n";
	}
	elsif ($prefix =~ /mutect/){
                print "/home/hef/Tools/miniconda3/bin/perl /home/hef/Tools/mskcc-vcf2maf-754d68a/vcf2maf.pl --input-vcf $vcf --output-maf $fout/$prefix.vep.maf --ref-fasta $VEP_GENOME --tumor-id $id[0] --normal-id $id\_Germline_$t[-1] --vep-forks 10\n";
        }
	elsif ($prefix =~ /pindel/){
                print "less $vcf| sed  '/<INV>/d' |sed  '/<DEL>/d' | sed '/^chrUn/d' > $vcf.remove; /home/hef/Tools/mskcc-vcf2maf-754d68a/vcf2maf.pl --input-vcf $vcf.remove --output-maf $fout/$prefix.vep.maf --ref-fasta $VEP_GENOME --tumor-id $id[0] --normal-id $id\_Germline_$t[-1] --vep-forks 10\n"
        }
	elsif ($prefix =~ /varscan/ || $prefix =~ /strelka/){
		print "/home/hef/Tools/miniconda3/bin/perl /home/hef/Tools/mskcc-vcf2maf-754d68a/vcf2maf.pl --input-vcf $vcf --output-maf $fout/$prefix.vep.maf --ref-fasta $VEP_GENOME --tumor-id TUMOR --normal-id NORMAL --vep-forks 10\n";
	}
}
