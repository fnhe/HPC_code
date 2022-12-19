#!usr/bin/perl
use strict;
use warnings;
my $cpu = 8;
my $outdir = "/project/gccri/OPTIMIST/analysis/RNA";

my $gtf_h = "/home/hef/Data/hg38/optimist_ref/gencodev22/gencode.v22.annotation.gtf";
my $gff_h = "/home/hef/Data/hg38/optimist_ref/gencodev22/gencode.v22.annotation.gff3";

my $rnaseqc_gtf = "/home/hef/Data/hg38/gencode.v22.genes.gtf";
my $kallisto_h = "/home/hef/Data/hg38/optimist_ref/gencodev22/gencode.v22.all_transcripts.fa.idx";

my $ctat_lib_dir = "/home/hef/Data/hg38/optimist_ref/GRCh38_gencode_v22.star-fusion.v1.10";

my $pwd = `pwd`;
chomp $pwd;
`mkdir -p $outdir/1.trim $outdir/1.trim/trimmed_fq $outdir/2.exp $outdir/2.exp/1.kallisto $outdir/3.fusion $outdir/3.fusion/1.star_fusion $outdir/3.fusion/2.PRADA $outdir/2.exp/2.RSEM $outdir/2.exp/3.htseq $outdir/4.rnaseqc`;
`mkdir -p $pwd/script_sh`;

open OT, ">trimmed_fq.ls" or die $!;
open IN,"<$ARGV[0]" or die $!;
while(<IN>){
        chomp;
        my ($id, $fq1, $fq2) = split /\t/;
        open SH, ">script_sh/$id.rna.sh" or die $!;
        print SH "trim_galore --phred33 --fastqc --length 50 -q 20 -o $outdir/1.trim/trimmed_fq --paired $fq1 $fq2 --dont_gzip\n";

	print SH "ln -s $outdir/1.trim/trimmed_fq/$id\_R1_val_1.fq $outdir/1.trim/Final_fq/$id.R1.fq;ln -s $outdir/1.trim/trimmed_fq/$id\_R2_val_2.fq $outdir/1.trim/Final_fq/$id.R2.fq\n";	
	$fq1 = "$outdir/1.trim/Final_fq/$id.R1.fq";
	$fq2 = "$outdir/1.trim/Final_fq/$id.R2.fq";
	print OT "$id\t$fq1\t$fq2\n";
	print SH "kallisto quant -i $kallisto_h -o $outdir/2.exp/1.kallisto/$id -t $cpu --plaintext $fq1 $fq2\n";

	print SH "/home/hef/Tools/STAR-Fusion-v1.10.0/STAR-Fusion --genome_lib_dir $ctat_lib_dir --left_fq $fq1 --right_fq $fq2 --FusionInspector validate --examine_coding_effect --CPU $cpu --output_dir $outdir/3.fusion/1.star_fusion/$id\n";
	print SH "source /home/hef/Tools/miniconda3/etc/profile.d/conda.sh;conda activate prada\n";
	print SH "python /home/hef/Tools/PRADA2-master/prada2.py --read1 $fq1 --read2 $fq2 --outdir $outdir/3.fusion/2.PRADA\n";
	print SH "python /home/hef/Tools/PRADA2-master/prada2.py --read1 $fq1 --read2 $fq2 --outdir $outdir/3.fusion/2.PRADA --fusion\n";
	print SH "conda deactivate\n";
	print SH "source /home/hef/Tools/miniconda3/etc/profile.d/conda.sh;conda activate py2\n";
	print SH "python /home/hef/Tools/PRADA2-master/prada2.py --read1 $fq1 --read2 $fq2 --outdir $outdir/3.fusion/2.PRADA --rsem\n";
	print SH "conda deactivate\n";
	print SH "ln -s $outdir/3.fusion/2.PRADA/$id/rsem_results/rsem.genes.results $outdir/2.exp/2.rsem/$id.genes.results ; ln -s $outdir/3.fusion/2.PRADA/$id/rsem_results/rsem.isoforms.results $outdir/2.exp/2.rsem/$id.isoforms.results\n";

	print SH "samtools sort -m 2G -@ $cpu -o $outdir/2.exp/3.htseq/$id.sorted.bam $outdir/3.fusion/1.star_fusion/$id/Aligned.out.bam; samtools index $outdir/2.exp/3.htseq/$id.sorted.bam\n";
        print SH "htseq-count -s no -f bam -r pos -n $cpu -t exon -i ID -m union --nonunique all $outdir/2.exp/3.htseq/$id.sorted.bam $gff_h --additional-attr=gene_id --additional-attr=gene_name --additional-attr=transcript_id --additional-attr=exon_number > $outdir/2.exp/3.htseq/$id.htseq.txt\n";

	print SH "rnaseqc $rnaseqc_gtf $outdir/2.exp/3.htseq/$id.sorted.bam --coverage $outdir/4.rnaseqc/$id\n";
}



