#!/usr/bin/env python3


import csv
import sys
from scipy.stats import *
from scipy.spatial.distance import jensenshannon
# from rpy2.robjects.packages import importr
# from rpy2.robjects import r, pandas2ri, conversion
from pandas import *
import pandas as pd
import numpy as np
import os.path
import argparse
import re
#from fractions import Fraction
csv.field_size_limit(sys.maxsize)
_SQRT2 = np.sqrt(2) # used in hellinger

def p_close(p_value, thres):
    if abs(p_value) <= abs(thres):
        return False # p_value stat significant, res different
    else:
        return True

def d_close(divergence, thres):
    if abs(divergence) >= abs(thres):
        return False # divergence too big, res different
    else:
        return True

def b_close(bool_value, thres):
    return bool(bool_value)

pydist_dict = {
    "normal" : "norm"
}

rdist_dict = {
    "normal" : "norm"
}

thres_dict = {
    "t" : 0.05,
    "ks" : 0.05,
    "kl" : 1,
    "ekl" : 0.5,
    "js" : 0.5,
    "smkl" : 1,
    "hell" : 0.4,
    "ehel" : 0.6,
    "wass" : 0.1,
    "rhat" : 1.01,
    "rhatavg" : 1.01,
    "rhatmax" : 1.01,
    "ess_n" : 0.01,
    "mmd": 0.05
}

close_dict = {
    "t": p_close,
    "ks": p_close,
    "kl": d_close,
    "ekl": d_close,
    "js": d_close,
    "smkl": d_close,
    "hell": d_close,
    "ehel": d_close,
    "wass": d_close,
    "mmd": b_close
}

extreme_dict = {
    "t": min,
    "ks": min,
    "kl": max,
    "ekl": max,
    "js": max,
    "smkl": max,
    "hell": max,
    "ehel": max,
    "wass" : max,
    "mmd" : min
}

class DataDataMetric:
    def __init__(self, value_a, value_b):
        self.data_a = value_a
        self.data_b = value_b
        #self.rhat_a = value_a.rhat
        #self.rhat_b = value_b.rhat

    def eval_metrics(self, metrics, thresholds, var_check = False):
        result = []
        for metric_name, threshold in zip(metrics, thresholds):
            try:
                metric = getattr(self, metric_name + "_s")
            except:
                print("Error: unknown metric. Metric must be one of {t, ks, kl, smkl, hell[inger], wass[erstein], Rhat, ESS}")
                exit(0)
            if "kl" in metric_name and "e" not in metric_name and var_check:
                result.append(metric(threshold) + (metric_name,))
                result.append(metric(threshold, var_check = True) + (metric_name,))
            else:
                result.append(metric(threshold) + (metric_name,))
        return result


    def reform_data(self, data_a, data_b):
        size = min(len(data_b), len(data_a))
        return (data_a[-size:], data_b[-size:])

    def t_s(self, thres=0):
        # required: data_a and data_b must have the same size
        # data_a, data_b = self.reform_data(self.data_a, self.data_b)
        statistics = ttest_ind(self.data_a, self.data_b)[1]
        return p_close(statistics, thres), statistics

    def ks_s(self, thres=0):
        statistics = ks_2samp(self.data_a, self.data_b)[1]
        return p_close(statistics, thres), statistics

    def var_small(self):
        var_a = np.var(self.data_a)
        var_b = np.var(self.data_b)
        diff_ab = abs(np.mean(self.data_a) - np.mean(self.data_b))
        return diff_ab < 0.01 and var_a < 0.01 and var_b < 0.01

    def ecdf(self, smooth_deg=0):
        u_values = np.array(self.data_a)
        v_values = np.array(self.data_b)
        ux, u_cdf = np.unique(u_values, return_counts=True)
        vx, v_cdf = np.unique(v_values, return_counts=True)
        # ux = sorted((u_values))
        # vx = sorted(set(v_values))
        if ux.size < vx.size:
            if smooth_deg == 0:
                v_cdf = np.zeros(ux.size)
            else:
                v_cdf = np.full(ux.size, smooth_deg)
            np.add.at(v_cdf, ux.searchsorted(v_values, 'right') - 1, 1)
        else:
            if smooth_deg == 0:
                u_cdf = np.zeros(vx.size)
            else:
                u_cdf = np.full(vx.size, smooth_deg)
            np.add.at(u_cdf, vx.searchsorted(u_values, 'right') - 1, 1)
            # cdf_indices = v_values[v_sorter].searchsorted(ux, 'right')
            # temp_ele, u_cdf = np.unique(cdf_indices, return_counts=True)
            # v_cdf = np.ones(len(u_cdf))
        # print(str(u_cdf))
        # print(str(v_cdf))
        if v_cdf.size == 1 and u_cdf.size == 1:
            if ux[0] < vx[0] and ux[-1] < vx[0]:
                u_cdf = np.append(u_cdf, 0.5)
                v_cdf = np.insert(v_cdf, 0, 0.5)
            elif vx[0] < ux[0] and vx[-1] < ux[0]:
                v_cdf = np.append(v_cdf, 0.5)
                u_cdf = np.insert(u_cdf, 0, 0.5)
        return (u_cdf, v_cdf)

    def kl_s(self, thres=float("inf"), var_check=False):
        r.assign('X', self.data_a)
        r.assign('Y', self.data_b)
        if (self.data_a == self.data_b):
            statistics = 0
        elif var_check and self.var_small():
            statistics = 0
        else:
            try:
                r_ret = r('''
                        X = as.numeric(t(X))
                        Y = as.numeric(t(Y))
                        library(FNN)
                        kl = KL.divergence(X, Y, k = 20, algorithm=c("kd_tree", "cover_tree", "brute"))
                        if(length(kl[is.finite(kl)]) == 0) {Inf} else { mean(kl[is.finite(kl)]) }
                        ''')
                r_ret_str = str(r_ret)
                statistics = float(r_ret_str[4:])
                if statistics < 0:
                    statistics = 0
            except:
                statistics = np.nan
        return d_close(statistics, thres), statistics

    def ekl_s(self, thres=float("inf")):
        statistics = entropy(*self.ecdf(0.5))
        return d_close(statistics, thres), statistics

    def js_s(self, thres=float("inf")):
        statistics = jensenshannon(*self.ecdf())
        return d_close(statistics, thres), statistics

    def ehel_s(self, thres=float("inf")):
        u_cdf, v_cdf = self.ecdf()
        u_cdf = u_cdf / np.sum(u_cdf, dtype="float")
        v_cdf = v_cdf / np.sum(v_cdf, dtype="float")
        statistics = np.sqrt(np.sum((np.sqrt(u_cdf) - np.sqrt(v_cdf)) ** 2)) / _SQRT2
        return d_close(statistics, thres), statistics

    def smkl_s(self, thres=float("inf"), var_check=False):
        r.assign('X', self.data_a)
        r.assign('Y', self.data_b)
        if (self.data_a == self.data_b):
            statistics = 0
        elif var_check and self.var_small():
            statistics = 0
        else:
            try:
                r_ret = r('''
                        X = as.numeric(t(X))
                        Y = as.numeric(t(Y))
                        library(FNN)
                        klxy = KL.divergence(X, Y, k = 20, algorithm=c("kd_tree", "cover_tree", "brute"))
                        klyx = KL.divergence(Y, X, k = 20, algorithm=c("kd_tree", "cover_tree", "brute"))
                        if(length(klxy[is.finite(klxy)]) == 0 | length(klyx[is.finite(klyx)]) == 0) {Inf} else{
                            mean(klxy[is.finite(klxy)]) + mean(klyx[is.finite(klyx)])
                        }
                        ''')
                r_ret_str = str(r_ret)
                statistics = float(r_ret_str[4:])
                if statistics < 0:
                    statistics = 0
            except:
                statistics = np.nan
        return d_close(statistics, thres), statistics

    def hell_s(self, thres=1):
        r.assign('X', self.data_a)
        r.assign('Y', self.data_b)
        try:
            r_ret = r('''
                    X = as.numeric(t(X))
                    Y = as.numeric(t(Y))
                    min2 = min(c(min(X),min(Y)))
                    max2 = max(c(max(X),max(Y)))
                    library(statip)
                    hellinger(X, Y, min2, max2)
                    ''')
            r_ret_str = str(r_ret)
            statistics = float(r_ret_str[4:])
        except:
            statistics = np.inf
        return d_close(statistics, thres), statistics

    def wass_s(self, thres=float("inf")):
        statistics = wasserstein_distance(self.data_a, self.data_b)
        return d_close(statistics, thres), statistics

    def mmd_s(self, thres=0.05, var_check=False):
        r.assign('X', self.data_a)
        r.assign('Y', self.data_b)
        r.assign('alpha',thres)
        try:
            r_ret = r('''
                    X = as.numeric(t(X))
                    Y = as.numeric(t(Y))
                    library(kernlab)
                    X = as.list((X))
                    Y = as.list((Y))
                    ret = kmmd(X, Y, alpha=alpha)
                    ret@H0
                    ''')
            r_ret_str = str(r_ret) # from different distribution?
            if "FALSE" in r_ret_str:
                statistics = True
            else:
                statistics = False
        except:
            if (self.data_a == self.data_b):
                statistics = True
            elif self.var_small():
                statistics = True
            else:
                statistics = False
        return statistics, statistics


