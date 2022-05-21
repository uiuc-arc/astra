data{
int<lower=0> T;
vector[T] y;
}
parameters{
real mu;
real<lower=-1, upper=1> phi;
real<lower=0> sigma;
vector[T] h;
real<lower=0, upper=10> robust_t_nu;
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
target+=student_t_lpdf(y[t]|robust_t_nu,0,exp(h[t]/2));
}
}

