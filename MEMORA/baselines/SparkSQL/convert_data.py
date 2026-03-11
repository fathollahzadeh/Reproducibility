from argparse import ArgumentParser
import os
import glob
import duckdb

def parse_arguments():
    parser = ArgumentParser()
    parser.add_argument('--dataset-name', type=str, default=None)
    parser.add_argument('--data-path', type=str, default=None)
    parser.add_argument('--target-path', type=str, default=None)
    parser.add_argument('--schema-path', type=str, default=None)
   
    args = parser.parse_args()
    if args.dataset_name is None:
        raise Exception("--dataset-name is a required parameter!")
    return args


if __name__ == "__main__":
    args = parse_arguments()

        # Find all .tbl or .csv files
    file_patterns = [os.path.join(args.data_path, "*.tbl"), os.path.join(args.data_path, "*.csv")]
    source_files = []
    for pattern in file_patterns:
        source_files.extend(glob.glob(pattern))
        
    con = duckdb.connect()

    # install and load postgres extension
    con.execute("INSTALL postgres")
    con.execute("LOAD postgres")

    # connection string
    conn = f"host=localhost port=5432 dbname={args.dataset_name} user=postgres password=postgres"

    for file_path in source_files:
        base_name = os.path.basename(file_path)
        table_name = base_name.split('.')[0]
        table_fname = f"{args.data_path}/{base_name}"
        target_path = os.path.join(args.target_path, f"{table_name}.parquet")

        # export entire table to parquet
        con.execute(f"""
        COPY (
            SELECT * 
            FROM postgres_scan('{conn}', 'public', '{table_name}')
        )
        TO '{target_path}'
        (FORMAT PARQUET, COMPRESSION ZSTD)
        """)