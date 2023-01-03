#!usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
my $bam_dir = "/project/gccri/CPRIT_PDX/hef_folder/9.re_sequencing/2.gatk";
my $ref = "/home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta";
my $anno_humandb = "/home/hef/Tools/annovar/humandb";
my $region = "chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY,chrM";
my $target_file = "/home/hef/Data/Exome_v1_hg38_Probes_Standard.bed";
my $af_cutoff = 0.001;
my $normal_dp = 7;

my $fout = "/project/gccri/CPRIT_PDX/hef_folder/9.re_sequencing/3.snv/filter";
my $pwd = `pwd`;
chomp $pwd;
`mkdir -p $pwd/sh_filter $fout`;


open IN, "<$ARGV[0]" or die $!;
while(<IN>){
	chomp;
	my ($id, $type, $vcf) = split /\t/;
	
	open OUT, ">$pwd/script_sh/$id\_$type.sh" or die $!;
	`mkdir -p $fout/dkfz $fout/annovar $fout/remove_PON`;
	#DKFZ
	print OUT "source /home/hef/Tools/miniconda3/etc/profile.d/conda.sh;conda activate py2\n";
	print OUT "dkfzbiasfilter.py $vcf $bam_dir/$id.dedupped.realigned.recal.bam $ref $fout/dkfz/$id.$type.vcf; bcftools view  -f PASS $fout/dkfz/$id.$type.vcf > $fout/dkfz/$id.$type.vcf2; mv $fout/dkfz/$id.$type.vcf2 $fout/dkfz/$id.$type.vcf\n";
	print OUT "conda deactivate\n";

	#Annovar
	print OUT "perl /home/hef/Tools/annovar/table_annovar.pl $fout/dkfz/$id.$type.vcf $anno_humandb -buildver hg38 -out $fout/annovar/$id.$type.anno  -remove -protocol refGene,exac03nontcga,gnomad30_genome,esp6500siv2_all,1000g2015aug_all,clinvar_20220320 -operation g,f,f,f,f,f -nastring . -vcfinput\n";
	
	#Filter  VAF& max allele
	print OUT "less $fout/annovar/$id.$type.anno.hg38_multianno.vcf|bcftools view -f 'PASS,.'|bcftools view --include 'INFO/Func.refGene=\"exonic\" | INFO/Func.refGene~\"UTR\" | INFO/Func.refGene~\"splicing\"' |bcftools view --include 'INFO/ExAC_nontcga_ALL<$af_cutoff| INFO/ExAC_nontcga_ALL=\".\"'|bcftools view --include 'INFO/esp6500siv2_all<$af_cutoff| INFO/esp6500siv2_all=\".\"'|bcftools view --include 'INFO/1000g2015aug_all<$af_cutoff|INFO/1000g2015aug_all=\".\"'|awk -F '[\\t;]AF_raw=' '\$2<$af_cutoff||\$2==\".\"'|awk -F '[\\t;]AF_afr=' '\$2<$af_cutoff||\$2==\".\"'|awk -F '[\\t;]AF_ami=' '\$2<$af_cutoff||\$2==\".\"'|awk -F '[\\t;]AF_amr=' '\$2<$af_cutoff||\$2==\".\"'|awk -F '[\\t;]AF_asj=' '\$2<$af_cutoff||\$2==\".\"'|awk -F '[\\t;]AF_eas=' '\$2<$af_cutoff||\$2==\".\"'|awk -F '[\\t;]AF_fin=' '\$2<$af_cutoff||\$2==\".\"'|awk -F '[\\t;]AF_nfe=' '\$2<$af_cutoff||\$2==\".\"'|bcftools view --exclude 'INFO/CLNSIG=\"Benign\" | INFO/CLNSIG=\"Likely_benign\" '  > $fout/annovar/$id.$type.vcf\n";
	print OUT "bgzip  --force $fout/annovar/$id.$type.vcf; tabix -p vcf $fout/annovar/$id.$type.vcf.gz\n";
	print OUT "bcftools view --regions $region -R $target_file $fout/annovar/$id.$type.vcf.gz|bcftools view --max-alleles 2 > $fout/annovar/$id.$type.vcf2\n";
	#normal depth
        if ($type eq "pindel"){
                print OUT "less $fout/annovar/$id.$type.vcf2|bcftools view --include \"SUM(AD[0:])>$normal_dp\"|bcftools view --include \"SUM(AD[1:])>13\"|bcftools view -i 'INFO/SVLEN<50 & INFO/SVLEN>-50'|bcftools view -e 'INFO/TYPEOFSV==\"RPL\"'  > $fout/annovar/$id.$type.vcf\n";
        }
        elsif ($type =~  /tumoronly/){
                print OUT "less $fout/annovar/$id.$type.vcf2|bcftools view --include \"FORMAT/DP[0]>$normal_dp\" > $fout/annovar/$id.$type.vcf\n";
        }
        else{
                print OUT "less $fout/annovar/$id.$type.vcf2|bcftools view --include \"FORMAT/DP>$normal_dp\" > $fout/annovar/$id.$type.vcf\n";
        }

	# remove pon site
	print OUT "perl ~/Data/Mutation_PON/remove_pon_site.vcf.pl $fout/annovar/$id.$type.vcf |cut -f2- > $fout/remove_PON/$id.$type.vcf1\n";
	print OUT "perl ~/2.project/1.PDX/4.DNAseq_mutation/2.filter_muts/1.old_filtering/2.remove_germline_pon_site.tumorOnly.pl $fout/remove_PON/$id.$type.vcf1|cut -f2- > $fout/remove_PON/$id.$type.vcf\n";
	
}
