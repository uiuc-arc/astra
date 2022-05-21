# AURA Transformer & Runner

## Transformer
The transformer automatically applies five robust transformations on a Stan model.

Run the following command to transform models in `autotemp/org/[model_name]`, which contains `[model_name].stan` and `[model_name].data.R`.

```
java -jar ./aura_transformer-1.0.jar
```

Find the robust versions in `autotemp/trans/[model_name]_robust_*`.

You can modify the file `autotemp.config` to transform the models in other directories. 
The transformer transforms the models in `input_org_dir` and stores the transformed models in `input_trans_dir`.
Make sure to organize the models in the same way as in `autotemp/org/*`. The `.stan` and `.data.R` files should
have the same name (`[model_name]`) as the directory containing them.


## Runner
The runner automatically evaluates the robustness of the original model and the transformed ones on different attack levels.
The metric is the MSE compared to the original data, by default averaged for five runs.

Change the field `stan_name` in `run_stan.config` to `stan_name=the_path_to_your_cmdstan_folder`.

Run the following code to evaluate the model `autotemp/trans/[model_name]` with the `outliers` (adding outliers) attack:

```
./autotemp_compile.sh [model_name]
```
It will print the MSE for different versions of this model in the end. You can also find the MSE stored in `autotemp/results/[model_name]/[model_name]_res_[attack]/all_noise_diff2*` for the original model and `autotemp/results/[model_name]_robust_*/[model_name]_robust_*_res_[attack]/all_noise_diff2*` for the transformed model.

You can modify the file `autotemp.config` to run the models in other directories not necessarily in `autotemp/trans/`. The runner runs the model under `input_trans_dir` (by default produced by the transformer), and stores results in `output_dir`. All the `[model_name]` used in AURA benchmarks are listed in `prog_all_39.`


You can also change attack=hiddengroup or skew in autotemp_compile.sh.
By default the runner runs each version of the model for five times for two noise level 0 and 10 with ADVI, for quickly checking if a model/attack works or not.
