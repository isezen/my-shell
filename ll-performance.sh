#!/bin/bash
# sezenismail@gmail.com
# 2014-11-27
# Compares performance of ll and native ls -l commands

_path="/usr/bin"
_n=50
_ts_total_run_time=$(( $(date +%s%N)/1000000 ))


# Native ls performance
_total=0
for i in $(seq 1 $_n);do
  _tsmp=$(( $(date +%s%N)/1000000 ))
  vcl=$(ls -l "$_path")
  # ls -l "$_path"
  _val=$(( $(date +%s%N)/1000000 - $_tsmp ))
  _total=$(( $_total + $_val ))
done
_lsperf=$(bc <<< "scale = 3; ($_total/$_n)")

# ll performance
_total=0
for i in $(seq 1 $_n);do
  _tsmp=$(( $(date +%s%N)/1000000 ))
  vcl=$(ll -h "$_path")
  # ll "$_path"
  _val=$(( $(date +%s%N)/1000000 - $_tsmp ))
  _total=$(( $_total + $_val ))
done
_llperf=$(bc <<< "scale = 3; ($_total/$_n)")

# How much faster or slower?
_comp_ll_ls=$(bc <<< "scale = 3; ($_llperf/$_lsperf)")
_ts_total_run_time=$(( $(date +%s%N)/1000000 - $_ts_total_run_time ))

date
echo "Total Run Time: $_ts_total_run_time ms."
echo "pure ls Performance: $_lsperf ms."
echo "ll Performance: $_llperf ms."
echo "ll $_comp_ll_ls times slower than ls"
