data{
int<lower=1> N;
real x[N];
vector[N] y;
}
transformed data{
real delta;
delta=1.0E-9;
}
parameters{
real<lower=0, upper=1> robust_weight[N];
real<lower=0> rho;
real<lower=0> alpha;
real<lower=0> sigma;
vector[N] eta;
}
model{
vector[N] f;
matrix[N,N] L_K;
matrix[N,N] K;
K=cov_exp_quad(x,alpha,rho);
for(n in 1 : N)
{
K[n,n]=K[n,n]+delta;
}
L_K=cholesky_decompose(K);
f=L_K*eta;
rho~inv_gamma(5,5);
alpha~normal(0,1);
sigma~normal(0,1);
eta~normal(0,1);
for(observe_i in 1 : N)
{
target+=normal_lpdf(y[observe_i]|f[observe_i],sigma)*robust_weight[observe_i];
}
}

