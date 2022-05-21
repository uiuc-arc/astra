# ASTRA Robustness Transformation Evaluator

This evaluator automatically evaluates the robustness of the original model and the transformed ones on different attack levels.
The metric is the MSE of the posterior predicted data compared to the original data, by default averaged over five runs.

First compile the probabilistic programming system Stan by running
```
./build.sh
```

Run the following code to evaluate the model `[model_name]` with the `outliers` (adding random outliers) noise model:

```
./autotemp_compile.sh [model_name] mse
```
where `[model_name]` can be one model from the list `prog_[attack]`, and [attack] should be one of `outliers`, `hiddengroup`, or `skew`.
In the end, it will print the MSE for different versions of this model. You can also find the MSE stored in `autotemp/results/[model_name]/[model_name]_res_[attack]/all_noise_diff2*` for the original model and `autotemp/results/[model_name]_robust_*/[model_name]_robust_*_res_[attack]/all_noise_diff2*` for the transformed model.

You may configure the experiment with `autotemp.config`:

1. `attack` (the noise model): one of `outliers`, `hiddengroup` or `skew`
2. `noise_levels`: a list of noise levels to run, which are numbers separated by space and surrounded by quotes, e.g. "0 2 4 6 8 10" 
3. `add_noise_times`: average the evaluation results over how many runs (each run may have different random noise)
4. `algo`: one of `nuts` or `advi`

By default the runner runs each version of the model for five times for five noise levels 0 and 10 with ADVI.
