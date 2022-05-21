data{
int<lower=0> N;
int<lower=0> n_groups;
int<lower=0> n_scenarios;
int<lower=1, upper=n_groups> group_id[N];
int<lower=1, upper=n_scenarios> scenario_id[N];
vector[N] y;
}
parameters{
real<lower=0, upper=1> robust_weight[N];
vector[n_groups] gamma;
vector[n_scenarios] delta;
real mu;
real<lower=0, upper=100> sigma_gamma;
real<lower=0, upper=100> sigma_delta;
real<lower=0, upper=100> sigma_y;
}
transformed parameters{
vector[N] y_hat;
for(i in 1 : N)
{
y_hat[i]=mu+gamma[group_id[i]]+delta[scenario_id[i]];
}
}
model{
gamma~normal(0,sigma_gamma);
delta~normal(0,sigma_delta);
for(observe_i in 1 : N)
{
target+=normal_lpdf(y[observe_i]|y_hat[observe_i],sigma_y)*robust_weight[observe_i];
}
}

