#!/usr/bin/env bash


# Usage: ./thisfile prog_name

# Run all the transformed model generated by transformer and the original model
#     with ADVI and evaluates with MSE. 
#     Requires input_org_dir input_trans_dir output_dir in the transformer config.
#     Outputs samples in the directory output_dir/model_name/model_name_res/
#     and MSE values in output_dir/model_name/model_name_res/*all*

# Dependencies: autotemp.config attack_run_metric_res_compile.sh
#               attack_run_compile.sh metric_res_compile.sh
#               plot_noise_diff_6_suf_compile.sh ddd_attack.R ddd_test_nosplit.R 
#               run_stan_config.sh run_stan.config
#               metrics_0301.py cmdstan 
#
# This script calls attack_run_metric_res_compile.sh to run the models and calculate metrics

org_prog=$1
#attack=outliers #hiddengroup #skew
metric_m=$2 # mse mad wass pl1 pr2 pam
script_dir=$(realpath $(dirname ${BASH_SOURCE[0]}))
source $script_dir/autotemp.config

datacorr=$(grep  -oh -m 1 '[a-zA-Z_\d\s:]*_corrupted' ${input_trans_dir}/${org_prog}/*.npl)
datagood=${datacorr%%_corrupted}
if [ ! -d ${output_dir}/$org_prog ]; then mkdir ${output_dir}/$org_prog; fi
cp ${input_org_dir}/${org_prog}/${org_prog}.stan ${output_dir}/$org_prog/
cp ${input_org_dir}/${org_prog}/${org_prog}.data.R ${output_dir}/$org_prog/

for dd in `ls -d ${input_trans_dir}/${org_prog}_robust_*/ ${input_trans_dir}/${org_prog}/`; do 
    pp=$(echo $dd | rev | cut -d'/' -f 2 | rev); 
    echo "Evaluating $pp..."; 
    if [ ! -d ${output_dir}/$pp ]; then mkdir ${output_dir}/$pp; fi
    cp $dd/*.stan ${output_dir}/$pp; 
    cp ${input_trans_dir}/$org_prog/$org_prog.data.R ${output_dir}/$pp/${pp}.data.R;
    if [ -e ${input_trans_dir}/$org_prog/given_attack.R ]; then
        cp ${input_trans_dir}/$org_prog/given_attack.R ${output_dir}/$pp/given_attack.R;
    fi
done

if ! grep -q "$org_prog" ./mix_models ; then
    echo "./ddd_test_nosplit.R ${input_org_dir}/${org_prog}/${org_prog}.data.R $datagood"
    ./ddd_test_nosplit.R ${input_org_dir}/${org_prog}/${org_prog}.data.R $datagood
    # truth_file contains y_test and will be rewritten by ddd_test_nosplit. truth_file_w doesn't change 
    tail -n +2 ${input_org_dir}/${org_prog}/truth_file_w >> ${input_org_dir}/${org_prog}/truth_file
else
    datagood=y
    echo "..."
fi

# truth_file contains y_test and will be rewritten by ddd_test_nosplit. truth_file_w doesn't change 
# if [ "$metric_m" == pam ] ; then
    # tail -n +2 ${input_org_dir}/${org_prog}/truth_file_w >> ${input_org_dir}/${org_prog}/truth_file
# fi

for ff in `ls ${output_dir}/${org_prog}_robust_*/ ${output_dir}/${org_prog}/ -d`; do 
    # if [ -d ../templates/genquant/${org_prog}/${org_prog}_res ]; then
    #     if ! grep -q "generated quantities" $ff/*.stan; then
    #         cat ../templates/genquant/$org_prog/$org_prog.genquant >> $ff/*.stan;
    #     fi
    # else
        if ! grep -q "generated quantities" $ff/*.stan; then
            if  ! grep -q "$org_prog" ./mix_models  ; then
                if [  "$metric_m" != pam ]; then
                    # if [  "$metric_m" != lik ]; then
                        cat ${input_trans_dir}/$org_prog/$org_prog.genquant >> $ff/*.stan;
                    # else
                    #     cat ${input_trans_dir}/$org_prog/$org_prog.pred >> $ff/*.stan;
                    # fi
                fi
            fi
        fi
    # fi
    # cp ${input_org_dir}/${org_prog}/test.data.R $ff/test.data.R; 
    cp ${input_org_dir}/${org_prog}/train.data.R $ff/train.data.R ;
    cp ${input_org_dir}/${org_prog}/truth_file $ff/truth_file ;
done

if [ "$algo" = "advi" ]; then
    #for attack in skew; do
    ls {${output_dir}/${org_prog}_robust_*/,${output_dir}/${org_prog}/} -d | xargs -P 1 -n 1 -I {} sh -c "echo Evaluating {}...;./attack_run_metric_res_compile.sh {} ${attack} ${metric_m} ${datagood}"
    #done
    echo "original result:"
    cat ${output_dir}/${org_prog}/*${attack}*/*all*vb_$metric_m

    for ff in `ls ${output_dir}/${org_prog}_robust_*/*${attack}*/*all*vb_$metric_m `; do
        parsss=${ff#*_robust_}
        echo "robust ${parsss%%/*} result:"
        cat $ff
    done
else
    #for attack in skew; do grep -v "robust_mix\|robust_student" grep -v "robust_mix"
    ls {${output_dir}/${org_prog}_robust_*/,${output_dir}/${org_prog}/} -d | grep -v "robust_mix" |  xargs -P 1 -n 1 -I {} sh -c "echo {};./attack_run_metric_res_compile.sh {} ${attack} ${metric_m} ${datagood}"
    #done
    echo "original result:"
    cat ${output_dir}/${org_prog}/*${attack}*/*all*diff2_$metric_m

    for ff in `ls ${output_dir}/${org_prog}_robust_*/*${attack}*/*all*diff2_$metric_m | grep -v "robust_local\|robust_mix" `; do
        parsss=${ff#*_robust_}
        parsss=${parsss#*p}
        echo "robust ${parsss%%/*} result:"
        cat $ff
    done
fi
