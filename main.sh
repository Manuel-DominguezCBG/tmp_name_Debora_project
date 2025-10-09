#!/bin/bash -e

#SBATCH --nodes=1
#SBATCH --job-name=FullAnalysis
#SBATCH --output=./%x.%j.log
#SBATCH --error=./%x.%j.log
#SBATCH --time=20:00:00

# Set strict error handling
set -euo pipefail


# Load necessary modules
samtools='apptainer exec --bind /mnt/data1:/mnt/data1 --bind /mnt/scratch1:/mnt/scratch1 docker://quay.io/biocontainers/samtools:1.20--h50ea8bc_0 samtools'
bedtools='apptainer exec --bind /mnt/data1:/mnt/data1 --bind /mnt/scratch1:/mnt/scratch1 docker://quay.io/biocontainers/bedtools:2.24--1 bedtools'


# Constants
Platform=ILLUMINA
ExperimentName=251002DM-MSRCPCR
ReferenceGenome="/mnt/data1/db/gcp-public-data--broad-references/hg38/v0/GIABv1mask/Homo_sapiens_assembly38.GIABv1mask.fasta"
InputDir=$1  # First argument to the script is the input directory
RunID=C2GC3
OutputDir="${InputDir}/BAM"
ReportDir="${InputDir}/Reports"
BED_FILE="/mnt/scratch1/projects/Deborah/Deborah-M-mapping-and-counting-reads/05022025_Debora.bed"

# Create output directories for BAM and report files if they do not exist
mkdir -p "${OutputDir}"
mkdir -p "${ReportDir}"


# Loop through each R1 file in the input directory for alignment and BAM file creation
for R1 in "${InputDir}"/*R1_001.fastq.gz; do
    # Identify the corresponding R2 file
    R2="${R1/R1_001/R2_001}"
    
    # Extract Sample ID from filename
    Sample_ID=$(basename "$R1" | cut -d'_' -f1)
    
    # Filename for the output BAM
    output_bam="${OutputDir}/${RunID}_${Sample_ID}_aligned.bam"

    # Alignment with bwa and sorting with samtools
    apptainer exec --bind /mnt:/mnt docker://quay.io/biocontainers/bwa:0.7.18--he4a0461_0 bwa mem \
    -R "@RG\tID:${RunID}_${Sample_ID}\tSM:${Sample_ID}\tPL:${Platform}\tLB:${ExperimentName}" \
    -K 100000000 \
    -v 3 \
    -t 1 \
    -Y \
    "$ReferenceGenome" \
    "$R1" "$R2" | \
    $samtools sort \
    -O bam \
    -o "$output_bam"

    # Index the BAM file
    $samtools index "$output_bam"

    echo "Completed processing for $Sample_ID"
done

# Loop over each BAM file in the output directory to generate reports
for BAM in "${OutputDir}"/*.bam; do
    # Generate the name for the CSV output file based on the BAM file name
    CSV_FILE="${ReportDir}/$(basename ${BAM%.bam})_aligned.report"

    # Use bedtools to count the reads overlapping the BED regions
    #bedtools intersect -a "$BED_FILE" -b "$BAM" -c > "$CSV_FILE"
    $bedtools multicov -bams "$BAM" -bed "$BED_FILE" -f 0.85 -r > "$CSV_FILE"

    echo "Generated read counts for $BAM in $CSV_FILE"
done

