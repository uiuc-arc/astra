#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
source(args[1])
data_name <- ls()
data_name <- data_name[!data_name == "args"]
i <- as.numeric(args[2])
if (i > 0) {
    s = rgamma(N, i/10.0 , 1)
} else {
    s = 0
}
y = rnorm(N, 26.6, 11*(s+1)) # weight=2, bias=1


new_data_file <- paste(dirname(args[1]), "noisy.data.R",sep="/")
dump(data_name,file=new_data_file)
