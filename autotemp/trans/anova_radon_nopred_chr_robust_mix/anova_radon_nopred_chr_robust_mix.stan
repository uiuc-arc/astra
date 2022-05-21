data{
int<lower=0> J;
int<lower=0> N;
int<lower=1, upper=J> county[N];
vector[N] y;
}
parameters{
vector[J] eta;
real mu_a;
real<lower=0, upper=100> sigma_a;
real<lower=0, upper=100> sigma_y;
real<lower=0, upper=0.5> robust_prob_outlier;
real<lower=log((sigma_y)^2)> robust_outlier_log_var;
real robust_outlier_log_var_mu;
real<lower=0> robust_outlier_log_var_std;
}
transformed parameters{
vector[J] a;
vector[N] y_hat;
a=mu_a+sigma_a*eta;
for(i in 1 : N)
{
y_hat[i]=a[county[i]];
}
}
model{
mu_a~normal(0,1);
eta~normal(0,1);
for(observe_i in 1 : N)
{
robust_outlier_log_var~normal(robust_outlier_log_var_mu,robust_outlier_log_var_std);
target+=log_mix(robust_prob_outlier,normal_lpdf(y[observe_i]|y_hat[observe_i],sqrt(exp(robust_outlier_log_var))),normal_lpdf(y[observe_i]|y_hat[observe_i],sigma_y));
}
}

