data{
int<lower=0> N;
vector[N] y;
vector<lower=0, upper=1>[N] x;
}
parameters{
real a;
real b;
real<lower=0> sigma_y;
real<lower=0, upper=1> robust_local_hyperp;
real<lower=0, upper=10> robust_local_sigma_y[N];
}
model{
for(observe_i in 1 : N)
{
robust_local_sigma_y[observe_i]~normal(sigma_y,robust_local_hyperp);
target+=normal_lpdf(y[observe_i]|a+b*(x[observe_i]),robust_local_sigma_y[observe_i]);
}
}

