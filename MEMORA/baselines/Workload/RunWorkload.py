from Database import PostgreDB, DuckDB, MySQLDB
from FileHandler import read_text_file_line_by_line
from LogResults import LogWorkloadResults
import time
import queue
import threading
import multiprocessing


class Workload(object):
    def __init__(self, workload_path: str, queries, database_name: str, dbms: str, output_path: str, query_log_path: str):
        self.workload_path = workload_path
        self.database_name = database_name
        self.dbms = dbms
        self.output_path = output_path
        self.query_log_path = query_log_path
        self.queries = queries
        self.iteration = -1
        self.connections = dict()

        self.results_lock = threading.Lock()
        self.log = LogWorkloadResults()

    # Worker function for threads
    def _worker(self):
        while True:
            try:
                query = self.queries.get(timeout=1)
            except queue.Empty:
                break

            thread_name = threading.current_thread().name
            self._run_queries(query, thread_name)
            self.queries.task_done()

    def _run_queries(self, query, thread_name):
        pass

    def run(self, iteration: int):
        pass


class WorkloadPG(Workload):
    def __init__(self, workload_path: str, queries, database_name: str, dbms: str, output_path: str, query_log_path: str):
        Workload.__init__(self, workload_path, queries, database_name, dbms, output_path, query_log_path)

    def _run_queries(self, query, thread_name):
        (pg, conn, cursor) = self.connections[thread_name]
        query_fname = f"{self.workload_path}/{query}.sql"
        query_str = read_text_file_line_by_line(query_fname)
        start = time.time()
        res_an = pg.execute(cursor=cursor, query=f"EXPLAIN ANALYZE {query_str}")
        end = time.time()
        planning_time = 0 #float(res_an[-2][0].split(":")[-1].split("ms")[0].strip())
        execution_time = (end - start) * 1000 #float(res_an[-1][0].split(":")[-1].split("ms")[0].strip())
        result = {"query_id": query, "dbms":"PostgreSQL", "iteration": self.iteration ,"start_time": start,
                      "planning_time": planning_time, "execution_time": execution_time}
        with self.results_lock:
            # self.log.add_result(result)
            self.log.save_results_query_by_query(result, f"{self.output_path}-{self.iteration}.dat")

    def run(self, iteration: int):
        self.iteration = iteration
        number_threads = multiprocessing.cpu_count()

        # Create and start threads
        threads = []
        for i in range(number_threads):
            pg = PostgreDB()
            conn, cursor = pg.connect()
            thread_name = f"thread_{i}"
            self.connections[thread_name] = (pg, conn, cursor)
            t = threading.Thread(target=self._worker, args=(), name=thread_name)
            t.start()
            threads.append(t)

        # Wait for all tasks in the queue to be processed
        self.queries.join()

        for i, t in enumerate(threads):
            t.join()
            thread_name = f"thread_{i}"
            (pg, conn, cursor) = self.connections[thread_name]
            pg.close_connect(conn=conn, cursor=cursor)

        #self.log.save_results(f"{self.output_path}-{iteration}.dat")

class WorkloadDuckDB(Workload):
    def __init__(self, workload_path: str, queries, database_name: str, dbms: str, output_path: str, query_log_path: str):
        Workload.__init__(self, workload_path, queries, database_name, dbms, output_path, query_log_path)

    def _run_queries(self, query, thread_name):
        (ddb, conn) = self.connections[thread_name]
        query_fname = f"{self.workload_path}/{query}.sql"
        query_str = read_text_file_line_by_line(query_fname)
        start = time.time()
        res_an = ddb.execute(conn= conn,query=f"{query_str}")
        end = time.time()
        planning_time = 0 #float(res_an[-2][0].split(":")[-1].split("ms")[0].strip())
        execution_time = (end - start) * 1000 #float(res_an[-1][0].split(":")[-1].split("ms")[0].strip())
        result = {"query_id": query, "dbms":"DuckDB", "iteration": self.iteration ,"start_time": start,
                      "planning_time": planning_time, "execution_time": execution_time}
        with self.results_lock:
            self.log.add_result(result)

    def run(self, iteration: int):
        self.iteration = iteration
        number_threads = multiprocessing.cpu_count()

        # Create and start threads
        threads = []
        for i in range(number_threads):
            ddb = DuckDB()
            conn = ddb.connect(threads=1)
            thread_name = f"thread_{i}"
            self.connections[thread_name] = (ddb, conn)
            t = threading.Thread(target=self._worker, args=(), name=thread_name)
            t.start()
            threads.append(t)

        # Wait for all tasks in the queue to be processed
        self.queries.join()

        for i, t in enumerate(threads):
            t.join()
            thread_name = f"thread_{i}"
            (ddb, conn) = self.connections[thread_name]
            ddb.close_connect(conn=conn)

        self.log.save_results(f"{self.output_path}-{iteration}.dat")


class WorkloadMySQL(Workload):
    def __init__(self, workload_path: str, queries, database_name: str, dbms: str, output_path: str, query_log_path: str):
        Workload.__init__(self, workload_path, queries, database_name, dbms, output_path, query_log_path)

    def _run_queries(self, query, thread_name):
        (mysql, conn, cursor) = self.connections[thread_name]
        query_fname = f"{self.workload_path}/{query}.sql"
        query_str = read_text_file_line_by_line(query_fname)
        start = time.time()
        res_an = mysql.execute(cursor=cursor, query=query_str)
        end = time.time()
        planning_time = 0#float(res_an[-2][0].split(":")[-1].split("ms")[0].strip())
        execution_time = (end - start) * 1000 # float(res_an[-1][0].split(":")[-1].split("ms")[0].strip())
        result = {"query_id": query, "dbms":"MySQL", "iteration": self.iteration ,"start_time": start,
                      "planning_time": planning_time, "execution_time": execution_time}
        with self.results_lock:
            #self.log.add_result(result)
            self.log.save_results_query_by_query(result, f"{self.output_path}-{self.iteration}.dat")

    def run(self, iteration: int):
        self.iteration = iteration
        number_threads = multiprocessing.cpu_count()

        # Create and start threads
        threads = []
        for i in range(number_threads):
            mysql = MySQLDB()
            conn, cursor = mysql.connect()
            thread_name = f"thread_{i}"
            self.connections[thread_name] = (mysql, conn, cursor)
            t = threading.Thread(target=self._worker, args=(), name=thread_name)
            t.start()
            threads.append(t)

        # Wait for all tasks in the queue to be processed
        self.queries.join()

        for i, t in enumerate(threads):
            t.join()
            thread_name = f"thread_{i}"
            (mysql, conn, cursor) = self.connections[thread_name]
            mysql.close_connect(conn=conn, cursor=cursor)

       # self.log.save_results(f"{self.output_path}-{iteration}.dat")
