#!/bin/bash

tar_directory="mnt/MMA/traces/";
output_prefix="stats_";

: > error.log

for archive_file in *.tar.gz
do
    # Clean-up
    rm -rf $tar_directory;

    echo "Extracting $archive_file...";
    tar -xzf $archive_file;

    cap_files=mnt/MMA/traces/*
	output_file="$output_prefix$(basename -s .tar.gz $archive_file).txt";
	
	: > $output_file;
	
    for cap_file in $cap_files; do
		echo "Processing $cap_file";
        ./capread.bash $cap_file --short >> $output_file 2>> error.log;
    done
done

# Clean-up
rm -rf $tar_directory;
