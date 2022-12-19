#!usr/bin/perl
use strict;
use warnings;
my $cpu = 8;
my $outdir = "/project/gccri/OPTIMIST/analysis/DNA";

my $ref = "/home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta";
my $known_dbsnp = "/home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.dbsnp138.vcf";
my $known_dbsnp_1000 = "/home/hef/Data/hg38/resources_broad_hg38_v0/1000G_phase1.snps.high_confidence.hg38.vcf";
my $Mills_indel = "/home/hef/Data/hg38/resources_broad_hg38_v0/Mills_and_1000G_gold_standard.indels.hg38.vcf";
my $known_indel = "/home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.known_indels.vcf";

my $pwd = `pwd`;
chomp $pwd;
`mkdir -p $pwd/script_sh`;
`mkdir -p $outdir/1.trim $outdir/1.trim/Final_fq $outdir/2.gatk`;
open OT, ">trimmed_fq.ls" or die $!;
open IN,"<$ARGV[0]" or die $!;
while(<IN>){
        chomp;
        my ($id, $fq1, $fq2) = split /\t/;
        open SH, ">script_sh/$id.bam.sh" or die $!;
        print SH "trim_galore --phred33 --fastqc --length 50 -q 20 -o $outdir/1.trim/trimmed_fq --paired $fq1 $fq2 \n";

	print SH "ln -s $outdir/1.trim/trimmed_fq/$id\_R1\_val\_1.fq.gz $outdir/1.trim/Final_fq/$id.R1.fq.gz;ln -s $outdir/1.trim/trimmed_fq/$id\_R2\_val\_2.fq.gz $outdir/1.trim/Final_fq/$id.R2.fq.gz\n";	
	$fq1 = "$outdir/1.trim/Final_fq/$id.R1.fq.gz";
	$fq2 = "$outdir/1.trim/Final_fq/$id.R2.fq.gz";
	print OT "$id\t$fq1\t$fq2\n";

	my $fout = "$outdir/2.gatk";
	print SH "bwa mem -t 8 -M -R \"\@RG\\tID:$id\\tPL:illumina\\tLB:$id\\tPU:$id\\tSM:$id\" $ref $fq1 $fq2|samtools view -Shb -o $fout/$id.bam -\n";
	print SH "java -Xmx16g -Djava.io.tmpdir=$pwd/tmp -jar /home/hef/Tools/miniconda3/bin/picard.jar AddOrReplaceReadGroups I=$fout/$id.bam O=$fout/$id.added.sorted.bam SO=coordinate RGLB=$id RGPL=illumina RGPU=$id RGSM=$id\n";
	print SH "samtools flagstat $fout/$id.added.sorted.bam > $fout/$id.mapping.txt\n";
	print SH "java -Xmx16g -Djava.io.tmpdir=$pwd/tmp -jar /home/hef/Tools/miniconda3/bin/picard.jar MarkDuplicates I=$fout/$id.added.sorted.bam O=$fout/$id.added.dedupped.bam VALIDATION_STRINGENCY=SILENT CREATE_INDEX=true M=$fout/$id.dedup.metrics.txt\n";
	print SH "java -Xmx16g -Djava.io.tmpdir=$pwd/tmp -jar /home/hef/Tools/gatk-4.2.3.0/GenomeAnalysisTK.jar -T RealignerTargetCreator -nt 8 -R $ref -I $fout/$id.added.dedupped.bam -known $Mills_indel -known $known_indel -o $fout/$id.intervals.list\n";
	print SH "java -Xmx16g -Djava.io.tmpdir=$pwd/tmp -jar /home/hef/Tools/gatk-4.2.3.0/GenomeAnalysisTK.jar -T IndelRealigner -R $ref -I $fout/$id.added.dedupped.bam -known $Mills_indel -known $known_indel -targetIntervals $fout/$id.intervals.list  -o $fout/$id.dedupped.realigned.bam\n";
	print SH "java -Xmx16g -Djava.io.tmpdir=$pwd/tmp -jar /home/hef/Tools/gatk-4.2.3.0/GenomeAnalysisTK.jar -T BaseRecalibrator -nct 8 -R $ref -I $fout/$id.dedupped.realigned.bam --knownSites $known_dbsnp_1000 --knownSites $known_dbsnp --knownSites $Mills_indel --knownSites $known_indel -o $fout/$id.data.table\n";
	print SH "java -Xmx16g -Djava.io.tmpdir=$pwd/tmp -jar /home/hef/Tools/gatk-4.2.3.0/GenomeAnalysisTK.jar -T PrintReads -nct 8 -R $ref -I $fout/$id.dedupped.realigned.bam -BQSR $fout/$id.data.table -o $fout/$id.dedupped.realigned.recal.bam\n";
	print SH "/bin/rm -rf $fout/$id.added.dedupped.ba* $fout/$id.dedupped.realigned.ba* $fout/$id.*sorted*ba*\n";


}
