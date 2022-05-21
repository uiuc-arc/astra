#!/usr/bin/env bash

script_dir=$(realpath $(dirname ${BASH_SOURCE[0]}))
model_path=$(realpath $1)

model_name=${model_path##*/}
source $script_dir/autotemp.config

suffix="_$2"
if [ "$algo" = "advi" ]; then
    echo noise_level,$(cat $model_path/${model_name}_res${suffix}/noise_diff_0_vb | head -1 ) > $model_path/${model_name}_res${suffix}/all_noise_diff2_vb_$3
    for i in $noise_levels; do
        #for i in 0 1 2 3 4 5 6 7 8 9 10; do
        echo plot_avg ${model_name}_res${suffix}/noise_diff_${i}_vb
        echo $i,$($script_dir/plot_avg.py $model_path/${model_name}_res${suffix}/noise_diff_${i}_vb | sed -n 2p) >> $model_path/${model_name}_res${suffix}/all_noise_diff2_vb_$3
    done
else
    echo noise_level,$(cat $model_path/${model_name}_res${suffix}/noise_diff_0 | head -1 ) > $model_path/${model_name}_res${suffix}/all_noise_diff2_$3
    #TODO
    for i in $noise_levels; do
        #for i in 0 1 2 3 4 5 6 7 8 9 10; do
        echo plot_avg ${model_name}_res${suffix}/noise_diff_$i
        echo $i,$($script_dir/plot_avg.py $model_path/${model_name}_res${suffix}/noise_diff_$i | sed -n 2p) >> $model_path/${model_name}_res${suffix}/all_noise_diff2_$3
    done
fi
# $script_dir/plot_noise_diff_6.py $model_path

