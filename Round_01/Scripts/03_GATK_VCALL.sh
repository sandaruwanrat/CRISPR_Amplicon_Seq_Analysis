#!/bin/bash


## load modules
module load samtools/1.20_gcc_12.3.0
module load gatk/4.5.0.0_gcc_12.3.0
module load picard/3.2.0

#reference
REF_DIR='/cluster/pixstor/slotkinr-lab/sandaruwan/amplicon_seq/analysis/CRISPR_Amplicon_Seq_Analysis/Round_01/Ref_R1'

BASE_DIR='/cluster/pixstor/slotkinr-lab/sandaruwan/amplicon_seq/'
BAM_TG_DIR="$BASE_DIR/02_TRIMMED_READS/02_MAPPING/SORTED_TG_BAM"

VCF_DIR="$BASE_DIR/02_TRIMMED_READS/03_GATK_VCF"

mkdir -p "${VCF_DIR}"


declare -A REF_GENOMES=(
  [d1_up]="${REF_DIR}/ACT8_mPing_d1_up.fa"
  [d1_dw]="${REF_DIR}/ACT8_mPing_d1_down.fa"
  [d2_up]="${REF_DIR}/ACT8_mPIng_d2_up.fa"
  [d2_dw]="${REF_DIR}/ACT8_mPIng_d2_down.fa"
)


# create gatk refence


for ref_name in "${!REF_GENOMES[@]}"; do
    ref_fa="${REF_GENOMES[$ref_name]}"
    ref_dir=$(dirname "$ref_fa")
    ref_base=$(basename "$ref_fa" .fa)
    dict="${ref_dir}/${ref_base}.dict"

    echo "Checking GATK dict for ${ref_base}"

    if [[ -f "$dict" ]]; then
        echo "GATK dict found"
    else
        echo "Creating GATK dict"
        java -jar /cluster/software/src/picard/picard.jar CreateSequenceDictionary \
            R="$ref_fa" \
            O="$dict"
    fi
done




for file in ${BAM_TG_DIR}/*_sorted_RGtg.bam; 
	do

 	basename=$(basename "$file" _sorted_RGtg.bam)
 	echo ${basename}
 	fnm=${basename%%_*}

	echo "sample >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ${fnm}"

	#get genome tag (d1_up, d1_dw, d2_up, d2_dw)
    genome_tag=$(echo "$basename" | grep -oE 'd[12]_(up|dw)')

	#check missing tag
	if [[ -z "$genome_tag" ]]; then
        echo "ERROR: Could not determine genome for $basename" >&2
        continue
    fi

	ref="${REF_GENOMES[$genome_tag]}"
	
	
	echo "genome tag>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ${genome_tag}"

	gatk HaplotypeCaller -R ${ref} \
	-I "${file}" \
	  -O "${VCF_DIR}/${basename}_nmkd.vcf.gz" --max-reads-per-alignment-start 0 --disable-tool-default-read-filters -ERC BP_RESOLUTION
	

		
  
done

