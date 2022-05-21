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
real<lower=0, upper=1> robust_weight[N];
vector[4] beta;
real<lower=0> sigma;
}
model{
for(observe_i in 1 : N)
{
target+=normal_lpdf(kid_score[observe_i]|beta[1]+(beta[2])*(work2[observe_i])+(beta[3])*(work3[observe_i])+(beta[4])*(work4[observe_i]),sigma)*robust_weight[observe_i];
}
}

