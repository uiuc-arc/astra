data{
int<lower=0> T;
vector[T] y;
}
parameters{
real mu;
real<lower=-1, upper=1> phi;
real<lower=0> sigma;
vector[T] h;
real<lower=0, upper=10> robust_local_tauexpht2[T];
real<lower=0, upper=10> robust_local_nuexpht2;
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
robust_local_tauexpht2[t]~gamma(robust_local_nuexpht2/2,robust_local_nuexpht2/2);
target+=normal_lpdf(y[t]|0,inv_sqrt(robust_local_tauexpht2[t])*(exp(h[t]/2)));
}
}

