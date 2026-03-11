import os
import time
import glob
from pyspark.sql import SparkSession
from argparse import ArgumentParser
import yaml
from Config import load_config
from FileHandler import read_text_file_line_by_line
from LogResults import LogWorkloadResults


def parse_arguments():
    parser = ArgumentParser()
    parser.add_argument('--dataset-name', type=str, default=None)
    parser.add_argument('--data-path', type=str, default=None)
    parser.add_argument('--workload-path', type=str, default=None)
    parser.add_argument('--output-path', type=str, default=None)
    parser.add_argument('--iteration', type=int, default=None)

    
    args = parser.parse_args()
    if args.dataset_name is None:
        raise Exception("--dataset-name is a required parameter!")
    return args


def load_spark_config(config_path: str) -> dict:
    """Reads and parses the YAML configuration file."""
    with open(config_path, 'r') as file:
        return yaml.safe_load(file)

def init_spark_from_config(spark_config: dict) -> SparkSession:
    """
    Initializes a Spark session dynamically based on a parsed YAML dictionary.
    """
    app_name = spark_config.get("app_name", "Default_Benchmark")
    master = spark_config.get("master", "local[*]")
    
    builder = SparkSession.builder \
        .appName(app_name) \
        .master(master)
        
    # Iterate through the 'configs' section and apply them
    advanced_configs = spark_config.get("configs", {})
    for conf_key, conf_value in advanced_configs.items():
        builder = builder.config(conf_key, str(conf_value))
        
    return builder.getOrCreate()


def register_parquet_tables(spark: SparkSession, data_dir: str):
    """
    Scans the data directory for Parquet files/folders and registers them as temporary views.
    Assumes each folder or file name corresponds to the table name (e.g., 'customer.parquet').
    """
    print(f"--- Registering Tables from {data_dir} ---")
    
    # Identify directories or .parquet files
    table_paths = glob.glob(os.path.join(data_dir, "*"))
    
    for path in table_paths:
        # Extract table name from the folder or file name
        base_name = os.path.basename(path)
        table_name = base_name.replace(".parquet", "").lower()
        
        try:
            df = spark.read.parquet(path)
            df.createOrReplaceTempView(table_name)
            print(f"Registered table: {table_name}")
        except Exception as e:
            print(f"Skipped {path}: Not a valid parquet format or empty. Error: {e}")

def load_and_execute_workload(spark: SparkSession, workload_dir: str, queries, iteration: int, output_path: str): 

    log = LogWorkloadResults()    

    for query in queries:
        query_fname = f"{workload_dir}/{query}.sql"
        query_str = read_text_file_line_by_line(query_fname)
        start_time = time.time()

        try:
            # Using 'noop' forces full execution of the physical plan 
            # without the overhead of disk I/O for saving results or driver OOMs.
            spark.sql(query_str).write.format("noop").mode("overwrite").save()
            
            end_time = time.time()
            execution_time = end_time - start_time
            print(f"Success: {query} completed in {execution_time:.2f} seconds.")
            
        except Exception as e:
            execution_time = -1.0
            print(f"Failed: {query}. Error: {str(e)[:200]}...")

        result = {"query_id": query, "dbms":"SparkSQL", "iteration": iteration ,"start_time": start_time,
                      "planning_time": 0, "execution_time": execution_time}
        
        log.save_results_query_by_query(result, f"{output_path}-{iteration}.dat")
     

    # results = []

    # for file_path in query_files:
    #     query_name = os.path.basename(file_path)
        
    #     with open(file_path, 'r') as file:
    #         query = file.read()

    #     if "select" not in query.lower():
    #         continue     
    #     print(f"Running {query_name}...")

        
    #     start_time = time.time()
        
    #     try:
    #         # Using 'noop' forces full execution of the physical plan 
    #         # without the overhead of disk I/O for saving results or driver OOMs.
    #         spark.sql(query).write.format("noop").mode("overwrite").save()
            
    #         end_time = time.time()
    #         execution_time = end_time - start_time
    #         print(f"Success: {query_name} completed in {execution_time:.2f} seconds.")
            
    #     except Exception as e:
    #         execution_time = -1.0
    #         print(f"Failed: {query_name}. Error: {str(e)[:200]}...")

    #     results.append({
    #         "query": query_name,
    #         "time_seconds": execution_time
    #     })

    # # Summary Report
    # print("\n--- Benchmark Summary ---")
    # for res in results:
    #     status = f"{res['time_seconds']:.2f} s" if res['time_seconds'] >= 0 else "FAILED"
    #     print(f"{res['query']}: {status}")

if __name__ == "__main__":
    args = parse_arguments()

    config_path = "benchmark_config.yaml"
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"Configuration file {config_path} not found.")
    
    load_config(dataset_name=args.dataset_name, workload_path=args.workload_path)
    from Config import _work_load

    config_data = load_spark_config(config_path)
    
    # 2. Ensure Spark spill directory exists (optional, defaults to OS temp)
    os.makedirs("/tmp/spark-spill", exist_ok=True)
    
    # 3. Run Benchmark Pipeline
    spark = init_spark_from_config(config_data['spark'])
    
    try:
        register_parquet_tables(spark, args.data_path)
        load_and_execute_workload(spark=spark, workload_dir=args.workload_path, queries=_work_load, iteration=args.iteration, output_path=args.output_path)
    finally:
        time.sleep(2)
        spark.stop()