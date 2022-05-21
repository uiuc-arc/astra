data{
int<lower=1> N;
real x[N];
vector[N] y;
}
transformed data{
real delta;
delta=1.0E-9;
}
parameters{
real<lower=0> rho;
real<lower=0> alpha;
real<lower=0> sigma;
vector[N] eta;
real<lower=0, upper=0.5> robust_prob_outlier;
real<lower=log((sigma)^2)> robust_outlier_log_var;
real robust_outlier_log_var_mu;
real<lower=0> robust_outlier_log_var_std;
}
model{
vector[N] f;
matrix[N,N] L_K;
matrix[N,N] K;
K=cov_exp_quad(x,alpha,rho);
for(n in 1 : N)
{
K[n,n]=K[n,n]+delta;
}
L_K=cholesky_decompose(K);
f=L_K*eta;
rho~inv_gamma(5,5);
alpha~normal(0,1);
sigma~normal(0,1);
eta~normal(0,1);
for(observe_i in 1 : N)
{
robust_outlier_log_var~normal(robust_outlier_log_var_mu,robust_outlier_log_var_std);
target+=log_mix(robust_prob_outlier,normal_lpdf(y[observe_i]|f[observe_i],sqrt(exp(robust_outlier_log_var))),normal_lpdf(y[observe_i]|f[observe_i],sigma));
}
}

