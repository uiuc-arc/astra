data{
int<lower=1> K;
int<lower=1> N;
real y[N];
}
parameters{
simplex[K] theta;
ordered[K] mu;
real<lower=0, upper=10> sigma[K];
real<lower=0, upper=1> robust_local_hyperp;
real robust_local_mu[K];
}
model{
real ps[K];
mu~normal(0,10);
for(n in 1 : N)
{
for(k in 1 : K)
{
robust_local_mu[k]~normal(mu[k],robust_local_hyperp);
ps[k]=log(theta[k])+normal_log(y[n],robust_local_mu[k],sigma[k]);
}
target+=(log_sum_exp(ps));
}
}

