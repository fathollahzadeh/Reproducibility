import pandas as pd
import os.path
import warnings

warnings.filterwarnings('ignore')

def r_bind_dfs(df_left, df_right):
    data = pd.merge(df_left, df_right, how='left',left_on=["query_id"],right_on=['query_id'])
    return data  

def read_results(path):
    df = pd.read_csv(path, low_memory=False, encoding='utf-8')  
    min_start_time = df['start_time'].min()
    df["start_time"] = (df['start_time'] - min_start_time) * 1000
    df["execution_start_time"] = df['start_time'] + df['execution_time']
      
    return df

def mergse_dfs(df_base, df_new):
    if len(df_new) > 0:
        for index, row in df_new.iterrows():
            df_base.loc[len(df_base)] = row 
    return df_base

def avg_results(df):
    df_start_time = df.groupby(['query_id'])['start_time'].mean()
    df_planning_time = df.groupby(['query_id'])['planning_time'].mean()
    df_execution_time = df.groupby(['query_id'])['execution_time'].mean()
    df_execution_start_time = df.groupby(['query_id'])['execution_start_time'].mean()
    
    df_start_time = pd.DataFrame({'start_time' : df_start_time}).reset_index()
    df_planning_time = pd.DataFrame({'planning_time' : df_planning_time}).reset_index()
    df_execution_time = pd.DataFrame({'execution_time' : df_execution_time}).reset_index()
    df_execution_start_time = pd.DataFrame({'execution_start_time' : df_execution_start_time}).reset_index()


    min_start_time = df_start_time["start_time"].min() 
    df_start_time["start_time"] = df_start_time["start_time"] - min_start_time   

    data = r_bind_dfs(df_left=df_start_time, df_right=df_planning_time)
    data = r_bind_dfs(df_left=data, df_right=df_execution_time)
    data = r_bind_dfs(df_left=data, df_right=df_execution_start_time)    

    data["workload_time"] = data["start_time"] + data["planning_time"] + data["execution_time"]
    data["workload_time"] = data["workload_time"].max()
    
    return data


def add_statistics(df_statistics, data, dataset_name, baseline, dbms, llm):
   
    df_results = data.sort_values(by='execution_time', ascending=True).reset_index(drop=True)
    n_queries = len(df_results)
    ratio = [0.25,0.5,0.75,0.95, 0.99,1.0]
    for r in ratio:
        count = int(r * n_queries)
        df = df_results[:count]
        df["ratio_time"] = df["start_time"] + df["planning_time"] + df["execution_time"] 
        elapsed_time = df["ratio_time"].max() / 1000
        if dbms == "DuckDB" and r<=0.5:
            df_statistics.loc[len(df_statistics)] = [dataset_name, dbms, llm, n_queries, count, float(r), baseline, f"{elapsed_time:.2f}"] 
        else:
             df_statistics.loc[len(df_statistics)] = [dataset_name, dbms, llm, n_queries, count, float(r), baseline, f"{int(elapsed_time)}"] 

        if r == 1 :
          median_time = df["ratio_time"].median() / 1000
          elapsed_time = (df["ratio_time"].max() / len(data)) / 1000
          df_statistics.loc[len(df_statistics)] = [dataset_name, dbms, llm, n_queries, count, "mean", baseline, f"{elapsed_time:.2f}"] 
          df_statistics.loc[len(df_statistics)] = [dataset_name, dbms, llm, n_queries, count, "median", baseline, f"{median_time:.2f}"] 

    return df_statistics


def r_bind_dfs_speed(df_left, left_time, df_right, right_time, ratio):
    import numpy as np
    data = pd.merge(df_left, df_right, how='left',left_on=["query_id"],right_on=['query_id'])
    # data['diff'] = (data[f"{left_time}_x"]+ data["start_time_x"]+ data["planning_time_x"]) - (data[f"{right_time}_y"]+ data["start_time_y"]+ data["planning_time_y"])

    data['diff'] = data[f"{left_time}_x"] - data[f"{right_time}_y"] * ratio
    # data['diffratio'] = (data[f"{right_time}_x"] -  data[f"{left_time}_y"])/ data[f"{left_time}_x"] * 100 

    data['diffratio'] = np.where(
            data['diff'] >= 0,           # faster or same
            data[f"{left_time}_x"] /data[f"{left_time}_y"],         # how many × faster
            -1*data[f"{left_time}_y"] / data[f"{left_time}_x"]          # how many × slower
        ).round(2)

    df_diff_positive = data.loc[(data['diff'] >= 0)].reset_index()
    df_diff_positive = df_diff_positive.drop('index', axis=1)

    df_diff_negative = data.loc[(data['diff'] < 0)].reset_index()   
    df_diff_negative = df_diff_negative.drop('index', axis=1) 

    data['PN'] = data['diff'] >=0
    
    return data, df_diff_positive, df_diff_negative


