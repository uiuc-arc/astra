#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
source(args[1])
data_name <- ls()
data_name <- data_name[!data_name == "args"]
i <- as.numeric(args[2])
N=T

U = runif(N)
s = i/10.0 * 0.2

for (n in 1:N) {
    if (U[n] < s) {
        y[n] = y[n] + runif(1,10,20)
    }
}


new_data_file <- paste(dirname(args[1]), "noisy.data.R",sep="/")
dump(data_name,file=new_data_file)
