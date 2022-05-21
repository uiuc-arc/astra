data{
int<lower=0> N;
vector[N] y;
vector<lower=0, upper=1>[N] x;
}
parameters{
real<lower=0, upper=1> robust_weight[N];
real a;
real b;
real<lower=0> sigma_y;
}
model{
for(observe_i in 1 : N)
{
target+=normal_lpdf(y[observe_i]|a+b*(x[observe_i]),sigma_y)*robust_weight[observe_i];
}
}

