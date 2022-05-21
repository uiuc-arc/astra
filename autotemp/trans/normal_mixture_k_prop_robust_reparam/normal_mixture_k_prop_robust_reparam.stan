data{
int<lower=1> K;
int<lower=1> N;
real y[N];
}
parameters{
simplex[K] theta;
simplex[K] mu_prop;
real mu_loc;
real<lower=0> mu_scale;
real<lower=0> sigma[K];
real<lower=0, upper=10> robust_local_tausigmak[N,K];
real<lower=0, upper=10> robust_local_nusigmak;
}
transformed parameters{
ordered[K] mu;
mu=mu_loc+mu_scale*cumulative_sum(mu_prop);
}
model{
real ps[K];
vector[K] log_theta;
mu_loc~cauchy(0,5);
mu_scale~cauchy(0,5);
sigma~cauchy(0,5);
log_theta=log(theta);
for(n in 1 : N)
{
for(k in 1 : K)
{
robust_local_tausigmak[n,k]~gamma(robust_local_nusigmak/2,robust_local_nusigmak/2);
ps[k]=log_theta[k]+normal_log(y[n],mu[k],inv_sqrt(robust_local_tausigmak[n,k])*(sigma[k]));
}
target+=(log_sum_exp(ps));
}
}

