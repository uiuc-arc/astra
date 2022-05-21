#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
source(args[1])
data_name <- ls()
data_name <- data_name[!data_name == "args"]
i <- as.numeric(args[2])
x = rbinom(N, 1, 0.1664853)
sigma = 0.82
beta1=1.3267
beta2=-0.6134
y = rnorm(N, x * beta2 + beta1, sigma) # weight=2, bias=1

if (i > 0) {
    # s = rgamma(N, i/10.0 , 1)
    s = i/10.0 * 0.2
    U = runif(N)
    sdy = sd(y)
    for (n in 1:N) {
        if (U[n] < s) {
            y[n] = y[n] + runif(1, 0, sdy*6)
        }
    }
} else {
    s = 0
}

# data_name <- c(data_name)


new_data_file <- paste(dirname(args[1]), "noisy.data.R",sep="/")
dump(data_name,file=new_data_file)