class DataDistMetric:
    def __init__(self, name, value_a, value_b, **kwargs):
        self.data_a = value_a
        self.dist_name = value_b.dist_name
        self.dist_args = value_b.dist_args
        self.close = None
        try:
            self.metric = getattr(self, name + "_s")
        except:
            print("Error: unknown metric. Metric must be one of {t, ks, kl, smkl, hell[inger]}")
            exit(1)

    def pyr_dist(self, pyr):
        try:
            if pyr == "py":
                result = pydist_dict[self.dist_name]
            elif pyr == "r":
                result = rdist_dict[self.dist_name]
        except:
            result = dist_name
        return result

    def dist_obj(self, pydist_name):
        return eval(pydist_name)

    def t_s(self, thres=0):
        return p_close, ttest_1samp(self.data_a, self.dist_obj(self.pyr_dist("py")).mean(*self.dist_args))[1]

    def ks_s(self, thres=0):
        return p_close, kstest(self.data_a, self.pyr_dist("py"), args=self.dist_args)[1]

    def kl_s(self, thres=float("inf")):
        len_data_a = len(self.data_a)
        dict_data_a = dict((x, self.data_a.count(x)/float(len_data_a)) for x in self.data_a)
        keys = dict_data_a.keys()
        p = [dict_data_a[kk] for kk in keys]
        q = self.dist_obj(self.pyr_dist("py")).pdf(keys, *self.dist_args)
        q = [np.finfo(np.float32).eps if qq == 0 else qq for qq in q]
        return d_close, entropy(p, q)

    def smkl_s(self, thres=float("inf")):
        len_data_a = len(self.data_a)
        dict_data_a = dict((x, self.data_a.count(x)/float(len_data_a)) for x in self.data_a)
        keys = dict_data_a.keys()
        p = [dict_data_a[kk] for kk in keys]
        q = self.dist_obj(self.pyr_dist("py")).pdf(keys, *self.dist_args)
        # q = [np.finfo(np.float32).eps if qq == 0 else qq for qq in q]
        return d_close, entropy(p, q) + entropy(q, p)

    def hell_s(self, thres=1):
        r.assign('X', self.data_a)
        r_ret = r('''
                X = as.numeric(t(X))
                Y = r{}({}, {})
                min2 = min(c(min(X),min(Y)))
                max2 = max(c(max(X),max(Y)))
                library(statip)
                hellinger(X, Y, min2, max2)
                '''.format(self.pyr_dist("r"), len(self.data_a),\
                        str(self.dist_args)[1:-1]))
        r_ret_str = str(r_ret)
        return d_close, float(r_ret_str[4:])


