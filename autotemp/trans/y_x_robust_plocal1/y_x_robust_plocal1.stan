data{
int<lower=0> N;
vector[N] x;
vector[N] y;
}
parameters{
vector[2] beta;
real<lower=0> sigma;
real<lower=0, upper=1> robust_local_hyperp;
real robust_local_beta1beta2x[N];
}
model{
for(observe_i in 1 : N)
{
robust_local_beta1beta2x[observe_i]~normal(beta[1]+(beta[2])*(x[observe_i]),robust_local_hyperp);
target+=normal_lpdf(y[observe_i]|robust_local_beta1beta2x[observe_i],sigma);
}
}

