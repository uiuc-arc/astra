data{
int<lower=0> N;
vector[N] kid_score;
int mom_work[N];
}
transformed data{
vector[N] work2;
vector[N] work3;
vector[N] work4;
for(i in 1 : N)
{
work2[i]=mom_work[i] == 2;
work3[i]=mom_work[i] == 3;
work4[i]=mom_work[i] == 4;
}
}
parameters{
vector[4] beta;
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
target+=log_mix(robust_prob_outlier,normal_lpdf(kid_score[observe_i]|beta[1]+(beta[2])*(work2[observe_i])+(beta[3])*(work3[observe_i])+(beta[4])*(work4[observe_i]),sqrt(exp(robust_outlier_log_var))),normal_lpdf(kid_score[observe_i]|beta[1]+(beta[2])*(work2[observe_i])+(beta[3])*(work3[observe_i])+(beta[4])*(work4[observe_i]),sigma));
}
}

