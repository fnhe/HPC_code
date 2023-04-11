less paired.ls|cut -f2,4|sort -u|grep "Germ"|awk '{print "gatk Mutect2 -R /home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta -I "$2" --max-mnp-distance 0 -O /project/gccri/CPRIT_PDX/hef_folder/3.DNA_mutation/1.somatic/2.without_Germline/sm_withoutG/PON/"$1".vcf.gz"}'> pon.sh 

### For mutect
#generate genomicDB
ls /project/gccri/CPRIT_PDX/hef_folder/3.DNA_mutation/1.somatic/2.without_Germline/sm_withoutG/PON/*WES*gz|awk '{print " -V "$1}'|xargs|awk '{print "gatk GenomicsDBImport -R /home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta -L /home/hef/Data/files_liding/mutect/wgs_calling_regions.hg38.interval_list  --genomicsdb-workspace-path pon_db_WES "$0}'|sh
ls /project/gccri/CPRIT_PDX/hef_folder/3.DNA_mutation/1.somatic/2.without_Germline/sm_withoutG/PON/*WGS*gz|awk '{print " -V "$1}'|xargs|awk '{print "gatk GenomicsDBImport -R /home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta -L /home/hef/Data/files_liding/mutect/wgs_calling_regions.hg38.interval_list  --genomicsdb-workspace-path pon_db_WGS "$0}'|sh

#create PON
gatk CreateSomaticPanelOfNormals -R /home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta  --germline-resource /home/hef/Data/files_liding/mutect/af-only-gnomad.hg38.vcf.gz -V gendb://pon_db_WES -O pon.WES.vcf.gz 

### Generate PON from mutect's PON (for pureCN mapping bias)
ls /project/gccri/CPRIT_PDX/hef_folder/3.DNA_mutation/1.somatic/2.without_Germline/sm_withoutG/PON/*vcf.gz|sed '/pon/d'|grep "WES"|xargs|bcftools merge - -O z -o pon_WES.merge.vcf
#bcftools merge 1753_Germline_WES.vcf.gz ….  -O z -o pon_WES.merge.vcf
ls /project/gccri/CPRIT_PDX/hef_folder/3.DNA_mutation/1.somatic/2.without_Germline/sm_withoutG/PON/*vcf.gz|sed '/pon/d'|grep "WGS"|xargs|bcftools merge - -O z -o pon_WGS.merge.vcf

bgzip pon_WES.merge.vcf
tabix -p vcf pon_WES.merge.vcf.gz

