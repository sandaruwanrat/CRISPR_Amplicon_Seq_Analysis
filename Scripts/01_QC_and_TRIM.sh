#!/bin/bash

#RAW Amplicon seq Directory
BASE_DIR='/cluster/pixstor/slotkinr-lab/sandaruwan/amplicon_seq/'
RAW_DIR="$BASE_DIR/00_RAW_READS"
QC_BF_TRIM="$BASE_DIR/01_QC_bfTRIM"
TRIM_DIR="$BASE_DIR/02_TRIMMED_READS"
QC_AFT_TRIM="$TRIM_DIR/QC_afTRIM"

fastqc --threads 16 -q -o ${QC_BF_TRIM} ${RAW_DIR}/*.fastq.gz

multiqc ${QC_BF_TRIM} -o ${QC_BF_TRIM}


for file in ${raw_dir}/*.gz; 
	do
  
  filename=$(basename "$file" .fastq.gz)
  smp_name=${filename%%_*}

  echo ${file}
  echo ${smp_name}
  
  cutadapt -j 2 -a "CTGTCTCTTATACACATCT;min_overlap=10;e=0.1" "$file" -o "${smp_name}_trimmed.fastq.gz"
  
done



for file in ${raw_dir}/*.gz; 
do
  basename=$(basename "$file" .fastq.gz)

  echo ${basename}
  
  seqkit stat --basename "${file}" | awk '{print $1,$4}' OFS='\t' >> "${trim_out_dir}/raw_fastq_read_count_R18.txt"

done



mkdir -p "${qc_dir}"

fastqc --threads 16 -q -o ${qc_dir} ${trim_out_dir}/*trimmed.fastq.gz

multiqc ${qc_dir} -o ${qc_dir}

