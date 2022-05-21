data{
int<lower=0> N;
int<lower=0> n_pair;
int<lower=1, upper=n_pair> pair[N];
vector[N] treatment;
vector[N] y;
}
parameters{
real beta;
vector[n_pair] eta;
real mu_a;
real<lower=0, upper=100> sigma_a;
real<lower=0, upper=100> sigma_y;
real<lower=0, upper=10> robust_t_nu;
}
transformed parameters{
vector[N] y_hat;
vector[n_pair] a;
a=100*mu_a+sigma_a*eta;
for(i in 1 : N)
{
y_hat[i]=a[pair[i]]+beta*treatment[i];
}
}
model{
mu_a~normal(0,1);
eta~normal(0,1);
beta~normal(0,1);
for(observe_i in 1 : N)
{
target+=student_t_lpdf(y[observe_i]|robust_t_nu,y_hat[observe_i],sigma_y);
}
}

