#!/usr/bin/env bash
# =====================================================================
# Script: main.sh
# Description: Perform full alignment and coverage analysis of Illumina
#              FASTQ files using bwa, samtools, and bedtools in Apptainer.
#
# Author: Manuel Dominguez
# Version: 1.0
# Date: 2025-05-12
#
# Usage:
#   sbatch main.sh <InputDir>
#
# Requirements:
#   - SLURM workload manager
#   - Apptainer or Singularity installed
#   - Access to /mnt/scratch1 and /mnt/data1
#   - FASTQ files named *R1_001.fastq.gz and *R2_001.fastq.gz
#
# Notes:
#   This script is part of the analysis workflow described in the manuscript.
# =====================================================================

#SBATCH --nodes=1
#SBATCH --job-name=FullAnalysis
#SBATCH --output=./%x.%j.log
#SBATCH --error=./%x.%j.log
#SBATCH --time=20:00:00
#SBATCH --mem=32G

# --------------------------------------------------------------------- #
# Strict error handling
set -euo pipefail

# --------------------------------------------------------------------- #
# Containerized tool definitions (biocontainers from Quay.io)
SAMTOOLS="apptainer exec --bind /mnt/data1:/mnt/data1 --bind /mnt/scratch1:/mnt/scratch1 docker://quay.io/biocontainers/samtools:1.20--h50ea8bc_0 samtools"
BEDTOOLS="apptainer exec --bind /mnt/data1:/mnt/data1 --bind /mnt/scratch1:/mnt/scratch1 docker://quay.io/biocontainers/bedtools:2.24--1 bedtools"
BWA="apptainer exec --bind /mnt:/mnt docker://quay.io/biocontainers/bwa:0.7.18--he4a0461_0 bwa"

# --------------------------------------------------------------------- #
# CONSTANTS
PLATFORM="ILLUMINA"
EXPERIMENT_NAME="ML2379327-REAGT"
REFERENCE_GENOME="/mnt/data1/db/gcp-public-data--broad-references/hg38/v0/GIABv1mask/Homo_sapiens_assembly38.GIABv1mask.fasta"
BED_FILE="/mnt/scratch1/projects/Manuel_tmp/tmp_name_Debora_project/05022025_Debora.bed"
RUN_ID="H7NYKG"

# Input directory (required argument)
INPUT_DIR=${1:-}
if [[ -z "$INPUT_DIR" ]]; then
    echo "Usage: sbatch $0 <InputDir>"
    exit 1
fi

# Output directories
OUTPUT_DIR="${INPUT_DIR}/BAM"
REPORT_DIR="${INPUT_DIR}/Reports_${RUN_ID}"

mkdir -p "${OUTPUT_DIR}" "${REPORT_DIR}"

# --------------------------------------------------------------------- #
# ALIGNMENT STEP
echo "=== Starting alignment for run: ${RUN_ID} ==="
for R1 in "${INPUT_DIR}"/*R1_001.fastq.gz; do
    [[ -e "$R1" ]] || { echo "No FASTQ files found in ${INPUT_DIR}"; exit 1; }

    R2="${R1/R1_001/R2_001}"
    SAMPLE_ID=$(basename "$R1" | cut -d'_' -f1)

    UNSORTED_BAM="${OUTPUT_DIR}/${RUN_ID}_${SAMPLE_ID}_unsorted.bam"
    OUTPUT_BAM="${OUTPUT_DIR}/${RUN_ID}_${SAMPLE_ID}_aligned.bam"

    echo "Processing sample: ${SAMPLE_ID}"

    # Step 1: Alignment with BWA-MEM
    ${BWA} mem \
        -R "@RG\tID:${RUN_ID}_${SAMPLE_ID}\tSM:${SAMPLE_ID}\tPL:${PLATFORM}\tLB:${EXPERIMENT_NAME}" \
        -K 100000000 -v 3 -t 1 -Y \
        "${REFERENCE_GENOME}" \
        "${R1}" "${R2}" | \
        ${SAMTOOLS} view -bS -o "${UNSORTED_BAM}" -

    # Step 2: Sort BAM
    ${SAMTOOLS} sort -O bam -o "${OUTPUT_BAM}" "${UNSORTED_BAM}"

    # Step 3: Index BAM and clean up
    ${SAMTOOLS} index "${OUTPUT_BAM}"
    rm -f "${UNSORTED_BAM}"

    echo "Completed processing for ${SAMPLE_ID}"
done

# --------------------------------------------------------------------- #
# COVERAGE ANALYSIS STEP
echo "=== Starting coverage analysis ==="
for BAM in "${OUTPUT_DIR}"/*.bam; do
    CSV_FILE="${REPORT_DIR}/$(basename "${BAM%.bam}")_aligned.report"

    ${BEDTOOLS} multicov \
        -bams "${BAM}" \
        -bed "${BED_FILE}" \
        -f 0.85 \
        -r > "${CSV_FILE}"

    echo "Generated coverage report: ${CSV_FILE}"
done

echo "=== Full analysis completed successfully ==="
echo "BAM files: ${OUTPUT_DIR}"
echo "Reports: ${REPORT_DIR}"
