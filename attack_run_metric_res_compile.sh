#!/usr/bin/env bash

# Called from autotemp_complie.sh

prog=$(realpath $1)
attack=$2
metric_m=$3
yyy=$4
program_name=$(echo $prog | rev | cut -d'/' -f 1 | rev)
script_dir=$(realpath $(dirname ${BASH_SOURCE[0]}))
source $script_dir/autotemp.config

cp $prog/truth_file $prog/${program_name}_res_$attack/

if [ "$algo" = "advi" ]; then
    ./attack_run_compile.sh $prog true $attack $yyy
    ./metric_res_compile.sh $prog/${program_name}_res_$attack/ true $metric_m
else
    ./attack_run_compile.sh $prog false $attack $yyy
    ./metric_res_compile.sh $prog/${program_name}_res_$attack/ false $metric_m
fi
./plot_noise_diff_6_suf_compile.sh $prog $attack $metric_m
