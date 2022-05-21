#!/usr/bin/env bash

#config
run_script=$(realpath ./run_stan_config.sh)
gooddata=$4
script_dir=$(realpath $(dirname ${BASH_SOURCE[0]}))
source $script_dir/run_stan.config
source $script_dir/autotemp.config
metrics_file=$metrics_file_path
#add_noise_times=5

# if [[ $input_file_path == *"genquant"* ]]; then
    genquant=true
    #TODO
#    add_noise_times=5
# fi

if [ "$variational" = true ]; then
    vbext="_vb"
    outputext="vb"
else
    vbext=""
    outputext="$min"
fi
gen_data=$(realpath ./ddd_attack.R)
# TODO: change back
# if [ -e ${input_file_path}/given_attack.R ]; then
#     gen_data=$(realpath ${input_file_path}/given_attack.R)
# fi
curr_model_name=${input_file_path##*/}

attack=$3
dest_model_name_ext_suffix=_$attack
dest_model_name_ext=_res$dest_model_name_ext_suffix

echo "================================"
echo "Compile: $1 vb=$2 attack=$attack" data=$gooddata
echo "================================"


#TODO
for i in $noise_levels; do
#for i in 0 1 2 3 4 5 6 7 8 9 10; do
    for j in $(eval echo "{1..$add_noise_times}"); do
        echo "$gen_data ${input_file_path}/${curr_model_name}.data.R $i $attack $gooddata"
        $gen_data ${input_file_path}/train.data.R $i $attack $gooddata
        mv ${input_file_path}/noisy.data.R ${input_file_path}/noisy_${i}_$j.data.R
        $run_script $input_file_path "$variational" noisy_${i}_$j.data.R $dest_model_name_ext_suffix
        mv $input_file_path/noisy_${i}_$j.data.R ${dest_path}/${curr_model_name}$dest_model_name_ext/
        cp ${dest_path}/${curr_model_name}$dest_model_name_ext/rw_summary_${outputext}_n ${dest_path}/${curr_model_name}$dest_model_name_ext/rw_summary_${outputext}_n_${i}_$j
        for ffi in 1 2 3 4; do
            mv ${dest_path}/${curr_model_name}$dest_model_name_ext/output_${outputext}_$ffi$sampleext ${dest_path}/${curr_model_name}$dest_model_name_ext/output_${outputext}_${ffi}_${i}_$j$sampleext
            mv ${dest_path}/${curr_model_name}$dest_model_name_ext/stanout_${outputext}_$ffi ${dest_path}/${curr_model_name}$dest_model_name_ext/stanout_${outputext}_${ffi}_${i}_$j
        done
    done
done

if [ "$genquant" = true ]; then
    cp $input_file_path/truth_file ${dest_path}/${curr_model_name}$dest_model_name_ext/
fi

echo "============================="
echo "Done Compile: $1 vb=$2 attack=$attack"
echo "============================="
