data{
int<lower=0> N;
vector[N] x;
vector[N] y;
}
parameters{
vector[2] beta;
real<lower=0> sigma;
real<lower=0, upper=0.5> robust_prob_outlier;
real<lower=log((sigma)^2)> robust_outlier_log_var;
real robust_outlier_log_var_mu;
real<lower=0> robust_outlier_log_var_std;
}
model{
for(observe_i in 1 : N)
{
robust_outlier_log_var~normal(robust_outlier_log_var_mu,robust_outlier_log_var_std);
target+=log_mix(robust_prob_outlier,normal_lpdf(y[observe_i]|beta[1]+(beta[2])*(x[observe_i]),sqrt(exp(robust_outlier_log_var))),normal_lpdf(y[observe_i]|beta[1]+(beta[2])*(x[observe_i]),sigma));
}
}

