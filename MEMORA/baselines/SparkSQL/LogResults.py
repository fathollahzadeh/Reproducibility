import pandas as pd


class LogWorkloadResults(object):
    def __init__(self):
        self.columns = ["query_id", "dbms", "iteration" ,"start_time", "planning_time", "execution_time"]
        self.df = pd.DataFrame(columns=self.columns)

    def add_result(self, result):
        if result is None:
            return
        row = [result["query_id"], result["dbms"], result["iteration"], result["start_time"], result["planning_time"], result["execution_time"]]
        self.df.loc[len(self.df)] = row

    def save_results(self, result_output_path: str):
        self.df.to_csv(result_output_path, index=False)

    def save_results_query_by_query(self, result, result_output_path: str):
        try:
            df_result = pd.read_csv(result_output_path)

        except Exception as err:
            df_result = pd.DataFrame(columns=self.columns)

        row = [result["query_id"], result["dbms"], result["iteration"], result["start_time"], result["planning_time"],
               result["execution_time"]]
        df_result.loc[len(df_result)] = row
        df_result.to_csv(result_output_path, index=False)


class LogVerifyResults(object):
    def __init__(self):
        self.columns = ["query_id", "verified_count", "failed_count" ,"error_count", "total_count", "verified_queries", "failed_queries", "error_queries","selected_query","query_elapsed_time"]
        self.df = pd.DataFrame(columns=self.columns)

    def add_results(self, query_id, results):
        if results is None:
            return

        query_times = []
        for k in results["query_elapsed_time"]:
            query_times.append(f'{k}:{results["query_elapsed_time"][k]}')
        query_times = ";".join(query_times)

        row = [query_id, len(results["verified_queries"]), len(results["failed_queries"]),len(results["error_queries"]),
                   len(results["verified_queries"])+len(results["failed_queries"])+len(results["error_queries"]),
                   ";".join(results["verified_queries"]), ";".join(results["failed_queries"]), ";".join(results["error_queries"]), results["selected_query"], query_times]
        self.df.loc[len(self.df)] = row

    def save_results(self, result_output_path: str):
        self.df.to_csv(result_output_path, index=False)