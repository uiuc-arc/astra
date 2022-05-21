data{
int<lower=0> N;
vector[N] y;
vector<lower=0, upper=1>[N] x;
}
parameters{
real a;
real b;
real<lower=0> sigma_y;
real<lower=0, upper=0.5> robust_prob_outlier;
real<lower=log((sigma_y)^2)> robust_outlier_log_var;
real robust_outlier_log_var_mu;
real<lower=0> robust_outlier_log_var_std;
}
model{
for(observe_i in 1 : N)
{
robust_outlier_log_var~normal(robust_outlier_log_var_mu,robust_outlier_log_var_std);
target+=log_mix(robust_prob_outlier,normal_lpdf(y[observe_i]|a+b*(x[observe_i]),sqrt(exp(robust_outlier_log_var))),normal_lpdf(y[observe_i]|a+b*(x[observe_i]),sigma_y));
}
}

