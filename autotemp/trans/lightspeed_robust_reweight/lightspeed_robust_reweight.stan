data{
int<lower=0> N;
vector[N] y;
}
parameters{
real<lower=0, upper=1> robust_weight[N];
vector[1] beta;
real<lower=0> sigma;
}
model{
for(observe_i in 1 : N)
{
target+=normal_lpdf(y[observe_i]|beta[1],sigma)*robust_weight[observe_i];
}
}

