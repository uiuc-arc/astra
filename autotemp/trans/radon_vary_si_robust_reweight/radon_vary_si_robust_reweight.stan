data{
int<lower=0> N;
int<lower=1, upper=85> county[N];
vector[N] x;
vector[N] y;
}
parameters{
real<lower=0, upper=1> robust_weight[N];
vector[85] a1;
vector[85] a2;
real mu_a1;
real mu_a2;
real<lower=0, upper=100> sigma_a1;
real<lower=0, upper=100> sigma_a2;
real<lower=0, upper=100> sigma_y;
}
transformed parameters{
vector[N] y_hat;
for(i in 1 : N)
{
y_hat[i]=a1[county[i]]+a2[county[i]]*x[i];
}
}
model{
mu_a1~normal(0,1);
a1~normal(mu_a1,sigma_a1);
mu_a2~normal(0,1);
a2~normal(0.1*mu_a2,sigma_a2);
for(observe_i in 1 : N)
{
target+=normal_lpdf(y[observe_i]|y_hat[observe_i],sigma_y)*robust_weight[observe_i];
}
}

