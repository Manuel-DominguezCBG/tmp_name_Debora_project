#!/usr/bin/env bash
# =====================================================================
# Script: bcf2fastq.sh
# Description: Convert Illumina BCL files to FASTQ format using bcl-convert
#              inside an Apptainer (Singularity) container.
# Author: Manuel Dominguez
# Version: 1.0
# Date: 2025-05-12
#
# Requirements:
#   - Apptainer or Singularity installed
#   - Access to /mnt/scratch1/ and /mnt/data1/ directories
#   - The quay.io/nf-core/bclconvert:4.3.6 container image
#
# Reference:
#   This script is part of the analysis workflow described in the manuscript.
# =====================================================================

set -euo pipefail  # safer bash settings: exit on error, undefined var, or failed pipe

# ---------------------------- CONFIGURATION ---------------------------- #
# Input and output directories
BCL_INPUT_DIR="/mnt/scratch1/projects/Manuel_tmp/250512_MN01972_0181_A000H7NYKGRPT"
OUTPUT_DIR="${BCL_INPUT_DIR}/fastq"

# Container image
CONTAINER_IMAGE="docker://quay.io/nf-core/bclconvert:4.3.6"

# ----------------------------------------------------------------------- #
# Create output directory if it doesn’t exist
mkdir -p "${OUTPUT_DIR}"

# Run bcl-convert within Apptainer
echo "Running bcl-convert on ${BCL_INPUT_DIR}..."
apptainer exec \
    --containall \
    --bind /mnt/scratch1/:/mnt/scratch1/ \
    --bind /mnt/data1/:/mnt/data1/ \
    "${CONTAINER_IMAGE}" \
    bcl-convert \
        --bcl-input-directory "${BCL_INPUT_DIR}" \
        --output-directory "${OUTPUT_DIR}" \
        --bcl-num-parallel-tiles 1 \
        --strict-mode true \
        --force

echo "BCL conversion completed successfully."
echo "FASTQ files are available at: ${OUTPUT_DIR}"
