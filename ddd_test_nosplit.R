#!/usr/bin/env Rscript

# Add org_datafile with noise and save the noise.data.R under the same dir as the org_datafile
# Usage: ./thisfile org_datafile noise_level
# Example: ./thisfile ../templates/stan_stagnant2_robust/stan_stagnant2_robust.data.R yyy

#library("rstan")
args <- commandArgs(trailingOnly = TRUE)
source(args[1])
data_name <- ls()
data_name <- data_name[!data_name == "args"]
datagood = args[2]
test_data_name = paste(datagood,"_test",sep="")
yyy = eval(parse(text=datagood))
orig_len = length(yyy)
half_len = orig_len # ceiling(orig_len/2)
assign(test_data_name, tail(yyy, half_len))
train_data_file <- paste(dirname(args[1]), "train.data.R",sep="/")
dump(data_name,file=train_data_file)


# test_data_file <- paste(dirname(args[1]), "test.data.R",sep="/")
# dump(c(test_data_name),file=test_data_file)
sss = eval(parse(text=test_data_name))
mmt = as.data.frame(sss)
colnames(mmt) <- test_data_name
rownames(mmt) <- paste(colnames(mmt),"[",rownames(mmt),"]",sep="")
df <- t(data.frame(t(mmt),check.names=F))
colnames(df) <- "Truth"
# truth_file is the same as test datafile
new_truth_file <- paste(dirname(args[1]), "truth_file", sep="/")
write.csv(data.frame("name"=rownames(df),df,check.names=F),file=new_truth_file, row.names=FALSE)