# class Data:
#     def __init__(self, sample):
#         self.sample = sample
#         #self.rhat = rhat

class Dist:
    def __init__(self, dist_name, dist_args):
        self.dist_name = dist_name
        self.dist_args = dist_args

def DataPredMetric(data_df, csv_df):
    Y_rep_names = [xx for xx in list(csv_df) if "_rep" in xx]
    Y_name = Y_rep_names[0].split("_rep")[0]
    ret = []
    # check extreme values
    p_max = min(sum(csv_df[Y_rep_names].max(axis=1) > data_df[Y_name].max()),
                sum(csv_df[Y_rep_names].max(axis=1) < data_df[Y_name].max()))\
            / float(len(csv_df.index))
    p_min = min(sum(csv_df[Y_rep_names].min(axis=1) < data_df[Y_name].min()),
                sum(csv_df[Y_rep_names].min(axis=1) > data_df[Y_name].min()))\
            / float(len(csv_df.index))
    ret.extend([p_min, p_max])
    # check variance (overdispersed data)
    p_var = min(sum(csv_df[Y_rep_names].var(axis=1) > data_df[Y_name].var()),
                sum(csv_df[Y_rep_names].var(axis=1) < data_df[Y_name].var()))\
            / float(len(csv_df.index))
    ret.append(p_var)
    # skewness
    p_skew = min(sum(csv_df[Y_rep_names].skew(axis=1) > data_df[Y_name].skew()),
                sum(csv_df[Y_rep_names].skew(axis=1) < data_df[Y_name].skew()))\
            / float(len(csv_df.index))
    ret.append(p_skew)
    return ret

def DataLPMLMetric(data_df, csv_df):
    Y_all = data_df["Y"]
    # print(Y_all)
    # print(csv_df["lambda.1"])
    ret = 0
    log_Z = 0
    # zij = np.array([])
    for _i in range(1,len(Y_all)+1):
        # use log pmf for better accuracy
        pi = poisson.logpmf(Y_all[_i], np.exp(csv_df["lambda.{}".format(_i)])) # * csv_df["robust_weights.{}".format(_i)] # robust_local_w
        # zi = poisson.logpmf(Y_all[_i], np.exp(csv_df["lambda.{}".format(_i)])) * (csv_df["robust_weights.{}".format(_i)] - 1)
        # zij = np.concatenate((zij,zi.values))
        # pi = [1.0 / ppi if not ppi == 0 else 10**100 for ppi in pi]
        small_pi = min(pi) #[ppi for ppi in pi if ppi < -300 ]
        ret -= small_pi
        pi = pi - small_pi

        # for ssi in small_pi:
        #     sssi = ssi - small_pi_deduct
        #     ret -= sssi
        #     small_pi_deduct += sssi
        #     pi = pi - sssi
        # if(np.mean(np.exp(-pi)) == 0):
        #     print(pi)
        ret += np.log(np.mean(np.exp(-pi)))
    ret = ret / len(Y_all)

    # max_zij = max(zij)
    # log_Z += max_zij
    # zij = zij - max_zij
    # log_Z += np.log(np.mean(np.exp(zij)))
    # ret = ret + log_Z
    # print(csv_df.loc[:, csv_df.columns.str.startswith('robust_weight.')])
    return [ret]


class SummSummMetric:
    def __init__(self, value_a, value_b):
        self.summ_a = value_a.summary_df
        self.summ_b = value_b.summary_df

    def param_mean_diff(self, metrics=[], thresholds=[], var_check = False):
        #param_mean = self.summ_a.Mean
        # print(param_mean.to_frame().join(self.summ_b.Mean,lsuffix='_left', rsuffix='_right'))
        print(pd.concat([(self.summ_a.Mean - self.summ_b.Mean).abs(), (self.summ_b.StdDev.add_suffix('_StdDev'))]).to_frame().T.to_csv(index=False))
        #print((self.summ_a.Mean - self.summ_b.Mean).to_frame().abs().T.to_csv(index=False)) # join(self.summ_b.StdDev, rsuffix='_StdDev').to_csv(index=False))
    def param_mean_diff_agg(self, metrics=[], thresholds=[], var_check = False):
        print(str(np.mean((self.summ_a.Mean - self.summ_b.Mean).abs())) + "," + str(np.mean(self.summ_a.StdDev - self.summ_b.StdDev)))
        # print(pd.concat([(self.summ_a.Mean - self.summ_b.Mean).abs(), (self.summ_b.StdDev.add_suffix('_StdDev'))]).to_frame().T.to_csv(index=False))

