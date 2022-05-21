data {
  int<lower=1> K;
  int<lower=1> N;
  real y[N];
}
parameters {
vector[K] theta;
vector[K] mu_prop;
  real mu_loc;
  real<lower=0> mu_scale;
  real<lower=0> sigma[K];
}
transformed parameters {
  vector[K] mu;
  //real[K] mu;
  mu <- mu_loc + mu_scale * cumulative_sum(mu_prop);
}
model {
  // prior
  real ps[K];
  vector[K] log_theta;
  mu_loc ~ cauchy(0,5);
  mu_scale ~ cauchy(0,5);
  sigma ~ cauchy(0,5);

  // likelihood
  // { 
    log_theta <- log(theta);

    for (n in 1:N) {
      for (k in 1:K) {
        ps[k] <- log_theta[k]
                 + normal_log(y[n],mu[k],sigma[k]);
      }
      target+=(log_sum_exp(ps));    
    }
  //}
}
