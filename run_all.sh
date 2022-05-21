#!/usr/bin/env bash

for aa in outliers hiddengroup skew ; do 
    sed -i 's/^attack=.*$/attack='$aa'/' autotemp.config; 
    for algo in mcmc advi; do 
        sed -i 's/^algo=.*$/algo='$algo'/' autotemp.config; 
        for ff in `cat prog_all_39_20220217_$aa`; do 
            # | xargs -P 8 -n 1 -I {} sh -c 'ff={}; if [ -z "${ff##*mix*}" ]; then ./autotemp_compile.sh  $ff rhat; else ./autotemp_compile.sh  $ff rhat; fi'
            if [[ $ff == *"mix"* ]]; then 
                ./autotemp_compile.sh $ff pam; 
            else
                ./autotemp_compile.sh $ff mse; 
            fi
        done
    done
done # |& tee temp
