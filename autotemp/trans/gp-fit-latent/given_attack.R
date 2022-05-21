#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

x <- (-50:50)/25
N <- length(x)
i <- as.numeric(args[2])
s = i/10.0 * 0.2

am = replicate(N,x)
kk = exp(-0.5 * (am - t(am))^2)
kk = kk + diag(N) * 0.1

mu = rep(0,N)
y = MASS::mvrnorm(1,mu, kk)

U = runif(N)
for (n in 1:N) {
    if (U[n] < s) {
        y[n] = y[n] + runif(1,10,20)
    }
}

data_name = c("N","x","y")
new_data_file <- paste(dirname(args[1]), "noisy.data.R",sep="/")
dump(data_name,file=new_data_file)
