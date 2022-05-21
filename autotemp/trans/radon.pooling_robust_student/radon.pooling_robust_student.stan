data{
int<lower=0> N;
vector[N] y;
vector<lower=0, upper=1>[N] x;
}
parameters{
real a;
real b;
real<lower=0> sigma_y;
real<lower=0, upper=10> robust_t_nu;
}
model{
for(observe_i in 1 : N)
{
target+=student_t_lpdf(y[observe_i]|robust_t_nu,a+b*(x[observe_i]),sigma_y);
}
}

