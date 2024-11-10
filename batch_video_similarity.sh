#!/bin/bash

# Usage: ./batch_video_similarity.sh <file_name>
# Example: ./batch_video_similarity.sh landscape_90_degree_PXL3
# * Splits 19m video into 60-second chunks and runs the Dart script on each chunk
# * Generates a CSV file where each row is a 60-second chunk of the video
# * In pairs, first row is the raw Video, next is Normalized

file_name=$1
experiment_dir="results/2_fov/2_vacuum"
target_mp4="$experiment_dir/raw_videos/19m/$file_name.mp4"
raw_video_dir="$experiment_dir/raw_videos"

# Use ffmpeg to split the video into 60-second chunks
ffmpeg -i "$target_mp4" -c copy -map 0 -f segment -segment_time 00:01:00 -reset_timestamps 1 "$raw_video_dir"/${file_name}_%03d.mp4

# Directory for raw video files and the CSV output file
output_csv="$experiment_dir/csv_videos/$file_name.csv"
match_pattern="${file_name}_*.mp4"

# Iterate over all the split video files
for video_file in "$raw_video_dir"/$match_pattern; do
  # Run the Dart script, appending results to the same CSV file
  dart run lib/cli/main.dart --output "$output_csv" --video "$video_file"
done
