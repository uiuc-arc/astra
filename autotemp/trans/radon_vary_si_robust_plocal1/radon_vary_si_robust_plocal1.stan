data{
int<lower=0> N;
int<lower=1, upper=85> county[N];
vector[N] x;
vector[N] y;
}
parameters{
vector[85] a1;
vector[85] a2;
real mu_a1;
real mu_a2;
real<lower=0, upper=100> sigma_a1;
real<lower=0, upper=100> sigma_a2;
real<lower=0, upper=100> sigma_y;
real<lower=0, upper=1> robust_local_hyperp;
real robust_local_y_hat[N];
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
robust_local_y_hat[observe_i]~normal(y_hat[observe_i],robust_local_hyperp);
target+=normal_lpdf(y[observe_i]|robust_local_y_hat[observe_i],sigma_y);
}
}

