data{
int<lower=0> T;
vector[T] y;
}
parameters{
real mu;
real<lower=-1, upper=1> phi;
real<lower=0> sigma;
vector[T] h;
real<lower=0, upper=1> robust_local_hyperp;
real<lower=0, upper=10> robust_local_exph2[T];
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
robust_local_exph2[t]~normal(exp(h[t]/2),robust_local_hyperp);
target+=normal_lpdf(y[t]|0,robust_local_exph2[t]);
}
}

