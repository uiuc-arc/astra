# ASTRA Robustness Transformation Evaluator

This evaluator automatically evaluates the robustness of the original model and the transformed ones on different attack levels.
The metric is the MSE of the posterior predicted data compared to the original data, by default averaged over five runs.

### Prerequisites
ASTRA requires Bash 4, Python >= 3.5, R >= 3.4

## Installation
Run
```
./build.sh
```

## Getting Started
Run the following command to evaluate different robust transformation of the model `[model_name]` with the `outliers` (adding random outliers) noise model.
```
./autotemp_compile.sh [model_name] mse
```
where `[model_name]` can be one model from the list `prog_[attack]`, and [attack] should be one of `outliers`, `hiddengroup`, or `skew`.
By default it runs each version of the model for `5` times for noise levels `"0 2 4 6 8 10"` with the `advi` algorithm.

In the end, it will print the MSE scores for different versions of this model. You can also find the MSE scores in `autotemp/results/[model_name]/[model_name]_res_[attack]/all_noise_diff2*` for the original model and `autotemp/results/[model_name]_robust_*/[model_name]_robust_*_res_[attack]/all_noise_diff2*` for the transformed model. The `all_noise_diff2_vb_mse` files store the results by running the `advi` algorithm, and `all_noise_diff2_mse` files store the results by running `nuts` algorithm.

For example, you may run 
```
./autotemp_compile.sh lightspeed mse
```
After compilation and running the programs, it will the give evaluation result in the end:
```
original result:
noise_level,time,mse
0,3.0040590000000003,0.6144487377146198
2,3.111238,0.6460318057968435
4,2.627504,0.7046183168869544
6,2.883012,0.7470031165324894
8,2.619271,0.8119748727719166
10,2.811243,1.0054041271259946
robust mix result:
noise_level,time,mse
0,18.784016,0.6638829305087263
2,19.979297000000003,0.7761817592472213
4,19.442367,0.7020628434417294
6,16.719281,0.7193424350784786
8,16.480019,0.7825248408440266
10,16.323905999999997,1.1622628765968435
robust local1 result:
noise_level,time,mse
0,6.459852000000001,0.649276935343125
2,5.124909,0.7288995515227685
4,5.737296,0.7601176466217078
6,6.1307920000000005,0.770880415765761
8,4.560924,0.8635642671532244
10,5.1679129999999995,0.9137157684186414
robust local2 result:
noise_level,time,mse
0,11.796506,0.6876077158078502
2,12.569356,3.0121827715998943e+249
4,9.329423,0.7481497979018186
6,11.428509,3.1795790328264438e+190
8,7.952933999999999,0.7941885452255577
10,7.354391000000001,0.7740031687138245
robust reparam result:
noise_level,time,mse
0,7.071441,0.6181519941879694
2,5.767017,0.6246884082295008
4,6.783151,0.6315731279561508
6,10.634566999999999,0.6338300006236721
8,6.327468,0.6426098219073574
10,6.53831,0.6356129217766064
robust reweight result:
noise_level,time,mse
0,5.437124,0.6704892652829991
2,6.508681000000001,0.6785330381676304
4,5.303089000000001,0.6868735423604199
6,6.101233000000001,0.6972531313387073
8,6.482711,0.7135198267746189
10,4.420973999999999,0.714266486227577
robust student result:
noise_level,time,mse
0,3.6128860000000005,0.6132856477183279
2,3.389842,0.6191688841664249
4,3.772745,0.6171339964188021
6,3.861361,0.6179499619656521
8,3.570148,0.6240424906718882
10,3.2314399999999996,0.6229147456370493
```

You may configure the experiment with `autotemp.config`:

1. `attack`: the noise model, one of `outliers`, `hiddengroup` or `skew`
2. `noise_levels`: a list of noise levels to run, which are numbers separated by space and surrounded by quotes, e.g. `"0 2 4 6 8 10"` 
3. `add_noise_times`: average the evaluation results over how many runs (each run may have different random noise), e.g. `5`
4. `algo`: the inference algorithm, one of `nuts` or `advi`


#### To reproduce the results in the paper, run 
```
```
