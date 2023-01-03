#!usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

my $sgz_output = "/project/gccri/CPRIT_PDX/hef_folder/9.re_sequencing/3.snv/filter/SGZ.tumor_only/output";
my $method1 = "basic.sgz";
my $method2 = "fmi.sgz";

my %flag;
opendir(IN,$sgz_output);
while(readdir IN){
	chomp;
	next if (/full/);
	next unless (/txt/);
	my $file = $_;
	my @t = split /\./, $file;
	my $id = $t[0];

	open FIN, "<$sgz_output/$file" or die $!;
	while(<FIN>){
		chomp;
		next if (/^mutation/);
		my @t = split /\t/;
		if ($file =~ /$method1/){
			$flag{$id}{$t[0]}{$method1} = $t[-1];
		}
		elsif ($file =~ /$method2/){
			$flag{$id}{$t[0]}{$method2} = $t[-2];			
		}
	}
}
#print Dumper(\%flag);

my %germline;
open MAF, "</project/gccri/CPRIT_PDX/hef_folder/z.result/reseq_20221221/tumor_only.reseq.txt" or die $!;
while(<MAF>){
	chomp;
	my @t = split /\t/;
	next if (/Hugo/);
	my $sample = $t[114];

        my $gene = $t[0];
       	my $transcript = $t[37];
        my $mut_c = $t[34];
       	my $mut_p = $t[36];
        my $mut_change = "$gene:$transcript:$mut_c\_$mut_p";

	my $patient_id = $t[115];
	my @k = split /-/, $patient_id;
	$patient_id = $k[0];
	
	if(defined $flag{$sample}{$mut_change}{$method1} && defined $flag{$sample}{$mut_change}{$method2} && !defined $germline{$patient_id}{$mut_change}){
		if ($flag{$sample}{$mut_change}{$method1} eq "germline" &&  $flag{$sample}{$mut_change}{$method2} eq "germline"){
			$germline{$patient_id}{$mut_change}++;
		}
	}

}
close MAF;
#print Dumper(\%germline);

open MAF, "</project/gccri/CPRIT_PDX/hef_folder/z.result/reseq_20221221/tumor_only.reseq.txt" or die $!;
while(<MAF>){
        chomp;
        my @t = split /\t/;
        foreach my $i(@t){
                print "$i\t";
        }

        if (/^Hugo/){
                print "Flag_basic\tFlag_SGZ\tTrue_germline\n";
        }
        else{
		my $sample = $t[114];
		my $gene = $t[0];
	        my $transcript = $t[37];
        	my $mut_c = $t[34];
        	my $mut_p = $t[36];
        	my $mut_change = "$gene:$transcript:$mut_c\_$mut_p";

        	my $patient_id = $t[115];
        	my @k = split /-/, $patient_id;
        	$patient_id = $k[0];

	        my $flag1 = "NA";
	        if(defined $flag{$sample}{$mut_change}{$method1}){
              		$flag1 = $flag{$sample}{$mut_change}{$method1};
        	}
       		 my $flag2 = "NA";
        	if(defined $flag{$sample}{$mut_change}{$method2}){
                	$flag2 = $flag{$sample}{$mut_change}{$method2}
        	}
		my $flag3 = "NA";
       		if (defined $germline{$patient_id}{$mut_change}){
			$flag3 = "TG";	
		}
		print "$flag1\t$flag2\t$flag3\n";
	}
}
