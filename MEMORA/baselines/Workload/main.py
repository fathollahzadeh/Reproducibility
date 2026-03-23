from argparse import ArgumentParser
from Config import load_config
from RunWorkload import WorkloadPG, WorkloadDuckDB, WorkloadMySQL

def parse_arguments():
    parser = ArgumentParser()
    parser.add_argument('--workload-path', type=str, default="/tmp/")
    parser.add_argument('--database-name', type=str, default="test")
    parser.add_argument('--database-path', type=str, default="test.duckdb")
    parser.add_argument('--dbms', type=str, default="postgresql")
    parser.add_argument('--iterations', type=int, default=5)
    parser.add_argument('--query-log-path', type=str, default="/tmp/")
    parser.add_argument('--output-path', type=str, default="/tmp/output.csv")

    args = parser.parse_args()
    return args


if __name__ == '__main__':
    args = parse_arguments()

    workload_dbms = None
    if args.dbms == "PostgreSQL":
        workload_dbms = WorkloadPG

    elif args.dbms == "DuckDB":
        workload_dbms = WorkloadDuckDB

    elif args.dbms == "MySQL":
        workload_dbms = WorkloadMySQL

    # for iteration in range(1, args.iterations+1):
    load_config(dbms=args.dbms, dataset_name=args.database_name, workload_path=args.workload_path, database_path=args.database_path)
    from Config import _work_load

    wl = workload_dbms(workload_path=args.workload_path, queries=_work_load, database_name=args.database_name,
                      dbms=args.dbms, query_log_path=args.query_log_path, output_path=args.output_path)
    wl.run(iteration=args.iterations)