class SummTrueMetric:
    def __init__(self, value_a, true_a):
        self.summ_a = value_a.summary_df
        self.truth = true_a.truth

    def param_true_diff(self, metrics=[], thresholds=[], var_check = False):
        # param_mean = self.summ_a.Mean
        # print(param_mean.to_frame().join(self.summ_b.Mean,lsuffix='_left', rsuffix='_right'))
        print(pd.concat([(self.summ_a.Mean - self.truth.Truth).abs(), (self.summ_a.StdDev.add_suffix('_StdDev'))]).to_frame().T.to_csv(index=False))
        #print((self.summ_a.Mean - self.summ_b.Mean).to_frame().abs().T.to_csv(index=False)) # join(self.summ_b.StdDev, rsuffix='_StdDev').to_csv(index=False))
    def y_wass(self, metrics=[], thresholds=[], var_check=False):
        joint_summ_truth = self.summ_a.join(self.truth)
        joint_summ_truth.dropna(subset=['Mean', 'Truth'],inplace=True)
        return(wasserstein_distance(joint_summ_truth.Mean,joint_summ_truth.Truth))
    def y_mse(self, metrics=[], thresholds=[], var_check=False):
        not_ytest_names = [nn for nn in self.truth.index if not 'test' in nn]
        truth_drop = self.truth.drop(index=not_ytest_names)
        joint_summ_truth = self.summ_a.join(truth_drop)
        joint_summ_truth.dropna(subset=['Mean', 'Truth'],inplace=True)
        from sklearn.metrics import mean_squared_error
        return(mean_squared_error(joint_summ_truth.Truth, joint_summ_truth.Mean))
    def y_pam(self, metrics=[], thresholds=[], var_check=False):
        not_ytest_names = [nn for nn in self.truth.index if 'test' in nn]
        truth_drop = self.truth.drop(index=not_ytest_names)
        joint_summ_truth = self.summ_a.join(truth_drop)
        joint_summ_truth.dropna(subset=['Mean', 'Truth'],inplace=True)
        from sklearn.metrics import mean_squared_error
        return(mean_squared_error(joint_summ_truth.Truth, joint_summ_truth.Mean))
    def y_pr2(self, metrics=[], thresholds=[], var_check=False):
        not_ytest_names = [nn for nn in self.truth.index if not 'test' in nn]
        truth_drop = self.truth.drop(index=not_ytest_names)
        joint_summ_truth = self.summ_a.join(truth_drop)
        joint_summ_truth.dropna(subset=['Mean', 'Truth'],inplace=True)
        # from sklearn.metrics import r2_score
        # print(r2_score(joint_summ_truth.Truth, joint_summ_truth.Mean))
        return(1 - np.sum(np.square(joint_summ_truth.Truth - joint_summ_truth.Mean))/np.sum(np.square(joint_summ_truth.Truth)))
    def y_pl1(self, metrics=[], thresholds=[], var_check=False):
        not_ytest_names = [nn for nn in self.truth.index if not 'test' in nn]
        truth_drop = self.truth.drop(index=not_ytest_names)
        joint_summ_truth = self.summ_a.join(truth_drop)
        joint_summ_truth.dropna(subset=['Mean', 'Truth'],inplace=True)
        return(1 - np.sum(np.abs(joint_summ_truth.Truth - joint_summ_truth.Mean))/np.sum(np.abs(joint_summ_truth.Truth)))
    def y_mad(self, metrics=[], thresholds=[], var_check=False):
        not_ytest_names = [nn for nn in self.truth.index if not 'test' in nn]
        truth_drop = self.truth.drop(index=not_ytest_names)
        joint_summ_truth = self.summ_a.join(truth_drop)
        joint_summ_truth.dropna(subset=['Mean', 'Truth','StdDev'],inplace=True)
        return(np.mean(np.square((joint_summ_truth.Truth - joint_summ_truth.Mean)/joint_summ_truth.StdDev)))
    def y_rhat(self, metrics=[], thresholds=[], var_check=False):
        not_ytest_names = [nn for nn in self.summ_a.index if 'test' in nn]
        summ_a_drop = self.summ_a.drop(index=not_ytest_names)
        return np.mean(summ_a_drop.R_hat)
    def y_rmax(self, metrics=[], thresholds=[], var_check=False):
        not_ytest_names = [nn for nn in self.summ_a.index if 'test' in nn]
        summ_a_drop = self.summ_a.drop(index=not_ytest_names)
        return np.max(summ_a_drop.R_hat)
    def y_lik(self, metrics=[], thresholds=[], var_check=False):
        return self.summ_a.Mean["log_lik"]


class Truth:
    def __init__(self, truth_file):
        self.truth = pd.read_csv(truth_file)
        self.truth.set_index("name", inplace=True)

class Summary:
    def __init__(self, summary_file, runtime=False, robust=False):
        self.summary_file = summary_file
        self.runtime_df = None
        summary_df = pd.read_csv(summary_file,comment='#') # sep="\s+")
        summary_df.set_index("name", inplace=True)
        if not runtime and not robust:
            summary_df.drop([xx for xx in list(summary_df.index) if "__" in xx], inplace=True)
            self.summary_df = summary_df
        elif runtime:
            self.summary_df = summary_df.drop([xx for xx in list(summary_df.index) if "__" in xx])
            self.runtime_df = summary_df.drop([xx for xx in list(summary_df.index) if "__" not in xx])
        elif robust:
            self.summary_df = summary_df.drop([xx for xx in list(summary_df.index) if "__" in xx or "robust_local" in xx or "robust_hyper" in xx or "robust_weight" in xx or "aug_link" in xx or "robust_const" in xx or "robust_" in xx]) #  or "_test" in xx])
            #self.runtime_df = summary_df.drop([xx for xx in list(summary_df.index) if "__" not in xx])

    def rhat(self, thres=thres_dict["rhat"], opt=["avg"]):
        ret = []
        for oo in opt:
            if "av" in oo:
                rhat_avg = self.summary_df.R_hat.mean()
                ret += [d_close(rhat_avg, thres),rhat_avg]
            elif "ext" in oo:
                rhat_ext = self.summary_df.R_hat.max()
                ret += [d_close(rhat_ext, thres),rhat_ext]
        return ret
        #else:
        #    print("Error: option for rhat must be \"avg\" or \"max\"")
        #    exit(0)

    def ess_n(self, thres=thres_dict["ess_n"], opt=["avg"]):
        import re
        ret = []
        with open(self.summary_file, 'r') as f:
            text=f.read()
            matches = re.findall("(?<=iter=\()\d+", text)
            iters_n = int(matches[0])
        ret = []
        for oo in opt:
            if "av" in oo:
                ess_avg = self.summary_df.N_Eff.mean()
                ess_avg_n = ess_avg/iters_n
                ret += [p_close(ess_avg_n, thres),ess_avg_n]
            elif "ext" in oo:
                ess_ext = self.summary_df.N_Eff.min()
                ess_ext_n = ess_ext/iters_n
                ret += [p_close(ess_ext_n, thres),ess_ext_n]
        return ret
        #else:
        #    print("Error: option for ess must be \"avg\" or \"max\"")
        #    exit(0)

    def diagnostics(self, opt = "avg"):
        return ",".join([str(vv) for vv in self.runtime_df.Mean.values])

    def param_mean(self):
        return ",".join([str(vv) for vv in self.summary_df.Mean.values])


