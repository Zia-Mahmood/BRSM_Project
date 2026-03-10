import pandas as pd
path = r'd:\IIITH\SEM 4\BRSM\Project\analysis\output\full_data.csv'
df = pd.read_csv(path)
print('>=10 count', (df['score_phq'] >= 10).sum(), '<10', (df['score_phq'] < 10).sum())
print('>=5 count', (df['score_phq'] >= 5).sum(), '<5', (df['score_phq'] < 5).sum())
