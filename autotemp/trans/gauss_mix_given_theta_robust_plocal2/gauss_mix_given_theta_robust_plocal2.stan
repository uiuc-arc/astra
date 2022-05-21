data{
int<lower=0> N;
vector[N] y;
real<lower=0, upper=1> theta;
}
parameters{
ordered[2] mu;
real<lower=0> sigma[2];
real<lower=0, upper=1> robust_local_hyperp;
real<lower=0, upper=10> robust_local_sigma1[N];
real<lower=0, upper=10> robust_local_sigma2[N];
}
model{
sigma~normal(0,2);
mu~normal(0,2);
for(n in 1 : N)
{
robust_local_sigma2[n]~normal(sigma[2],robust_local_hyperp);
robust_local_sigma1[n]~normal(sigma[1],robust_local_hyperp);
target+=log_mix(theta,normal_lpdf(y[n]|mu[1],robust_local_sigma1[n]),normal_lpdf(y[n]|mu[2],robust_local_sigma2[n]));
}
}

