data{
int<lower=0> N;
vector[N] kid_score;
int mom_work[N];
}
transformed data{
vector[N] work2;
vector[N] work3;
vector[N] work4;
for(i in 1 : N)
{
work2[i]=mom_work[i] == 2;
work3[i]=mom_work[i] == 3;
work4[i]=mom_work[i] == 4;
}
}
parameters{
vector[4] beta;
real<lower=0> sigma;
real<lower=0, upper=1> robust_local_hyperp;
real<lower=0, upper=10> robust_local_sigma[N];
}
model{
for(observe_i in 1 : N)
{
robust_local_sigma[observe_i]~normal(sigma,robust_local_hyperp);
target+=normal_lpdf(kid_score[observe_i]|beta[1]+(beta[2])*(work2[observe_i])+(beta[3])*(work3[observe_i])+(beta[4])*(work4[observe_i]),robust_local_sigma[observe_i]);
}
}

