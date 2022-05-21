data{
int<lower=0> N;
vector[N] y;
}
parameters{
vector[1] beta;
real<lower=0> sigma;
real<lower=0, upper=1> robust_local_hyperp;
real<lower=0, upper=10> robust_local_sigma[N];
}
model{
for(observe_i in 1 : N)
{
robust_local_sigma[observe_i]~normal(sigma,robust_local_hyperp);
target+=normal_lpdf(y[observe_i]|beta[1],robust_local_sigma[observe_i]);
}
}