class Stan_CSV:
    def __init__(self, csv_file):
        try:
            csv_df = pd.read_csv(csv_file,comment='#')
        except:
            csv_df = pd.DataFrame()
        csv_df.drop([xx for xx in list(csv_df) if "__" in xx], axis=1, inplace=True)
        csv_df = csv_df.loc[:, csv_df.mean().apply(np.isfinite)]
        self.csv_df = csv_df[-args.warmup:]

class Stan_CSV_chains:
    def __init__(self, csv_files):
        self.csv_dfs = []
        for ff in csv_files:
            try:
                csv_df = pd.read_csv(ff,comment='#')
            except:
                csv_df = pd.DataFrame()
            csv_df.drop([xx for xx in list(csv_df) if "__" in xx], axis=1, inplace=True)
            csv_df = csv_df.loc[:, csv_df.mean().apply(np.isfinite)]
            self.csv_dfs.append(csv_df)

    def concat_dfs(self, warmup=0, iters=-1, last=-1):
        csv_dfs = []
        for cc in self.csv_dfs:
            if iters == -1:
                csv_dfs.append(cc[warmup:])
            else:
                if last == -1:
                    csv_dfs.append(cc[warmup:warmup+iters])
                else:
                    full_cc = cc[warmup:warmup+iters]
                    csv_dfs.append(full_cc[-last:])
        self.csv_df = pd.concat(csv_dfs)
        if not args.sample_size:
            self.csv_dfs = []

    def get_size(self):
        return len(self.csv_df.index)

    def resize(self, length):
        # resize by taking the LAST #length samples
        self.csv_df = self.csv_df[-length:]

    def is_param_in_limit(self, param_size_limit):
        return len(list(self.csv_df)) <= param_size_limit

class Stan_data:
    def __init__(self, stan_data_file):
        r_source = r['source']
        r_source(stan_data_file)
        data_obj_list = str(r("ls()"))[4:].replace("\"","").split()
        r("rdf <- data.frame(" + ",".join(data_obj_list) + ")")
        pandas2ri.activate()
        self.data_df = r["rdf"]


def csv_metric_pyro(ref_stan, pyro_res, metrics, thresholds, opt=[], var_check=False):
    csv_df_a = ref_stan.csv_df
    param_set = (set([kk.strip() for kk in csv_df_a]))
    # remove unused params from eval
    if args.unused:
        line = args.unused.readline()
        used_list = []
        unused_list = []
        while line:
            param = line.strip()[1:]
            if "+" in line[0]:
                used_list.append(param)
            else:
                unused_list.append(param)
            line = args.unused.readline()
        param_set = [pp for pp in param_set if pp in used_list or pp.split('.')[0] in used_list]
        if len(param_set) == 0:
            return []
    result=[]
    if var_check:
        var_check_ret = False
    for param in param_set:
        data_a = csv_df_a[param]
        param_pyro = param.split('.')[0]
        if param_pyro not in pyro_res:
            #print("skipping .. " + param_pyro)
            continue
        indices=re.findall('\.', param)

        #print(param_pyro)
        if len(indices) == 0:
            data_b = getSamples(pyro_res, param_pyro, None)
        elif len(indices) == 1:
            data_b = getSamples(pyro_res, param_pyro, int(param.split('.')[1])-1 )
        else:
            # assuming 2d
            data_b = getSamples(pyro_res, param_pyro, (int(param.split('.')[1]) - 1, int(param.split('.')[2])-1))
        if 'nan' in data_b:
            continue
        #print(data_b.sample)
        dd_metric = DataDataMetric(data_a, data_b)
        # for each param a bunch of tuples
        all_result_value = dd_metric.eval_metrics(metrics, thresholds, var_check)
        if args.debug:
            print("{}: {}".format(param, all_result_value))
        result.append(all_result_value)
        if var_check and not var_check_ret:
            var_check_ret = var_check_ret or dd_metric.var_small()
    list_list_tuples = map(list, zip(*result))
    all_result_stats = []
    if var_check:
        if "kl" in metrics:
            kl_index = metrics.index("kl")
            thresholds.insert(kl_index, thresholds[kl_index])
        if "smkl" in metrics:
            kl_index = metrics.index("smkl")
            thresholds.insert(kl_index, thresholds[kl_index])
    for idx, test in enumerate(list_list_tuples):
        test_result = map(list, zip(*test))[0]
        test_stats = map(list, zip(*test))[1]
        test_name = map(list,zip(*test))[2]
        close = close_dict[test_name[0]]
        for oo in opt:
            if "ext" in oo:
                extreme = extreme_dict[test_name[0]]
                #all_result_stats.append((all(test_result), np.mean(test_stats)))
                all_result_stats.append((close(extreme(test_stats),thresholds[idx]), float(extreme(test_stats))))
            elif "av" in oo:
                all_result_stats.append((close(np.mean(test_stats),thresholds[idx]), np.mean(test_stats)))
    if var_check:
        all_result_stats.append(str([var_check_ret]))
    return all_result_stats


