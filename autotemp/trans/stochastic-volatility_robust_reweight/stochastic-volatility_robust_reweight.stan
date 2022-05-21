data{
int<lower=0> T;
vector[T] y;
}
parameters{
real<lower=0, upper=1> robust_weight[T];
real mu;
real<lower=-1, upper=1> phi;
real<lower=0> sigma;
vector[T] h;
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
target+=normal_lpdf(y[t]|0,exp(h[t]/2))*robust_weight[t];
}
}

