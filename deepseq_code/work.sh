#Get UMI unaligned bam
les dp.ls|awk '{print "picard FastqToSam F1="$2" F2="$3" SM="$1" RG="$1" O=585.unaligned.bam"}'|sh
fgbio ExtractUmisFromBam -i 585.unaligned.bam -o 585.unaligned.umi.bam -r 5M2S+T 5M2S+T -t RX

#get aligned bam
picard SamToFastq I=585.unaligned.umi.bam F=585.R1.fq.gz F2=585.R2.fq.gz
bwa mem -t 8 -M -R "@RG\tID:585\tPL:illumina\tLB:585\tPU:585\tSM:585" /home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta 585.R1.fq.gz 585.R2.fq.gz -o 585.sam
picard SamFormatConverter I=585.sam O=585.bam

#Merge bam
gatk MergeBamAlignment --ALIGNED_BAM 585.bam --UNMAPPED_BAM 585.unaligned.umi.bam --OUTPUT merge.bam --REFERENCE_SEQUENCE /home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta --ATTRIBUTES_TO_RETAIN X0  --ATTRIBUTES_TO_REMOVE NM --ATTRIBUTES_TO_REMOVE MD  --SORT_ORDER queryname  --ALIGNED_READS_ONLY true --MAX_INSERTIONS_OR_DELETIONS -1  --PRIMARY_ALIGNMENT_STRATEGY MostDistant  --ALIGNER_PROPER_PAIR_FLAGS true  --CLIP_OVERLAPPING_READS false
picard MarkDuplicates I=merge.bam O=merge.dedup.bam  M=585.dedup.metrics.txt BARCODE_TAG=RX

#Get consensus bam
gatk BedToIntervalList --INPUT probe.bed --SEQUENCE_DICTIONARY /home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.dict --OUTPUT bait.interval_list
gatk CollectHsMetrics  --BAIT_INTERVALS bait.interval_list --BAIT_SET_NAME deepseq --TARGET_INTERVALS bait.interval_list --INPUT merge.dedup.bam --OUTPUT 585_hs_metrics.txt  --REFERENCE_SEQUENCE /home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta --PER_BASE_COVERAGE 585_hs_metrics.per_base_coverage.txt 
fgbio SortBam -s TemplateCoordinate -i merge.dedup.bam -o merge.dedup.sort.bam
fgbio GroupReadsByUmi --input=merge.dedup.sort.bam  --output=merge_grouped.bam -t RX -f 585_umi_group_data.tsv --strategy=adjacency --edit=1
fgbio CallMolecularConsensusReads  --input=merge_grouped.bam --output=merge_grouped_consensus.bam --error-rate-post-umi 40  --error-rate-pre-umi 45  --output-per-base-tags false  --min-reads 2  --max-reads 50  --min-input-base-quality 20 --read-name-prefix='consensus'

#re-aligned to consensus bam
picard SamToFastq I=merge_grouped_consensus.bam F=585.consensus.R1.fq.gz F2=585.consensus.R2.fq.gz
bwa mem -t 8 -M -R "@RG\tID:585\tPL:illumina\tLB:585\tPU:585\tSM:585" /home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta 585.consensus.R1.fq.gz 585.consensus.R2.fq.gz |samtools view -bh - -o 585_consensus_mapped.bam

#statics
gatk CollectHsMetrics  --BAIT_INTERVALS bait.interval_list --BAIT_SET_NAME deepseq --TARGET_INTERVALS bait.interval_list --INPUT 585_consensus_mapped.bam --OUTPUT 585_hs_metrics.2.txt  --REFERENCE_SEQUENCE /home/hef/Data/hg38/resources_broad_hg38_v0/Homo_sapiens_assembly38.fasta --PER_BASE_COVERAGE 585_hs_metrics.per_base_coverage.2.txt