# csv_a, csv_b: Stan_CSV dataframes
def csv_metric(csv_a, csv_b, metrics, thresholds, opt=[], var_check=False):
    csv_df_a = csv_a.csv_df
    csv_df_b = csv_b.csv_df
    # pandas2ri.activate()
    # r.assign('a',pandas2ri.py2ri(csv_df_a))
    # r.assign('b',pandas2ri.py2ri(csv_df_b))
    # r('''
    #     print(ls())
    #     library(kernlab)
    #     ret = kmmd(data.matrix(a),data.matrix(b), alpha=0.05)
    #     print(ret)
    #     ''')
    param_set = (set([kk.strip() for kk in csv_df_a]) & set([kk.strip() for kk in csv_df_b]))
    # remove unused params from eval
    if args.unused:
        args.unused.seek(0)
        line = args.unused.readline()
        used_list = []
        unused_list = []
        while line:
            param = line.strip()[1:]
            if "+" in line[0]:
                used_list.append(param)
            else:
                unused_list.append(param)
            line = args.unused.readline()
        param_set = [pp for pp in param_set if pp in used_list or pp.split('.')[0] in used_list]
        if len(param_set) == 0:
            return []
    result = []
    if var_check:
        var_check_ret = False
    param_set = [pp for pp in param_set if ("robust_weight" not in pp and "robust_local" not in pp and "robust_const" not in pp and "robust_" not in pp and "_test" not in pp and "y_hat" not in pp)]
    for param in param_set:
        dd_metric = DataDataMetric(csv_df_a[param], csv_df_b[param])
        # for each param a bunch of tuples
        all_result_value = dd_metric.eval_metrics(metrics, thresholds, var_check)
        if args.debug:
            print("{},{}".format(param, all_result_value[0][1]))
        result.append(all_result_value)
        if var_check and not var_check_ret:
            var_check_ret = var_check_ret or dd_metric.var_small()
    csv_df_a = None
    csv_df_b = None
    list_list_tuples = map(list, zip(*result))
    all_result_stats = []
    if var_check:
        if "kl" in metrics:
            kl_index = metrics.index("kl")
            thresholds.insert(kl_index, thresholds[kl_index])
        if "smkl" in metrics:
            kl_index = metrics.index("smkl")
            thresholds.insert(kl_index, thresholds[kl_index])
    for idx, test in enumerate(list_list_tuples):
        test_result = map(list, zip(*test))[0]
        test_stats = map(list, zip(*test))[1]
        test_name = map(list,zip(*test))[2]
        close = close_dict[test_name[0]]
        for oo in opt:
            if "ext" in oo:
                extreme = extreme_dict[test_name[0]]
                #all_result_stats.append((all(test_result), np.mean(test_stats)))
                all_result_stats.append((close(extreme(test_stats),thresholds[idx]), extreme(test_stats)))
            elif "av" in oo:
                all_result_stats.append((close(np.mean(test_stats),thresholds[idx]), np.mean(test_stats)))
    if var_check:
        all_result_stats.append(str([var_check_ret]))
    return all_result_stats

    #    param_set = (set([kk.strip() for kk in dict_a.keys()]) & set([kk.strip() for kk in dict_b.keys()]))
    #    for key_a in param_set:
    #        result = {"param" : key_a}
    #        value_a = dict_a[key_a]
    #        value_b = dict_b[key_a]
    #        for metric in metrics:
    #            thres = thres_dict[metric]
    #            if isinstance(value_a, Data) and isinstance(value_b, Data):
    #                dd_metric = DataDataMetric(metric, value_a, value_b)
    #            elif isinstance(value_a, Data):
    #                dd_metric = DataDistMetric(metric, value_a, value_b)
    #            elif isinstance(value_b, Data):
    #                dd_metric = DataDistMetric(metric, value_b, value_a)
    #            # else:
    #            #     dd_metric = data_dist_metric(metric.lower(), data_a, data_b)
    #            is_close, value = dd_metric.metric(thres)
    #            result[metric + "_value"] = value
    #            result[metric + "_is_close"] = is_close
    #        if isinstance(value_a, Data):
    #            result["rhat1_value"] = dict_a[key_a].rhat
    #        if isinstance(value_b, Data):
    #            result["rhat2_value"] = dict_b[key_a].rhat
    #        df = df.append(Series(result), ignore_index=True)



# def fitted(data_str):
#     if data_str[0].strip()[0] == '[':
#         sample = [float(dd) for dd in data_str[0].strip(' []').split()]
#         try:
#             rhat = float(data_str[1])
#         except:
#             rhat = 0
#         #return Data(sample[len(sample)/2:], rhat)
#         return Data(sample[-1000:], rhat)
#     else:
#         return Dist(data_str[0].strip().lower(), [float(dd.strip(' []')) for dd in data_str[1:]])
#
# def file_to_dict(file_name):
#     with open(file_name) as f:
#         data_a_reader = csv.reader(f, delimiter='\n')
#         data_a = []
#         for data_a_str in data_a_reader:
#             data_a.extend(data_a_str)
#     dict_a = {}
#     for aa in data_a:
#         aa_split = aa.split(',')
#         dict_a[aa_split[0].strip().lower().replace("[","_").replace("]","")] = fitted(aa_split[1:])
#     list(dict_a)[0]
#     return dict_a


def parse_pyro_samples(samplesfile):
    import ast
    data = {}
    file = open(samplesfile).read().splitlines()
    for f in file:
        name = f.split(':')[0]
        samples = f.split(':')[1]
        cur_arr = np.array(ast.literal_eval(samples.replace('nan', '\"nan\"').replace('inf', "\"inf\"")))
        data[name] = cur_arr
    return data


def getSamples(data, name, indices):
    # e.g getSamples('sigma', None) -- scalar
    # e.g getSamples('sigma', 1) -- 1d
    # e.g getSamples('sigma', (2,1)) -- 2d array
    try:
        if indices is None:
            samples = [x[0] for x in data[name]]
        elif type(indices) == np.int or len(indices) == 1:
            d = data[name]
            samples = [x[indices] for x in d]
        elif len(indices) == 2:
            d = data[name]
            samples = [x[indices[0]][indices[1]] for x in d]
        else:
            samples = []
    except Exception as e:
        samples = ['nan']*1000

    return samples

