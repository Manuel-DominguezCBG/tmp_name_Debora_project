#!/usr/bin/env python3
"""
Script: merge_amplicon_reports.py
Author: Manuel Dominguez
Version: 1.0
Date: 2025-05-12

Description:
    This script merges multiple `.report` files (produced per-sample or per-run)
    into a single CSV table. It reads all `.report` files from a given directory,
    extracts read count information, and combines them by genomic coordinates.

    Each file contributes one column of read counts, labeled by the filename.
    The resulting table allows easy comparison of coverage across multiple runs.

Usage:
    python merge_report.py <directory>

    If no directory is provided, the current directory is used.

Input file format:
    Tab-separated with the following columns:
        chr, start, end, amplicon_name, read_count

Output:
    A single merged CSV file named after the run ID (or a generic name)
    containing all read counts across input report files.

Requirements:
    - Python 3.8+
    - pandas

This script is part of the reproducible workflow described in the manuscript.
"""

import pandas as pd
import os
import re
import sys

# Check if a directory was passed as a command line argument
if len(sys.argv) > 1:
    directory = sys.argv[1]
else:
    print("No directory specified. Using the current directory as default.")
    directory = '.'

# Prepare an empty DataFrame to hold all data
merged_df = None

# Columns of interest
columns_of_interest = ['chr', 'start', 'end', 'amplicon_name', 'read_count']

# List to store file info
file_data = []

# Loop through all .report files in the directory
for filename in os.listdir(directory):
    if filename.endswith('.report'):
        # Read the file
        filepath = os.path.join(directory, filename)
        df = pd.read_csv(filepath, sep='\t', header=None, usecols=[0, 1, 2, 3, 4],
                         names=columns_of_interest)
        
        # Extract the sequence number from the filename
        match = re.search(r'_(\d+)-', filename)
        if match:
            sequence_number = int(match.group(1))
        else:
            sequence_number = 999  # Assign a high number to files missing sequence info
        
        # Store in list with sequence number for sorting later
        file_data.append((sequence_number, filename[:-7], df))

# Sort files by sequence number
file_data.sort()

# Pivot each dataframe and combine
for seq, file_name, df in file_data:
    pivot_df = df.pivot_table(index=['chr', 'start', 'end', 'amplicon_name'],
                              columns=lambda x: file_name, values='read_count', aggfunc='first')
    if merged_df is None:
        merged_df = pivot_df
    else:
        merged_df = merged_df.join(pivot_df, how='outer')

# Reset index to turn multi-index into columns
merged_df.reset_index(inplace=True)

# Fill NaN with zeros if any column are not present in some files
merged_df.fillna(0, inplace=True)

# Save the merged DataFrame to CSV
merged_df.to_csv('251208_MN01972_0290_A000HC72H5.csv', index=False)

