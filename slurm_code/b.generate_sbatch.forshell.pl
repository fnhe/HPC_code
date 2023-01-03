#!usr/bin/perl
use strict;
use warnings;

if( $ARGV[0] eq '-h' || $ARGV[0] eq '-help'){help();exit;}
sub help { print "Usage: perl generate_sbatch.forshell.pl filein cpus job_time> sbatch\n";}

my $pwd = `pwd`;
chomp $pwd;
my $file = shift;
my $cpu = shift // 1;
my $time = shift // "1-23:58:58";

`mkdir -p $pwd/slurm_out`;
print "#!/bin/bash\n";
print "#SBATCH --job-name $file\n";
print "#SBATCH --nodes 1\n";
print "#SBATCH --ntasks 1\n";
print "#SBATCH --cpus-per-task $cpu\n";
print "#SBATCH --mem 16G\n";
print "#SBATCH --partition=compute\n";  #bigmem, compute, GPU
print "#SBATCH --time $time\n";
print "#SBATCH --output $pwd/slurm_out/%j.out\n";
print "#SBATCH --mail-user hef\@uthscsa.edu\n";

print "module load slurm/18.08.9\n";
print "module use -a  /home/hef/z.modulefiles\n";
print "module load miniconda3/4.10.3 fastqc/0.11.9 bwa/0.7.17 gatk/4.2.3.0 samtools/1.14 kallisto/0.46.0 trim_galore/0.6.7\n";
print "srun sh $pwd/$file > $pwd/$file.log\n";

