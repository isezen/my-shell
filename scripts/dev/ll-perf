#!/bin/bash
# sezenismail@gmail.com
# 2014-11-27
# Compares performance of ll and native ls -l commands

_n=50 # number of runs
_path="/usr/bin" # path to run

_ts_total_run_time=$(( $(date +%s%N)/1000000 ))

# Native ls performance
_total=0
_numoffiles=$(find "$_path" -mindepth 1 -maxdepth 1 | wc -l)
for _ in $(seq 1 $_n);do
  _tsmp=$(( $(date +%s%N)/1000000 ))
  ls -l "$_path" > /dev/null
  # ls -l "$_path"
  _val=$(( $(date +%s%N)/1000000 - _tsmp ))
  _total=$(( _total + _val ))
done
_lsruntime=$(bc <<< "scale = 3; ($_total/$_n)")
_ls_perf_per_file=$(bc <<< "scale = 3; ($_lsruntime/$_numoffiles)")

# ll performance
_total=0
for _ in $(seq 1 $_n);do
  _tsmp=$(( $(date +%s%N)/1000000 ))
  ll -h "$_path" > /dev/null
  # ll "$_path"
  _val=$(( $(date +%s%N)/1000000 - _tsmp ))
  _total=$(( _total + _val ))
done
_llruntime=$(bc <<< "scale = 3; ($_total/$_n)")
_ll_perf_per_file=$(bc <<< "scale = 3; ($_llruntime/$_numoffiles)")

# How much faster or slower?
_comp_ll_ls=$(bc <<< "scale = 3; ($_llruntime/$_lsruntime)")
_ts_total_run_time=$(( $(date +%s%N)/1000000 - _ts_total_run_time ))


date
echo "Total Run Time: $_ts_total_run_time ms."
echo "Number of files: $_numoffiles"
echo "Pure ls run time: $_lsruntime ms. Perf: $_ls_perf_per_file"
echo "ll run time: $_llruntime ms. Perf: $_ll_perf_per_file"
echo "ll $_comp_ll_ls times slower than ls"
