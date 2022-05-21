data{
int<lower=0> N;
vector[N] y;
}
parameters{
vector[2] mu;
real<lower=0> sigma[2];
real<lower=0, upper=1> theta;
real<lower=0, upper=10> robust_local_tausigma1[N];
real<lower=0, upper=10> robust_local_nusigma1;
real<lower=0, upper=10> robust_local_tausigma2[N];
real<lower=0, upper=10> robust_local_nusigma2;
}
model{
sigma~normal(0,2);
mu[1]~normal(4,0.5);
mu[2]~normal(-4,0.5);
theta~beta(5,5);
for(n in 1 : N)
{
robust_local_tausigma2[n]~gamma(robust_local_nusigma2/2,robust_local_nusigma2/2);
robust_local_tausigma1[n]~gamma(robust_local_nusigma1/2,robust_local_nusigma1/2);
target+=log_mix(theta,normal_lpdf(y[n]|mu[1],inv_sqrt(robust_local_tausigma1[n])*(sigma[1])),normal_lpdf(y[n]|mu[2],inv_sqrt(robust_local_tausigma2[n])*(sigma[2])));
}
}

