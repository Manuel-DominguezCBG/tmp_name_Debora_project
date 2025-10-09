# 🧬 FullAnalysis Pipeline

## Overview
`main.sh` is a **Bash pipeline** for processing paired-end Illumina sequencing data.  
It performs **alignment**, **BAM generation**, **indexing**, and **read coverage quantification** against predefined genomic regions.  

This script is designed for execution on a **SLURM-based high-performance computing (HPC)** environment, using **Apptainer containers** to ensure reproducibility and consistent software environments.

This script was developed for the scientific paper **“XXX”** by **Debora Mackay** and **Manuel Dominguez**.


---

## ⚙️ Workflow Summary

1. **Job Scheduling (SLURM)**  
   The script uses `SBATCH` directives to request computing resources:
   - 1 compute node  
   - 20-hour time limit  
   - Log output written to `<jobname>.<jobid>.log`  

2. **Software Environment**  
   Tools are executed inside Apptainer containers from Biocontainers:
   - [`samtools`](https://bioconda.github.io/recipes/samtools/README.html) v1.20  
   - [`bedtools`](https://bioconda.github.io/recipes/bedtools/README.html) v2.24  
   - [`bwa`](https://bioconda.github.io/recipes/bwa/README.html) v0.7.18  

   These tools handle read alignment, BAM file processing, and region-based read counting.

3. **Input and Output Structure**
   - **Input:** A directory containing paired FASTQ files (`*_R1_001.fastq.gz` and `*_R2_001.fastq.gz`).  
   - **Outputs:**
     - Aligned and sorted BAM files stored in `BAM/`
     - Read count reports stored in `Reports/`

4. **Alignment and BAM Creation**
   - Each sample (identified by the prefix before the first underscore in the filename) is aligned using **BWA-MEM** against the specified **hg38 reference genome**.  
   - The resulting SAM output is piped directly to `samtools sort` to produce a compressed, sorted BAM file.  
   - Each BAM file is then indexed with `samtools index`.

5. **Read Counting with Bedtools**
   - For each BAM file, **Bedtools multicov** calculates the number of reads overlapping each region in the provided BED file.  
   - The results are saved as `<Sample>_aligned.report` in the `Reports/` directory.  
   - The `-f 0.85` and `-r` parameters ensure that only reads covering ≥85% of a region and aligned in the correct orientation are counted.

---

## 📥 Example Usage
```bash
sbatch main.sh fastq_directory

