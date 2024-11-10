#!/bin/bash

# Usage: ./train_compare_video.sh
# * Compares a directory of CSV files from two different scenes
# * Generates a training / testing set for the ML model
# * Each row contains label, and similarity scores for each comparison

OUT_DIR="results/2_fov/3_compare_1_2/flex_train_similarity_scores"
SCENE_ONE="1_office"
SCENE_TWO="2_vacuum"

scene_one_pwd="results/2_fov/$SCENE_ONE/csv_videos"
scene_two_pwd="results/2_fov/$SCENE_TWO/csv_videos"
match_pattern="*.csv"

# Iterate over all csv files in SCENE_ONE
for scene_one_csv in "$scene_one_pwd"/$match_pattern; do
  # Iterate over all csv files in SCENE_TWO
  for scene_two_csv in "$scene_two_pwd"/$match_pattern; do
    if [ "$scene_one_csv" == "$scene_two_csv" ]; then
      dart run lib/cli/main.dart --normalized --csv "$scene_one_csv" --output "$OUT_DIR/pairwise_$(basename $scene_one_csv)"
    else
      if [ "$SCENE_ONE" == "$SCENE_TWO" ]; then
        dart run lib/cli/main.dart --visual-similarity --normalized --csv "$scene_one_csv" --versus "$scene_two_csv" --output "$OUT_DIR/$(basename $scene_one_csv)_vs_$(basename $scene_two_csv)"
      else
        dart run lib/cli/main.dart --normalized --csv "$scene_one_csv" --versus "$scene_two_csv" --output "$OUT_DIR/$(basename $scene_one_csv)_vs_$(basename $scene_two_csv)"
      fi
    fi
  done
done
