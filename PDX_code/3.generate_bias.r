library(PureCN)
normal.panel.vcf.file <- "/project/gccri/CPRIT_PDX/hef_folder/3.DNA_mutation/1.somatic/2.without_Germline/sm_withoutG/PON/pon_WES.merge.vcf.gz"
bias <- calculateMappingBiasVcf(normal.panel.vcf.file, genome = "hg38")
saveRDS(bias, "/project/gccri/CPRIT_PDX/hef_folder/5.CNV/pureCN/WES_mapping_bias.rds")
