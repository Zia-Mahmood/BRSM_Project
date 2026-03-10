import pandas as pd
from scipy import stats
import numpy as np

path = r'd:\IIITH\SEM 4\BRSM\Project\analysis\output\full_data.csv'
df = pd.read_csv(path)
mean_speed_cols = [f'mean_speed_v{i}' for i in range(1, 6)]
df['mean_speed_avg'] = df[mean_speed_cols].mean(axis=1)

r, p = stats.pearsonr(df['score_phq'], df['mean_speed_avg'])
print('pearson phq vs mean_speed_avg', r, p)

low = df[df['score_phq'] < 5]['mean_speed_v5'].dropna()
high = df[df['score_phq'] >= 5]['mean_speed_v5'].dropna()
print('low mean', low.mean(), 'high mean', high.mean())

# Welch t-test
t, p = stats.ttest_ind(low, high, equal_var=False)
print('t-test (unequal var) p', p, 't', t)

# Cohen's d
def cohen_d(x, y):
    nx, ny = len(x), len(y)
    dof = nx + ny - 2
    pooled_var = ((nx - 1) * x.var(ddof=1) + (ny - 1) * y.var(ddof=1)) / dof
    return (x.mean() - y.mean()) / np.sqrt(pooled_var)

print('cohen d', cohen_d(low, high))
