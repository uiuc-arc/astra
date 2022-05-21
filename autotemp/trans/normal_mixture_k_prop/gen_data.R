#!/usr/bin/env Rscript

# Add org_datafile with noise and save the noise.data.R under the same dir as the org_datafile
# Usage: ./thisfile org_datafile noise_level
# Example: ./gen_data.R ../templates/stan_stagnant2_robust/stan_stagnant2_robust.data.R 1

#library("rstan")
#source("hmm_gen_data.R")
# fit <- stan('hmm-semisup.stan', # 'hmm-fit-semisup.stan',
args <- commandArgs(trailingOnly = TRUE)
source(args[1])
data_name <- ls()
data_name <- data_name[!data_name == "args"]
i <- as.numeric(args[2])
if (identical("scale", args[3])) { y <- y + i}
if (identical("noise", args[3])) { y <- y + rnorm(length(y),0,i)}
if (identical("power", args[3])) { y <- y ^ i}
if (identical("root",  args[3])) { y <- sign(y) * abs(y)^(1/i) }
if (identical("replace", args[3])) { y <- sapply(y, function(x) ifelse(runif(1) < i/100, x*100, x))}
if (identical("twomode", args[3])) { 
    y_mean = mean(y); y_sd = sd(y); 
    if (y_mean < 0)
        i = -i;
    # other_mean = y_mean + i * y_sd; 
    y <- sapply(y, function(x) ifelse(runif(1) < 0.2,x + i * y_sd, x)) # rnorm(1,x + i * y_sd, y_sd)
}
if (identical("skew", args[3])) { 
    y_min = min(y); y_max = max(y); 
    y_scale = (y-y_min)/(y_max-y_min)
    y <- y_scale^(1+i*0.1) * (max(y) - min(y)) + min(y)
}
# if (identical("dist",args[3])) { y <- uniform(len10000, 100000) }
# if (strcmp("dupli", args[3])) { if (runif(1) < 0.33) y <- runif(1)}
#var_Y <- var(Y)
#for(i in 0:10){
    # y <- y^i# + rnorm(length(y),0,i)
#    print(Y + noise)
#}
# y <- y + noise
#to_replace <- c("Y")
#replace_with <- c("Y_new")
#new_data_name <- replace(data_name,data_name %in% to_replace, replace_with)
new_data_file <- paste(dirname(args[1]), "noisy.data.R",sep="/")
dump(data_name,file=new_data_file)
