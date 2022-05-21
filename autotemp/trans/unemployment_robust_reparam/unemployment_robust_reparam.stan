data{
int<lower=0> N;
vector[N] y;
vector[N] y_lag;
}
parameters{
vector[2] beta;
real<lower=0> sigma;
real<lower=0, upper=10> robust_local_tausigma[N];
real<lower=0, upper=10> robust_local_nusigma;
}
model{
for(observe_i in 1 : N)
{
robust_local_tausigma[observe_i]~gamma(robust_local_nusigma/2,robust_local_nusigma/2);
target+=normal_lpdf(y[observe_i]|beta[1]+(beta[2])*(y_lag[observe_i]),inv_sqrt(robust_local_tausigma[observe_i])*(sigma));
}
}