def calac_speed(dataset_name: str, dbms, llm_model: str, dfs, final_path):   
    key_1 = f"{dbms}_{dataset_name}"
    key_2 = f"{dbms}_{dataset_name}_{llm_model}"

    ds_dbms,_,_ = r_bind_dfs_speed(df_left=dfs[key_1], left_time="execution_time", df_right=dfs[key_2], right_time="execution_time", ratio=1)
    df = pd.DataFrame(columns=ds_dbms.columns)
    
    df = ds_dbms.sort_values("diff", ascending=True).reset_index()
    df = df.drop(['index'], axis=1)

    fname = f"{final_path}/Experiment2_{dbms}_{dataset_name}_{llm_model}-Speed-R10.dat"
    df.to_csv(fname, index=True, index_label="index" ) 



if __name__ == '__main__':
    
    method_ID = {"": 0, "_gemini-2.5-pro":1}
    root_path = "../raw-results"
    final_path= "../results"
    dbms = ["SparkSQL"]  
    workload = ["stats", "stats_ceb", "imdb", "tpch"] #"stackoverflow","publicbibenchmark",, "dsb", "imdb_13k"
    llms = ["", "_gemini-2.5-pro"]

    df_statistics = pd.DataFrame(columns=["dataset_name","dbms","llm","total_queries","count" ,"ratio","baseline","time"]) 
    dfs = dict()
    
    for dbm in dbms:
      for llm in llms:  
        for wl in workload:
            df_exp2 = None
            for it in range(2, 6):
                fname_exp2 = f"{root_path}/{wl}/Experiment1_{dbm}_{wl}{llm}-{it}.dat"
                if os.path.exists(fname_exp2):
                    df_tmp = read_results(path=fname_exp2)
                    if df_exp2 is None:
                        df_exp2 = df_tmp
                    else:
                        df_exp2 = mergse_dfs(df_base=df_exp2, df_new=df_tmp)
                    
                
            if df_exp2 is not None and len(df_exp2) > 0:         
                df_exp2 = avg_results(df=df_exp2)
                exe2_fname = f"{final_path}/Experiment1-{wl}-{dbm}{llm}-R10.dat" 
                  
                df_exp2 = df_exp2.sort_values(by='start_time', ascending=True).reset_index(drop=True)                
                df_statistics = add_statistics(df_statistics=df_statistics, dbms=dbm, data=df_exp2,dataset_name=wl, baseline=dbm, llm=llm)
                df_exp2["ID"] = method_ID[llm]
                df_exp2.to_csv(exe2_fname, index=True, index_label="index")   

                key = f"{dbm}_{wl}{llm}"
                dfs[key] = df_exp2             

    exe2_statistics_fname = f"{final_path}/Experiment1-Statistics-R10.dat"
    df_statistics.to_csv(exe2_statistics_fname, index=True, index_label="index")

    calac_speed(dataset_name="imdb", dbms='SparkSQL', llm_model='gemini-2.5-pro', dfs=dfs, final_path=final_path)
       
    calac_speed(dataset_name="tpch", dbms='SparkSQL', llm_model='gemini-2.5-pro', dfs=dfs, final_path=final_path)
    
    # calac_speed(dataset_name="dsb", dbms='SparkSQL', llm_model='gemini-2.5-pro', dfs=dfs, final_path=final_path)
    
    calac_speed(dataset_name="stats", dbms='SparkSQL', llm_model='gemini-2.5-pro', dfs=dfs, final_path=final_path)
   
    calac_speed(dataset_name="stats_ceb", dbms='SparkSQL', llm_model='gemini-2.5-pro', dfs=dfs, final_path=final_path)
        
    # calac_speed(dataset_name="stackoverflow", dbms='SparkSQL', llm_model='gemini-2.5-pro', dfs=dfs, final_path=final_path)

    # calac_speed(dataset_name="publicbibenchmark", dbms='SparkSQL', llm_model='gemini-2.5-pro', dfs=dfs, final_path=final_path)
    
    # calac_speed(dataset_name="imdb_13k", dbms='SparkSQL', llm_model='gemini-2.5-pro', dfs=dfs, final_path=final_path)
    
    # calac_speed(dataset_name="publicbibenchmark", dbms='SparkSQL', llm_model='gemini-2.5-pro', dfs=dfs, final_path=final_path)
    
