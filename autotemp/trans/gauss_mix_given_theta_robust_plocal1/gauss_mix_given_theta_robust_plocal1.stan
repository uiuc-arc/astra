data{
int<lower=0> N;
vector[N] y;
real<lower=0, upper=1> theta;
}
parameters{
ordered[2] mu;
real<lower=0> sigma[2];
real<lower=0, upper=1> robust_local_hyperp;
real robust_local_mu1[N];
real robust_local_mu2[N];
}
model{
sigma~normal(0,2);
mu~normal(0,2);
for(n in 1 : N)
{
robust_local_mu2[n]~normal(mu[2],robust_local_hyperp);
robust_local_mu1[n]~normal(mu[1],robust_local_hyperp);
target+=log_mix(theta,normal_lpdf(y[n]|robust_local_mu1[n],sigma[1]),normal_lpdf(y[n]|robust_local_mu2[n],sigma[2]));
}
}

