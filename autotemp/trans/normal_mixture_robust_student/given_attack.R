#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
source(args[1])
data_name <- ls()
data_name <- data_name[!data_name == "args"]
i <- as.numeric(args[2])

U = runif(N)
s = i/10.0 * 0.2
p1 = (1-s)*theta
p2 = p1 + (1-s)*(1-theta)
p3 = 1
mu3 = max(mu1, mu2) + (abs(mu1 - mu2))

y = rep(NA,N)

for (n in 1:N) {
    if (U[n] < p1) {
        y[n] = rnorm(1,mu1,sd)
    }else if (U[n] < p2){
        y[n] = rnorm(1,mu2,sd)
    }else {
        y[n] = rnorm(1,mu3,sd)
    }
}


new_data_file <- paste(dirname(args[1]), "noisy.data.R",sep="/")
dump(data_name,file=new_data_file)
