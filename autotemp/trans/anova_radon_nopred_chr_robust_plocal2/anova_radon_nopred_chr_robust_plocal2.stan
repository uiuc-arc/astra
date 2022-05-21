data{
int<lower=0> J;
int<lower=0> N;
int<lower=1, upper=J> county[N];
vector[N] y;
}
parameters{
vector[J] eta;
real mu_a;
real<lower=0, upper=100> sigma_a;
real<lower=0, upper=100> sigma_y;
real<lower=0, upper=1> robust_local_hyperp;
real<lower=0, upper=10> robust_local_sigma_y[N];
}
transformed parameters{
vector[J] a;
vector[N] y_hat;
a=mu_a+sigma_a*eta;
for(i in 1 : N)
{
y_hat[i]=a[county[i]];
}
}
model{
mu_a~normal(0,1);
eta~normal(0,1);
for(observe_i in 1 : N)
{
robust_local_sigma_y[observe_i]~normal(sigma_y,robust_local_hyperp);
target+=normal_lpdf(y[observe_i]|y_hat[observe_i],robust_local_sigma_y[observe_i]);
}
}

