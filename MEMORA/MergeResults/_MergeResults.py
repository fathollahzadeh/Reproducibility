import pandas as pd
import os.path
import warnings

warnings.filterwarnings('ignore')

def r_bind_dfs(df_left, df_right):
    data = pd.merge(df_left, df_right, how='left',left_on=["baseline", 's'],right_on=["baseline", 's'])
    return data  

def read_results(path):
    df = pd.read_csv(path, low_memory=False, encoding='utf-8')  
    return df

def mergse_dfs(df_base, df_new):
    if len(df_new) > 0:
        for index, row in df_new.iterrows():
            df_base.loc[len(df_base)] = row 
    return df_base

def avg_results(df):
    df_time = df.groupby(['baseline','s'])['time'].mean()    
    df = pd.DataFrame({'time' : df_time}).reset_index()    
    return df



if __name__ == '__main__':
    
    root_path = "../raw-results"
    final_path= "../final-results"
    baselines = ["SystemDS","TorchFX", "TVM","JAX"] 
    
    df_raw_compute = read_results(f"{root_path}/TASK1.dat")
    df_raw_read = read_results(f"{root_path}/TASK1_Read.dat")
    df_compute = avg_results(df_raw_compute)
    df_read = avg_results(df_raw_read)

    df_compute = r_bind_dfs(df_left=df_compute, df_right=df_read)
    df_compute['time'] = df_compute['time_x']-df_compute['time_y']
    df_compute['task'] = 'task1'

    print(df_compute)

    df_compute.to_csv(f"{final_path}/task1.csv", index=False, index_label="index")

    