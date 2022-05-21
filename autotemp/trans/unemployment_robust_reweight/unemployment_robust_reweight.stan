data{
int<lower=0> N;
vector[N] y;
vector[N] y_lag;
}
parameters{
real<lower=0, upper=1> robust_weight[N];
vector[2] beta;
real<lower=0> sigma;
}
model{
for(observe_i in 1 : N)
{
target+=normal_lpdf(y[observe_i]|beta[1]+(beta[2])*(y_lag[observe_i]),sigma)*robust_weight[observe_i];
}
}

