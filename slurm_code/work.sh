perl generate_trim_sh.pl sample.raw_fq.ls

ls script_sh/*sh |awk '{print "perl /home/hef/2.project/1.PDX/a.add_shell_info.pl "$1" > "$1".add"}'|sh
ls script_sh/*add|awk '{print "perl /home/hef/2.project/1.PDX/b.generate_sbatch.forshell.pl "$1" 1 1-23:59:59 > "$1".sbatch"}'|sh
ls script_sh/*sbatch|awk '{print "perl /home/hef/2.project/1.PDX/c.submit_jobs.pl "$1"|sh"}'|sh

