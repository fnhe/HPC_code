#!usr/bin/perl
use strict;
use warnings;
my $pwd = `pwd`;
chomp $pwd;

if( $ARGV[0] eq '-h' || $ARGV[0] eq '-help'){help();exit;}
sub help { print "Usage: perl submit_jobs.pl sbatch|sh\n";}

my $sbatch = shift;
print "module load slurm/18.08.9\ndos2unix $pwd/$sbatch\nsbatch $pwd/$sbatch\n";
