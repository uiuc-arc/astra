#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import sys
from os.path import abspath

df = pd.read_csv(sys.argv[1])
# df = df[df.rhat <= 1.5]
# df = df[df.rmax <= 3]
mean_df = df.mean(axis=0).to_frame().T
for mm in list(df):
    if "max" in mm:
        maxmm = mm
        mean_df[mm] = df[mm].max()
    elif "time" in mm:
        timemm = mm
        mean_df[mm] = mean_df[mm] * 4

print(mean_df.to_csv(index=False)) # [df<10000000]
