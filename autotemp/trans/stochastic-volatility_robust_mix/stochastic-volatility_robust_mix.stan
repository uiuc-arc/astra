data{
int<lower=0> T;
vector[T] y;
}
parameters{
real mu;
real<lower=-1, upper=1> phi;
real<lower=0> sigma;
vector[T] h;
real<lower=0, upper=0.5> robust_prob_outlier;
real<lower=log(max(exp(h/2))^2)> robust_outlier_log_var;
real robust_outlier_log_var_mu;
real<lower=0> robust_outlier_log_var_std;
}
model{
phi~uniform(-1,1);
sigma~cauchy(0,5);
mu~cauchy(0,10);
h[1]~normal(mu,sigma/sqrt(1-phi*phi));
for(t in 2 : T)
{
h[t]~normal(mu+phi*(h[t-1]-mu),sigma);
}
for(t in 1 : T)
{
robust_outlier_log_var~normal(robust_outlier_log_var_mu,robust_outlier_log_var_std);
target+=log_mix(robust_prob_outlier,normal_lpdf(y[t]|0,sqrt(exp(robust_outlier_log_var))),normal_lpdf(y[t]|0,exp(h[t]/2)));
}
}

