#!/usr/bin/env bash

res_path=$1
sampleext="" # ".gz"
metrics_file=./metrics_0301.py
#add_noise_times=5
script_dir=$(realpath $(dirname ${BASH_SOURCE[0]}))
source $script_dir/autotemp.config

#if [[ $res_path == *"genquant"* ]]; then
    genquant=true
    #TODO
#    add_noise_times=5
#fi

variational=$2
if [ "$variational" = true ]; then
    vbext="_vb"
    outputext="vb"
else
    vbext=""
    minext=$(grep "^min=" ./run_stan.config)
    outputext=${minext##*=}
fi

metric_m=$3


echo "===================================="
echo "Compile(metric): $1 vb=$2 metric=$metric_m"
echo "===================================="

#TODO
for i in $noise_levels; do
#for i in 0 1 2 3 4 5 6 7 8 9 10; do
    if [ "$genquant" = "true" ]; then
        mmm=""
        for mm in $metric_m; do
            mmm+=",$mm"
        done
        echo "time$mmm" > $res_path/noise_diff_${i}${vbext}
    else
        echo "time,param_wass_avg" > $res_path/noise_diff_${i}${vbext}
    fi
    for j in $(eval echo "{1..$add_noise_times}"); do
        if [ "$genquant" = "true" ]; then
            if [ "$metric_m" != wass ]; then
                mmm=""
                for mm in $metric_m; do
                    # temp fix for mixture mse=pam
                    res_path_no_slash="$(echo ${res_path} | sed 's:/*$::')"
                    res_path_file_name=${res_path_no_slash##*/}
                    res_path_trans_name=${res_path_file_name%%_res*}
                    res_path_model_name=${res_path_trans_name%%_robust*}
                    if [[ $res_path_model_name == *"mix"* ]]; then mm="pam"; fi
                    mmm+="-m $mm "
                done
                if [ ! -f $res_path/rw_summary_${outputext}_n_${i}_${j} ];then  continue; fi
                echo "-c -fs $res_path/rw_summary_${outputext}_n_${i}_${j} -ft $res_path/truth_file -rb $mmm"
                wass=$($metrics_file -c -fs $res_path/rw_summary_${outputext}_n_${i}_${j} -ft $res_path/truth_file -rb $mmm)
            else
                echo "$metrics_file -fr $res_path/output_${outputext}_1_0_1$sampleext -fr $res_path/output_${outputext}_2_0_1$sampleext -fr $res_path/output_${outputext}_3_0_1$sampleext -fr $res_path/output_${outputext}_4_0_1$sampleext -fm $res_path/output_${outputext}_1_${i}_$j$sampleext -fm $res_path/output_${outputext}_2_${i}_$j$sampleext -fm $res_path/output_${outputext}_3_${i}_$j$sampleext -fm $res_path/output_${outputext}_4_${i}_$j$sampleext -m wass -w 1000 -o avg"
                # echo "-fs $res_path/rw_summary_${outputext}_n_${i}_${j} -ft $res_path/truth_file -rb -m wass"
                # wass=$($metrics_file -c -fs $res_path/rw_summary_${outputext}_n_${i}_${j} -ft $res_path/truth_file -rb)
                #echo "-fs -fr $res_path/output_${outputext}_1_0_1$sampleext  -fm $res_path/output_${outputext}_1_${i}_$j$sampleext -m wass -o avg -w 1000"
                wass=$($metrics_file -fr $res_path/output_${outputext}_1_0_1$sampleext -fr $res_path/output_${outputext}_2_0_1$sampleext -fr $res_path/output_${outputext}_3_0_1$sampleext -fr $res_path/output_${outputext}_4_0_1$sampleext -fm $res_path/output_${outputext}_1_${i}_$j$sampleext -fm $res_path/output_${outputext}_2_${i}_$j$sampleext -fm $res_path/output_${outputext}_3_${i}_$j$sampleext -fm $res_path/output_${outputext}_4_${i}_$j$sampleext -m wass -w 1000 -o avg | sed 's/\(True\|False\),//g')
            fi
        else
            echo "$metrics_file -fr $res_path/output_${outputext}_1_0_1$sampleext -fr $res_path/output_${outputext}_2_0_1$sampleext -fr $res_path/output_${outputext}_3_0_1$sampleext -fr $res_path/output_${outputext}_4_0_1$sampleext -fm $res_path/output_${outputext}_1_${i}_$j$sampleext -fm $res_path/output_${outputext}_2_${i}_$j$sampleext -fm $res_path/output_${outputext}_3_${i}_$j$sampleext -fm $res_path/output_${outputext}_4_${i}_$j$sampleext -m wass -w 1000 -o avg"
            wass=$($metrics_file -fr $res_path/output_${outputext}_1_0_1$sampleext -fr $res_path/output_${outputext}_2_0_1$sampleext -fr $res_path/output_${outputext}_3_0_1$sampleext -fr $res_path/output_${outputext}_4_0_1$sampleext -fm $res_path/output_${outputext}_1_${i}_$j$sampleext -fm $res_path/output_${outputext}_2_${i}_$j$sampleext -fm $res_path/output_${outputext}_3_${i}_$j$sampleext -fm $res_path/output_${outputext}_4_${i}_$j$sampleext -m wass -w 1000 -o avg)
        fi
        if [ "$variational" = true ]; then
            endtime=$(grep -h "COMPLETED" $res_path/stanout_${outputext}_*_${i}_${j} | head -1 | cut -d] -f1 | sed 's/[^0-9|\.]//g')
            begintime=$(grep "Gradient evaluation took" $res_path/stanout_${outputext}_1_${i}_${j}  | cut -d] -f1 | sed 's/[^0-9|\.]//g')
            if [ ! -z "$endtime" ] && [ ! -z "$begintime" ]; then
                rtime=$(bc<<< $endtime-$begintime) 
            else
                rtime=""
            fi
        else
            rtime=$(grep "(Total)" $res_path/stanout_${outputext}_1_${i}_${j} | cut -d] -f2 | sed 's/[^0-9|\.]//g')
        fi
        echo $wass
        echo $rtime,$wass >> $res_path/noise_diff_${i}${vbext}
    done
done
echo "===================================="
echo "Done Compile(metric): $1 vb=$2 metric=$metric_m"
echo "===================================="
