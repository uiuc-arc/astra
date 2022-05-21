data{
int<lower=0> T;
real y[T];
real x[T];
}
parameters{
real alpha;
real beta;
real<lower=0, upper=1> lambda;
real<lower=0> sigma;
real<lower=0, upper=0.5> robust_prob_outlier;
real<lower=log((sigma)^2)> robust_outlier_log_var;
real robust_outlier_log_var_mu;
real<lower=0> robust_outlier_log_var_std;
}
model{
target+=cauchy_lpdf(alpha|0,5);
target+=cauchy_lpdf(beta|0,5);
target+=uniform_lpdf(lambda|0,1);
target+=cauchy_lpdf(sigma|0,5);
for(t in 2 : T)
{
robust_outlier_log_var~normal(robust_outlier_log_var_mu,robust_outlier_log_var_std);
target+=log_mix(robust_prob_outlier,normal_lpdf(y[t]|alpha+beta*(x[t])+lambda*(y[t-1]),sqrt(exp(robust_outlier_log_var))),normal_lpdf(y[t]|alpha+beta*(x[t])+lambda*(y[t-1]),sigma));
}
}

