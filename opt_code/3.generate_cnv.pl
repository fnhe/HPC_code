#!usr/bin/perl
use strict;
use warnings;
my $cpu = 8;
my $outdir = "/project/gccri/OPTIMIST/analysis/DNA";

my $ref = "/home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta";
my $cnvkit_ini = "/home/hef/Tools/cnvkit_liding/config/config.gencode_grch38.mgi.ini";
my $cnvkit_parameter = "-1.1,-0.4,0.3,0.7";
my $gc_wig = "/home/hef/Data/hg38/resources_broad_hg38_v0/hg38.gc50Base.wig.gz";

my $DB_pon="/home/hef/Data/files_liding/mutect/gatk4_mutect2_4136_pon.vcf.gz";
my $DB_gnomad="/home/hef/Data/files_liding/mutect/af-only-gnomad.hg38.vcf.gz";
my $DB_interval="/home/hef/Data/files_liding/mutect/wgs_calling_regions.hg38.interval_list";
my $region_excluded="/home/hef/Data/hg38/hg38.centromere_telomere.bed";
my $add = "--genotype-germline-sites true --genotype-pon-sites true";
my $mapping_bias_wes = "/project/gccri/CPRIT_PDX/hef_folder/5.CNV/pureCN/WES_mapping_bias.rds";
my $mapping_bias_wgs = "/project/gccri/CPRIT_PDX/hef_folder/5.CNV/pureCN/WGS_mapping_bias.rds";
my $blacklist = "/project/gccri/CPRIT_PDX/hef_folder/5.CNV/pureCN/hg38_simpleRepeats.bed";

my $pwd = `pwd`;
chomp $pwd;
`mkdir -p $pwd/script_sh`;
`mkdir -p $outdir/4.cnv`;
open IN,"<$ARGV[0]" or die $!;
while(<IN>){
        chomp;
        my ($tumor_id, $normal_id, $tumor_bam, $normal_bam) = split /\t/;
	open OUT,">script_sh/$tumor_id.cnv.sh" or die $!;	
	my $fout = "$outdir/4.cnv";
	`mkdir -p $fout/cnvkit $fout/cnvkit/$tumor_id $fout/seqz $fout/seqz/$tumor_id $fout/pureCN $fout/pureCN/$tumor_id`;
	#generate sequenza Rscript
	if ($tumor_id =~ /002$/){
		open SH, ">$fout/seqz/$tumor_id.r";
        	print SH "library(sequenza)\n";
	        print SH "data.file <- \"$fout/seqz/$tumor_id/$tumor_id.seqz.gz\"\n";
        	print SH "seqz <-sequenza.extract(data.file,verbose=FALSE)\nCP <- sequenza.fit(seqz)\n";
	        print SH "sequenza.results(sequenza.extract = seqz, cp.table = CP, sample.id = \"$tumor_id\", out.dir=\"$fout/seqz/$tumor_id\")\n";

        	print OUT "/home/hef/Tools/miniconda3/bin/sequenza-utils bam2seqz -n $normal_bam -t $tumor_bam --fasta $ref -gc $gc_wig -o $fout/seqz/$tumor_id/$tumor_id.seqz.gz\n";
	        print OUT "less $fout/seqz/$tumor_id/$tumor_id.seqz.gz|grep -v \"_random\" |bgzip > $fout/seqz/$tumor_id/new.gz; mv $fout/seqz/$tumor_id/new.gz $fout/seqz/$tumor_id/$tumor_id.seqz.gz; tabix -f -s 1 -b 2 -e 2 -S 1 $fout/seqz/$tumor_id/$tumor_id.seqz.gz\n";
        	print OUT "Rscript $fout/seqz/$tumor_id.r > $fout/seqz/$tumor_id.log 2>&1\n";
	}
	#cnvkit
	my $tumor_bai = $tumor_bam;
	$tumor_bai =~ s/bam/bai/g;
	my $normal_bai = $normal_bam;
        $normal_bai =~ s/bam/bai/g;
	print OUT "/bin/rm -rf $fout/cnvkit/$tumor_id/*bam;/bin/rm -rf $fout/cnvkit/$tumor_id/*bai\n";
	print OUT "ln -s $tumor_bam $fout/cnvkit/$tumor_id/$tumor_id.T.bam; ln -s $tumor_bai $fout/cnvkit/$tumor_id/$tumor_id.T.bam.bai\n";
	print OUT "ln -s $normal_bam $fout/cnvkit/$tumor_id/$tumor_id.N.bam; ln -s $normal_bai $fout/cnvkit/$tumor_id/$tumor_id.N.bam.bai\n";
	print OUT "bash /home/hef/Tools/cnvkit_liding/src/cnvkit_wxs.tumorNormal.v2.sh -C $cnvkit_ini -p $cnvkit_parameter -S $tumor_id -N $fout/cnvkit/$tumor_id/$tumor_id.N.bam -T $fout/cnvkit/$tumor_id/$tumor_id.T.bam -O $fout/cnvkit|sh\n";
	print OUT "cnvkit.py export seg $fout/cnvkit/$tumor_id/$tumor_id.T.cns --enumerate-chroms -o $fout/pureCN/$tumor_id/$tumor_id.seg\n";	

	#pureCN
        print OUT "gatk Mutect2 -R $ref -L $DB_interval -I $tumor_bam -tumor $tumor_id -I $normal_bam -normal $normal_id --germline-resource $DB_gnomad --panel-of-normals $DB_pon -XL $region_excluded -O $fout/pureCN/$tumor_id/$tumor_id.raw.vcf $add\n";
	if($tumor_id =~/001$/){
		my $mapping_bias = $mapping_bias_wes;

		my $wes_id = $tumor_id;
		$wes_id =~ s/001$/002/g;
	        print OUT "Rscript /home/hef/Tools/miniconda3/lib/R/library/PureCN/extdata/PureCN.R --out $fout/pureCN/$tumor_id --sampleid $tumor_id --tumor $fout/cnvkit/$tumor_id/$tumor_id.T.cnr --seg-file $fout/pureCN/$tumor_id/$tumor_id.seg --mapping-bias-file $mapping_bias --vcf $fout/pureCN/$wes_id/$wes_id.raw.vcf --snp-blacklist $blacklist --genome hg38 --fun-segmentation none --force --post-optimize --seed 123 --sex ?\n";
	}
	elsif ($tumor_id =~/002$/){
                my $mapping_bias = $mapping_bias_wes;

                my $wes_id = $tumor_id;
                print OUT "Rscript /home/hef/Tools/miniconda3/lib/R/library/PureCN/extdata/PureCN.R --out $fout/pureCN/$tumor_id --sampleid $tumor_id --tumor $fout/cnvkit/$tumor_id/$tumor_id.T.cnr --seg-file $fout/pureCN/$tumor_id/$tumor_id.seg --mapping-bias-file $mapping_bias --vcf $fout/pureCN/$wes_id/$wes_id.raw.vcf --snp-blacklist $blacklist --genome hg38 --fun-segmentation none --force --post-optimize --seed 123 --sex ?\n";
        }

}
