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
real<lower=0, upper=1> robust_weight[N];
vector[4] beta;
}
model{
for(observe_i in 1 : N)
{
target+=bernoulli_logit_lpmf(switched[observe_i]|beta[1]+(beta[2])*(dist100[observe_i])+(beta[3])*(arsenic[observe_i])+(beta[4])*(educ4[observe_i]))*robust_weight[observe_i];
}
}

