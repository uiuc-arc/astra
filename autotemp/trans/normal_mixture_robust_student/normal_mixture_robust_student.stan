data{
int<lower=0> N;
real y[N];
}
parameters{
real<lower=0, upper=1> theta;
  ordered[2] mu;
real<lower=0, upper=10> robust_t_nu;
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
target+=(log_sum_exp(log_theta+student_t_lpdf(y[n]|robust_t_nu,mu[1],1.0),log_one_minus_theta+student_t_lpdf(y[n]|robust_t_nu,mu[2],1.0)));
}
}

