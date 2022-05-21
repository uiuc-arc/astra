data{
int<lower=0> N;
vector[N] y;
vector<lower=0, upper=1>[N] x;
}
parameters{
real a;
real b;
real<lower=0> sigma_y;
real<lower=0, upper=10> robust_local_tausigma_y[N];
real<lower=0, upper=10> robust_local_nusigma_y;
}
model{
for(observe_i in 1 : N)
{
robust_local_tausigma_y[observe_i]~gamma(robust_local_nusigma_y/2,robust_local_nusigma_y/2);
target+=normal_lpdf(y[observe_i]|a+b*(x[observe_i]),inv_sqrt(robust_local_tausigma_y[observe_i])*(sigma_y));
}
}

