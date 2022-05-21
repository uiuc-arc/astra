data{
int<lower=0> N;
vector[N] y;
vector[N] y_lag;
}
parameters{
vector[2] beta;
real<lower=0> sigma;
real<lower=0, upper=1> robust_local_hyperp;
real<lower=0, upper=10> robust_local_sigma[N];
}
model{
for(observe_i in 1 : N)
{
robust_local_sigma[observe_i]~normal(sigma,robust_local_hyperp);
target+=normal_lpdf(y[observe_i]|beta[1]+(beta[2])*(y_lag[observe_i]),robust_local_sigma[observe_i]);
}
}

