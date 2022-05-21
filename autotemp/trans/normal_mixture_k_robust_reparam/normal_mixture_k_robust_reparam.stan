data{
int<lower=1> K;
int<lower=1> N;
real y[N];
}
parameters{
simplex[K] theta;
ordered[K] mu;
real<lower=0, upper=10> sigma[K];
real<lower=0, upper=10> robust_local_tausigmak[N,K];
real<lower=0, upper=10> robust_local_nusigmak;
}
model{
real ps[K];
mu~normal(0,10);
for(n in 1 : N)
{
for(k in 1 : K)
{
robust_local_tausigmak[n,k]~gamma(robust_local_nusigmak/2,robust_local_nusigmak/2);
ps[k]=log(theta[k])+normal_log(y[n],mu[k],inv_sqrt(robust_local_tausigmak[n,k])*(sigma[k]));
}
increment_log_prob(log_sum_exp(ps));}
}

