data{
int<lower=0> N;
int<lower=0> n_treatment;
int<lower=0> n_airport;
int<lower=0, upper=n_treatment> treatment[N];
int<lower=0, upper=n_airport> airport[N];
vector[N] y;
}
parameters{
real<lower=0> sigma;
real<lower=0> sigma_gamma;
real<lower=0> sigma_delta;
vector[n_treatment] gamma;
vector[n_airport] delta;
real mu;
real<lower=0, upper=0.5> robust_prob_outlier;
real<lower=log((sigma)^2)> robust_outlier_log_var;
real robust_outlier_log_var_mu;
real<lower=0> robust_outlier_log_var_std;
}
model{
vector[N] y_hat;
sigma~uniform(0,100);
sigma_gamma~uniform(0,100);
sigma_delta~uniform(0,100);
mu~normal(0,100);
gamma~normal(0,sigma_gamma);
delta~normal(0,sigma_delta);
for(i in 1 : N)
{
y_hat[i]=mu+gamma[treatment[i]]+delta[airport[i]];
}
for(observe_i in 1 : N)
{
robust_outlier_log_var~normal(robust_outlier_log_var_mu,robust_outlier_log_var_std);
target+=log_mix(robust_prob_outlier,normal_lpdf(y[observe_i]|y_hat[observe_i],sqrt(exp(robust_outlier_log_var))),normal_lpdf(y[observe_i]|y_hat[observe_i],sigma));
}
}

