data{
int<lower=0> N;
vector[N] y;
real<lower=0, upper=1> theta;
}
parameters{
real<lower=0, upper=1> robust_weight[N];
  ordered[2] mu;
real<lower=0> sigma[2];
}
model{
sigma~normal(0,2);
mu~normal(0,2);
for(n in 1 : N)
{
target+=log_mix(theta,normal_lpdf(y[n]|mu[1],sigma[1])*robust_weight[n],normal_lpdf(y[n]|mu[2],sigma[2])*robust_weight[n]);
}
}

