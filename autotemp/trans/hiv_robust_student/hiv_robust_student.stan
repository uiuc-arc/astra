data{
int<lower=0> J;
int<lower=0> N;
int<lower=1, upper=J> person[N];
vector[N] time;
vector[N] y;
}
parameters{
vector[J] a1;
vector[J] a2;
real mu_a1;
real mu_a2;
real<lower=0, upper=100> sigma_a1;
real<lower=0, upper=100> sigma_a2;
real<lower=0, upper=100> sigma_y;
real<lower=0, upper=10> robust_t_nu;
}
transformed parameters{
vector[N] y_hat;
for(i in 1 : N)
{
y_hat[i]=a1[person[i]]+a2[person[i]]*time[i];
}
}
model{
mu_a1~normal(0,1);
mu_a2~normal(0,1);
a1~normal(mu_a1,sigma_a1);
a2~normal(0.1*mu_a2,sigma_a2);
for(observe_i in 1 : N)
{
target+=student_t_lpdf(y[observe_i]|robust_t_nu,y_hat[observe_i],sigma_y);
}
}

