import pandas as pd
path = r'd:\IIITH\SEM 4\BRSM\Project\analysis\output\full_data.csv'
df = pd.read_csv(path)
print('vr_experience values', df['vr_experience'].value_counts(dropna=False).to_dict())
print('missing vr_experience', df['vr_experience'].isna().sum())
