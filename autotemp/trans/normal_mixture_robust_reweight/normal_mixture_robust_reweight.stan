data{
int<lower=0> N;
real y[N];
}
parameters{
real<lower=0, upper=1> robust_weight[N];
real<lower=0, upper=1> theta;
  ordered[2] mu;
}
transformed parameters{
real log_theta;
real log_one_minus_theta;
log_theta=log(theta);
log_one_minus_theta=log(1.0-theta);
}
model{
target+=uniform_lpdf(theta|0,1);
for(k in 1 : 2)
{
mu[k]~normal(0,10);
}
for(n in 1 : N)
{
target+=(log_sum_exp(log_theta+normal_log(y[n],mu[1],1.0)*robust_weight[n],log_one_minus_theta+normal_log(y[n],mu[2],1.0)*robust_weight[n]));
}
}

