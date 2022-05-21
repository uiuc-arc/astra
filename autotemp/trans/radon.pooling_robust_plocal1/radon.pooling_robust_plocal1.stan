data{
int<lower=0> N;
vector[N] y;
vector<lower=0, upper=1>[N] x;
}
parameters{
real a;
real b;
real<lower=0> sigma_y;
real<lower=0, upper=1> robust_local_hyperp;
real robust_local_abx[N];
}
model{
for(observe_i in 1 : N)
{
robust_local_abx[observe_i]~normal(a+b*(x[observe_i]),robust_local_hyperp);
target+=normal_lpdf(y[observe_i]|robust_local_abx[observe_i],sigma_y);
}
}

