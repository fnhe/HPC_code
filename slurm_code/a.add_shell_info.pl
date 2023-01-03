#!usr/bin/perl
use strict;
use warnings;

my $num = 0;
open IN, "<$ARGV[0]" or die $!;
while(<IN>){
	chomp;
	my $line = $_;
	$num ++;	
	print "echo Job$num\n";
	print "echo Job$num start:`date`\n";
	print "if\n";
	print "\t$line\n";
	print "then\n";	
	print "\techo Job$num done:`date`\n";
	print "else\n";
	print "\techo ERROR in: $line\n";	
	print "\texit\n";
	print "fi\n";
}
