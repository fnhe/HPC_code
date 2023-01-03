#!usr/bin/perl
use strict;
use warnings;

while(<>){
	chomp;
	print "salloc --nodes=1 --ntasks-per-node=1 -A gccri\n";
	print "srun sh $_\n";
	print "exit\n";
}
