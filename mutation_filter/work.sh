perl 1.mutation_fil.pl all.ls

ls script_sh/*sh |awk '{print "perl /home/hef/2.project/1.PDX/a.add_shell_info.pl "$1" > "$1".add"}'|sh
ls script_sh/*add|awk '{print "perl /home/hef/2.project/1.PDX/b.generate_sbatch.forshell.pl "$1" 1 30-23:59:59 > "$1".sbatch"}'|sh
ls script_sh/*sbatch|awk '{print "perl /home/hef/2.project/1.PDX/c.submit_jobs.pl "$1"|sh"}'|sh

#annotation
ls /project/gccri/CPRIT_PDX/hef_folder/9.re_sequencing/3.snv/filter/remove_PON|grep "vcf$"|sed 's/\.vcf//g'|awk '{print $1"\t/project/gccri/CPRIT_PDX/hef_folder/9.re_sequencing/3.snv/filter/remove_PON/"$1".vcf"}' > tumor_normal.vcf.ls
perl 2.generate_vep.pl tumor_normal.vcf.ls > run_vep.sh

# for notmal-tumor
les tumor_normal.ls |cut -f1 > sample.ls
perl 3.combineVCF.tumorNormal.pl sample.ls
ls sh_merge/*sh |awk '{print "perl /home/hef/2.project/1.PDX/a.add_shell_info.pl "$1" > "$1".add"}'|sh
ls sh_merge/*add|awk '{print "perl /home/hef/2.project/1.PDX/b.generate_sbatch.forshell.pl "$1" 1 30-23:59:59 > "$1".sbatch"}'|sh
ls sh_merge/*sbatch|awk '{print "perl /home/hef/2.project/1.PDX/c.submit_jobs.pl "$1"|sh"}'|sh

# for tumor-only
les ../tumor_only.ls |awk '{print $1"\t"$1"\t"$2}'|sed 's/_PDX_WES//'|sed 's/_PDX_WGS//' > ids.not_paired.ls
perl a.generate_cnv.SGZ.pl ids.not_paired.ls #change 896751 to 1939_Dup
perl b.generate_mut.SGZ.pl
les tumor_only.ls |cut -f1|sort -u > sample.ls #add header sampleID
conda activate py2
cd ~/Tools/SGZ
python ~/Tools/SGZ/run_test.py -s /home/hef/2.project/1.PDX/b.re-sequencing/mutation_fil/sample.ls -t /project/gccri/CPRIT_PDX/hef_folder/9.re_sequencing/3.snv/filter/SGZ.tumor_only/data -o /project/gccri/CPRIT_PDX/hef_folder/9.re_sequencing/3.snv/filter/SGZ.tumor_only/output
perl c.add_flag2maf.pl >tumor_only.reseq.addSGZ.txt
