#!/usr/bin/env Rscript

# Add original.data.R with noise and save a noisy.data.R under the same directory as original.data.R
# Usage: ./ddd_attack.R original.data.R noise_level attack_name data_object_name
# Example: ./ddd_attack.R ../templates/stan_stagnant2_robust/stan_stagnant2_robust.data.R 8 outliers y

#library("rstan")
args <- commandArgs(trailingOnly = TRUE)
source(args[1])
data_name <- ls()
data_name <- data_name[!data_name == "args"]
i <- as.numeric(args[2])
datagood = args[4]
ddd = eval(parse(text=datagood))
integer_data = (all(ddd%%1==0))
binary_data = (length(levels(as.factor(ddd)))==2 && min(ddd)==0)
if ((!integer_data) && (!binary_data)) {
    if (identical("outliers", args[3])) { 
        if (i > 0){
            assign(datagood, sapply(ddd, function(x) ifelse(runif(1) < i/100, x*abs(rnorm(1,i/2,sd(ddd))), x)))
        }; 
        assign(datagood, ddd)
    # }
    # if (identical("outliers", args[3])) {
            # ddd[seq(length(ddd), 5, -floor(100/i))] <- ddd[seq(length(ddd), 5, -floor(100/i))]*5
    } else if (identical("hiddengroup", args[3])) { 
        y_mean = mean(ddd); y_sd = sd(ddd); 
        if (y_mean < 0)
            i = -i;
        # other_mean = y_mean + i * y_sd;  
        assign(datagood, sapply(ddd, function(x) ifelse(runif(1) < 0.2,rnorm(1, y_mean + (i * y_sd)/2, 0.1 * i), x)))
    } else if (identical("skew", args[3])) { 
        library(e1071);
        y_min = min(ddd); y_max = max(ddd); y_mean = mean(ddd);
        y_scale = (ddd-y_min)/(y_max-y_min);
        new_y = 0;
        if (skewness(y_scale,type=1) < 0 ) {
            new_y = (1-(1-y_scale)^(1+i*0.1)) * (max(ddd) - min(ddd)) + min(ddd);
        } else {
            new_y = y_scale^(1+i*0.1) * (max(ddd) - min(ddd)) + min(ddd);
        }
        diff_y = y_mean - mean(new_y);
        assign(datagood,new_y)
    }
} else if (binary_data) {
    if (identical("outliers", args[3])) { 
        print("binary");
        assign(datagood, sapply(ddd, function(x) ifelse(runif(1) < i/100, 1-x, x)))
    } else if (identical("skew", args[3])) { 
        assign(datagood, sapply(ddd, function(x) ifelse(runif(1) < i/100, 1, x)))
    }
} else if (integer_data) {
    #if (identical("outliers", args[3])) { if (i > 0){ddd[seq(length(ddd), 1, -floor(100/i))] <- ddd[seq(length(ddd), 1, -floor(100/i))]*rnorm(1,10,1)}; assign(datagood, ddd)}
    if (identical("outliers", args[3])) {
        y_min = min(ddd); y_max = max(ddd); 
        assign(datagood, sapply(ddd, function(x) ifelse(runif(1) < i/100,max(min(floor(x*rnorm(1,5,sd(ddd)/5)), y_max), y_min) , x)))
    } else if (identical("hiddengroup", args[3])) { 
        y_min = min(ddd); y_max = max(ddd); 
        y_mean = mean(ddd); y_sd = sd(ddd); 
        if (y_mean < 0)
            i = -i;
        # other_mean = y_mean + i * y_sd; 
        assign(datagood, sapply(ddd, function(x) ifelse(runif(1) < 0.2,max(min(x + floor((i * y_sd)/2), y_max), y_min), x)))
    } else if (identical("skew", args[3])) { 
        library(e1071);
        y_min = min(ddd); y_max = max(ddd); 
        y_scale = (ddd-y_min)/(y_max-y_min)
        y_min = min(ddd); y_max = max(ddd); y_mean = mean(ddd);
        y_scale = (ddd-y_min)/(y_max-y_min);
        new_y = 0;
        if (skewness(y_scale,type=1) < 0 ) {
            new_y = (1-(1-y_scale)^(1+i*0.1)) * (max(ddd) - min(ddd)) + min(ddd);
        } else {
            new_y = y_scale^(1+i*0.1) * (max(ddd) - min(ddd)) + min(ddd);
        }
        diff_y = y_mean - mean(new_y);
        assign(datagood,round(new_y))
    }
}
new_data_file <- paste(dirname(args[1]), "noisy.data.R",sep="/")
dump(data_name,file=new_data_file)
