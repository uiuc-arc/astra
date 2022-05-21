#!/usr/bin/env bash

for aa in outliers hiddengroup skew ; do 
    sed -i 's/^attack=.*$/attack='$aa'/' autotemp.config; 
    for algo in advi mcmc; do 
        sed -i 's/^algo=.*$/algo='$algo'/' autotemp.config; 
        # cat prog_$aa | xargs -P 8 -n 1 -I {} sh -c 'ff={}; ./autotemp_compile.sh $ff mse'
        for ff in `cat prog_$aa`; do 
            ./autotemp_compile.sh $ff mse; 
        done
    done
done # |& tee temp
sed -i 's/^attack=.*$/attack=outliers/' autotemp.config; 
sed -i 's/^algo=.*$/algo=advi/' autotemp.config; 