if __name__ == "__main__":
    pp = argparse.ArgumentParser()
    pp.add_argument("-fc", "--csv_file", action="append", default=[],
            help="CSV data file(s) to use")
    pp.add_argument("-fs", "--summary_file", action="append", default=[],
            help="Stan summary file(s) to use")
    pp.add_argument("-ft", "--truth_file", action="append", default=[],
            help="True value to compare")
    pp.add_argument("-fm", "--min_files", action="append", default=[],
            help="CSV data file(s) for minimum iters in .gz")
    pp.add_argument("-fr", "--ref_files", action="append", default=[],
            help="CSV data file(s) for 100000 iters in .gz")
    pp.add_argument("-fp", "--param_file", action="append", default=[],
            help="Formatted param file(s) with samples and rhat")
    pp.add_argument("-fpyro", "--pyro_file", action="append", default=[],
            help="Samples file in pyro")
    pp.add_argument("-fdata", "--stan_data_file", type=str,
            help="Stan .data.R file used to compare with posterior \
                    prediction")
    pp.add_argument("-c", action="store_true", default=False,
            dest="conv", help="Calculate convergence metrics instead of \
                    accuracy metrics")
    pp.add_argument("-btosize", action="store_true", default=False,
            dest="before_to_size", help="Maximum samples before timeout")
    pp.add_argument("-m", "--metric", action="append", default=[],
            help="Metric to calculate.\n If CSV file is provided, the metric\
                    must be one from {t, ks, kl, smkl, hell[inger]; \n\
                    If Stan summary file is provided, the metric must be one\n\
                    from {rhat, ess}.")
    pp.add_argument("-t", "--threshold", action="append", default=[],
            help="Set customer threshold")
    pp.add_argument("-o", "--option", action="append", default=[],
            help="Take the average value or extreme value among all the params\n\
                    must be one from {avg,ext}\n\
                    output would be in the order m1_o1,m1_o2,m2_o1,m2_o2")
    pp.add_argument("-s", "--sample_size", action="append", default=[],
            help="Only use the first #iters from the minimum .gz file\n\
                    with warmup removed.\n\
                    If multiple sample size is calculated, must provide them\n \
                    in a descending order!")
    pp.add_argument("-w", "--warmup", type=int, default=0,
            help="Delete the warmup samples from all .gz files")
    pp.add_argument("-l", "--last", type=int, default=-1,
            help="Only take the last number of samples for comparison")
    pp.add_argument("-rt", "--runtime", action="store_true", default=False,
            help="Calculate runtime features from Stan summary file")
    pp.add_argument("-rb", "--robust", action="store_true", default=False,
            help="Extract param mean from Stan summary file by removing\n\
                    aux robust params, also can be used to compare MCMC with vb")
    pp.add_argument("-agg", "--aggregate", action="store_true", default=False,
            help="print average difference of Mean and StdDev")
    pp.add_argument("-vc", "--var_check", action="store_true", default=False,
            help="Add check for small variance but similar mean value")
    pp.add_argument("-d", "--debug", action="store_true", default=False,
            help="Print the metric result for each parameter")
    pp.add_argument("-u", "--unused",
            help="File contains unused parameters. Unused paramters are\
                    ignored in metrics calucation")
    pp.add_argument("-ps", "--param_size_limit", type= int, default=np.inf,
            help="Skip files with more than limit params" )
    args = pp.parse_args()
    args.metric = [mm[:4] for mm in args.metric]
    if len(args.option) == 0:
        args.option = ["avg"]
    if args.conv:
        if args.summary_file:
            # ./metrics_0301.py -c -fs summary_100000 -m rhat
            data_file_a = args.summary_file[0]
            if not args.runtime and not args.robust:
                summary = Summary(data_file_a)
                rhat_ess_ret = []
                if "rhat" in args.metric:
                    if len(args.threshold) == 0:
                        rhat_ess_ret.append(str(summary.rhat(opt=args.option))[1:-1])
                    else:
                        rhat_ess_ret.append(str(summary.rhat(thres=float(args.threshold[0]), opt=args.option))[1:-1])
                if "ess" in args.metric:
                    rhat_ess_ret.append(str(summary.ess_n(opt=args.option))[1:-1])
                if len(rhat_ess_ret) != 0:
                    print(", ".join(rhat_ess_ret))
            elif args.runtime:
                summary = Summary(data_file_a, runtime=True)
                rhat_ess_ret = []
                if len(args.threshold) == 0:
                    rhat_ess_ret.append(str(summary.rhat(opt=args.option))[1:-1])
                else:
                    rhat_ess_ret.append(str(summary.rhat(thres=float(args.threshold[0]),opt=args.option))[1:-1])
                rhat_ess_ret.append(str(summary.ess_n(opt=args.option))[1:-1])
                metrics = list(summary.runtime_df)
                rhat_ess_ret.append(summary.diagnostics())
                if len(rhat_ess_ret) != 0:
                    print(", ".join(rhat_ess_ret))
            elif args.robust:
                if args.truth_file:
                    # $metrics_file -c -fs $input_file_path/rw_summary_${min}_n -ft truth_file -rb
                    summary_a = Summary(data_file_a, robust=True)
                    true_a = Truth(args.truth_file[0])
                    st_metric = SummTrueMetric(summary_a,true_a)
                    #st_metric.param_true_diff()
                    ret = []
                    for mm in args.metric:
                        if "mse" == mm:
                            try:
                                ret.append(st_metric.y_mse())
                            except:
                                ret.append(np.nan)
                        elif "pam" == mm:
                            ret.append(st_metric.y_pam())
                        elif "pr2" == mm:
                            try:
                                ret.append(st_metric.y_pr2())
                            except:
                                ret.append(np.nan)
                        elif "pl1" == mm:
                            try:
                                ret.append(st_metric.y_pl1())
                            except:
                                ret.append(np.nan)
                        elif "mad" == mm:
                            ret.append(st_metric.y_mad())
                        elif "wass" == mm:
                            ret.append(st_metric.y_wass())
                        elif "rhat" == mm:
                            ret.append(st_metric.y_rhat())
                        elif "rmax" == mm:
                            ret.append(st_metric.y_rmax())
                        elif "lik" == mm:
                            ret.append(st_metric.y_lik())
                    print(",".join([str(rr) for rr in ret]))

                else:
                    # $metrics_file -c -fs $input_file_path/rw_summary_${min} -fs $input_file_path/rw_summary_${min}_n -rb
                    summary_a = Summary(data_file_a, robust=True)
                    summary_b = Summary(args.summary_file[1], robust=True)
                    ss_metric = SummSummMetric(summary_a,summary_b)
                    if args.aggregate:
                        ss_metric.param_mean_diff_agg()
                    else:
                        ss_metric.param_mean_diff()
                # rhat_ess_ret = []
                # rhat_ess_ret.append(summary_a.param_mean())
                # if len(rhat_ess_ret) != 0:
                #     print(", ".join(rhat_ess_ret))

            #data_file_a = args.summary_file[0]
            #else:
            #    args.me

    else:
        if args.csv_file:
            # ./metrics_0301.py -fc output_1000.csv -fc output_100000_thin.csv -m t
            data_file_a = args.csv_file[0]
            data_file_b = args.csv_file[1]
            if len(args.threshold) > 0:
                if len(args.threshold) != len(args.metric):
                    print("Error: threshold not specified for every metric")
                    exit(0)
                try:
                    thresholds = map(float, args.threshold)
                except:
                    print("Error: invalid threshold")
                    exit(0)
            else:
                thresholds = [thres_dict[mm] for mm in args.metric]
            stan_csv_a = Stan_CSV(data_file_a)
            stan_csv_b = Stan_CSV(data_file_b)
            metric_ret = csv_metric(stan_csv_a, stan_csv_b, args.metric, thresholds, args.option, args.var_check)
            if (len(metric_ret) != 0):
                print(", ".join([str(mm)[1:-1] for mm in metric_ret]))
        elif args.ref_files and args.min_files:
            if len(args.threshold) > 0:
                if len(args.threshold) != len(args.metric):
                    print("Error: threshold not specified for every metric")
                    exit(0)
                try:
                    thresholds = map(float, args.threshold)
                except:
                    print("Error: invalid threshold")
                    exit(0)
            else:
                thresholds = [thres_dict[mm] for mm in args.metric]
            stan_csv_min = Stan_CSV_chains(args.min_files)
            stan_csv_min.concat_dfs(warmup=args.warmup)
            if not stan_csv_min.is_param_in_limit(args.param_size_limit):
                exit(0)
            stan_csv_ref = Stan_CSV_chains(args.ref_files)
            stan_csv_ref.concat_dfs(warmup=args.warmup)
            timeout_size = stan_csv_ref.get_size()
            if args.before_to_size:
                timeout_size_str = str(timeout_size) + ","
            else:
                timeout_size_str = ""
            if args.sample_size:
                for ss in args.sample_size:
                    ss_int = int(ss)
                    stan_csv_min.concat_dfs(warmup=args.warmup,iters=ss_int, last=args.last)
                    stan_csv_ref.resize(stan_csv_min.get_size())
                    metric_ret = csv_metric(stan_csv_ref, stan_csv_min, args.metric, thresholds, args.option, args.var_check)
                    if (len(metric_ret) != 0):
                        print(timeout_size_str +  ss + "," +  ", ".join([str(mm)[1:-1] for mm in metric_ret]))
            else:
                # stan_csv_min.concat_dfs(warmup=args.warmup)
                stan_csv_ref.resize(stan_csv_min.get_size())
                metric_ret = csv_metric(stan_csv_ref, stan_csv_min, args.metric, thresholds, args.option, args.var_check)
                if (len(metric_ret) != 0):
                    print(timeout_size_str + ", ".join([str(mm)[1:-1] for mm in metric_ret]))
        elif args.ref_files and args.pyro_file:
            if len(args.threshold) > 0:
                if len(args.threshold) != len(args.metric):
                    print("Error: threshold not specified for every metric")
                    exit(0)
                try:
                    thresholds = map(float, args.threshold)
                except:
                    print("Error: invalid threshold")
                    exit(0)
            else:
                thresholds = [thres_dict[mm] for mm in args.metric]
            stan_csv_ref = Stan_CSV_chains(args.ref_files)
            stan_csv_ref.concat_dfs(args.warmup)
            stan_csv_ref.resize(1000)
            pyro_results = parse_pyro_samples(args.pyro_file[0])
            metric_ret = csv_metric_pyro(stan_csv_ref, pyro_results, args.metric, thresholds, args.option, args.var_check)
            if len(metric_ret) != 0:
                print(", ".join([str(mm)[1:-1] for mm in metric_ret]))
        elif args.stan_data_file: # and args.min_files:
            stan_csv_min = Stan_CSV_chains(args.min_files)
            stan_csv_min.concat_dfs(warmup=args.warmup)
            stan_data = Stan_data(args.stan_data_file)
            if not args.metric:
                metric_ret = DataPredMetric(stan_data.data_df, stan_csv_min.csv_df)
            else:
                metric_ret = DataLPMLMetric(stan_data.data_df, stan_csv_min.csv_df)
            if (len(metric_ret) != 0):
                print(",".join([str(rr) for rr in metric_ret]))
        if args.unused:
            args.unused.close()

