#!/bin/bash

BASE_DIR='/cluster/pixstor/slotkinr-lab/sandaruwan/amplicon_seq/'

TRIM_DIR="$BASE_DIR/02_TRIMMED_READS"


## load modules

module load bwa/0.7.18_gcc_12.3.0
module load samtools/1.20_gcc_12.3.0

#Mapping
############################################################
REF_DIR='/cluster/pixstor/slotkinr-lab/sandaruwan/amplicon_seq/analysis/reference/Ref_R18'


BASE_DIR='/cluster/pixstor/slotkinr-lab/sandaruwan/amplicon_seq/'
TRIM_DIR="$BASE_DIR/02_TRIMMED_READS"

SAM_DIR="$BASE_DIR/02_TRIMMED_READS/02_MAPPING/SAM_FILES"
BAM_DIR="$BASE_DIR/02_TRIMMED_READS/02_MAPPING/BAM_FILES"
SORTED_BAM="$BASE_DIR/02_TRIMMED_READS/02_MAPPING/SORTED_BAM_FILES"



#reference
#change the refence according as needed
#declare reference in a array
declare -A REF_GENOMES=(
  [d1_up]="${REF_DIR}/ACT8_mPing_d1_up.fa"
  [d1_dw]="${REF_DIR}/ACT8_mPing_d1_down.fa"
  [d2_up]="${REF_DIR}/ACT8_mPIng_d2_up.fa"
  [d2_dw]="${REF_DIR}/ACT8_mPIng_d2_down.fa"
)


#check for existing ref index
#BWA build index
for ref_name in "${!REF_GENOMES[@]}";
	do
	ref_fa="${REF_GENOMES[$ref_name]}"

	if [[ -f "${ref_fa}.bwt" ]]; then
		echo "Index file found"
	else
		samtools faidx "${ref_fa}"
		bwa index "${ref_fa}"
	fi

done



mkdir -p "${SAM_DIR}"
mkdir -p "${BAM_DIR}"
mkdir -p "${SORTED_BAM}"



#BWA-mem mapping
for file in ${TRIM_DIR}/*.fastq.gz; do
    basename=$(basename "$file" .fastq.gz)
    fnm=${basename%%_*}
    echo "Processing sample: ${fnm}"

    for ref_name in "${!REF_GENOMES[@]}"; do
        ref_fa="${REF_GENOMES[$ref_name]}"

        echo "  Mapping to ${ref_name}"


		bwa mem  -t 8 "${ref_fa}" "${file}"  > "${SAM_DIR}/${fnm}_${ref_name}_aligned.sam"
		samtools view -S -b "${SAM_DIR}/${fnm}_${ref_name}_aligned.sam" > "${BAM_DIR}/${fnm}_${ref_name}_aligned.bam"
		samtools sort "${BAM_DIR}/${fnm}_${ref_name}_aligned.bam" > "${SORTED_BAM}/${fnm}_${ref_name}_sorted.bam"
		samtools index "${SORTED_BAM}/${fnm}_${ref_name}_sorted.bam"

    done
done




cd ${SAM_DIR} 
rm *_aligned.sam


#-----------------------------------------------Add RG tag----------------------------------------------
##add RG tag
##if no RG tag added GATK will not run accurately

module load picard/3.2.0

OUT_TG_DIR="$BASE_DIR/02_TRIMMED_READS/02_MAPPING/BAM_FILES/SORTED_TG_BAM"



for file in ${SORTED_BAM}/*_sorted.bam; 
	do
	echo ${file}
 	basename=$(basename "$file" _sorted.bam)
 	echo ${basename}
 	fnm=${basename%%_*}
	echo ${fnm}

	
	java -jar /cluster/software/src/picard/picard.jar AddOrReplaceReadGroups \
       I="${file}" \
       O="${out_tgdir}/${basename}_sorted_RGtg.bam" \
       RGID="${basename}" \
       RGLB=lib2 \
       RGPL=ILLUMINA \
       RGPU=unit2 \
       RGSM="${basename}"

	
	samtools index "${OUT_TG_DIR}/${basename}_sorted_RGtg.bam"
		
	
		
  
done