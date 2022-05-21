data{
int<lower=0> T;
real y[T];
real x[T];
}
parameters{
real alpha;
real beta;
real<lower=0, upper=1> lambda;
real<lower=0> sigma;
real<lower=0, upper=1> robust_local_hyperp;
real robust_local_alphabeaxlambday1[T];
}
model{
target+=cauchy_lpdf(alpha|0,5);
target+=cauchy_lpdf(beta|0,5);
target+=uniform_lpdf(lambda|0,1);
target+=cauchy_lpdf(sigma|0,5);
for(t in 2 : T)
{
robust_local_alphabeaxlambday1[t]~normal(alpha+beta*(x[t])+lambda*(y[t-1]),robust_local_hyperp);
target+=normal_lpdf(y[t]|robust_local_alphabeaxlambday1[t],sigma);
}
}

