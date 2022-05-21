data{
int<lower=0> N;
int<lower=0, upper=1> switched[N];
vector[N] dist;
vector[N] arsenic;
vector[N] educ;
}
transformed data{
vector[N] dist100;
vector[N] educ4;
dist100=dist/100.0;
educ4=educ/4.0;
}
parameters{
vector[4] beta;
real<lower=0, upper=1> robust_local_hyperp;
real robust_local_beta1beta2dist100beta3arsenicbeta4educ4[N];
}
model{
for(observe_i in 1 : N)
{
robust_local_beta1beta2dist100beta3arsenicbeta4educ4[observe_i]~normal(beta[1]+(beta[2])*(dist100[observe_i])+(beta[3])*(arsenic[observe_i])+(beta[4])*(educ4[observe_i]),robust_local_hyperp);
target+=bernoulli_logit_lpmf(switched[observe_i]|robust_local_beta1beta2dist100beta3arsenicbeta4educ4[observe_i]);
}
}

