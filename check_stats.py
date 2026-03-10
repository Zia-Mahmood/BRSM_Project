import pandas as pd

path = r'd:\IIITH\SEM 4\BRSM\Project\analysis\output\full_data.csv'
df = pd.read_csv(path)
print('n', len(df))
print('gender counts', df['gender'].value_counts(dropna=False).to_dict())
print('age mean sd', df['age'].mean(), df['age'].std())
print('phq mean sd median min max', df['score_phq'].mean(), df['score_phq'].std(), df['score_phq'].median(), df['score_phq'].min(), df['score_phq'].max())
print('gad mean sd', df['score_gad'].mean(), df['score_gad'].std())
print('stai mean sd', df['score_stai_t'].mean(), df['score_stai_t'].std())
print('vrise mean sd', df['score_vrise'].mean(), df['score_vrise'].std())
print('phq>=5 count', (df['score_phq']>=5).sum(), 'phq<5', (df['score_phq']<5).sum())

df_less = df[df['score_phq'] < 5]
df_ge = df[df['score_phq'] >= 5]
print('phq<5 n', len(df_less), 'phq mean', df_less['score_phq'].mean(), 'gad mean', df_less['score_gad'].mean(), 'stai mean', df_less['score_stai_t'].mean())
print('phq>=5 n', len(df_ge), 'phq mean', df_ge['score_phq'].mean(), 'gad mean', df_ge['score_gad'].mean(), 'stai mean', df_ge['score_stai_t'].mean())

for v in range(1, 6):
    col = f'mean_speed_v{v}'
    print('v', v, 'mean speed', df[col].mean(), 'sd', df[col].std())

print('missing mean speed v5', df['mean_speed_v5'].isna().sum())
