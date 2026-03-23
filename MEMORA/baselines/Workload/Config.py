import os
import queue
import yaml

_pgsql_user = None
_pgsql_password = None
_pgsql_host = None
_pgsql_port = None

_mysql_user = None
_mysql_password = None
_mysql_host = None
_mysql_port = None


_dbms = None
_dataset_name = None
_database_path = None

_work_load = None
_work_load_verify = None

def load_config(db_config_path: str = "DBConfig.yaml", dbms: str = "PostgreSQL", dataset_name: str = None,
                workload_path: str = None, database_path: str = None):
    global _dataset_name
    global _dbms
    global _database_path
    _database_path = database_path

    _dbms = dbms
    if "imdb" in dataset_name:
        _dataset_name = "imdb"
    elif "dsb" in dataset_name:
        _dataset_name = "dsb"
    else:
        _dataset_name = dataset_name
    load_db_config(db_config_path=db_config_path)
    load_work_load_queries(dataset_name=dataset_name, workload_path=workload_path)


def load_db_config(db_config_path: str = "DBConfig.yaml"):
    global _pgsql_user
    global _pgsql_password
    global _pgsql_host
    global _pgsql_port

    global _mysql_user
    global _mysql_password
    global _mysql_host
    global _mysql_port

    with open(db_config_path, "r") as f:
        try:
            configs = yaml.load(f, Loader=yaml.FullLoader)
            for conf in configs:
                plt = conf.get("database")
                if plt == "Postgres":
                    try:
                        _pgsql_user = conf.get("user")
                        _pgsql_password = conf.get("password")
                        _pgsql_host = conf.get("host")
                        _pgsql_port = conf.get("port")
                    except:
                        pass
                elif plt == "MySQL":
                    try:
                        _mysql_user = conf.get("user")
                        _mysql_password = conf.get("password")
                        _mysql_host = conf.get("host")
                        _mysql_port = conf.get("port")
                    except:
                        pass
        except yaml.YAMLError as ex:
            raise Exception(ex)

def load_work_load_queries(dataset_name: str = None, workload_path: str = None):
    global _work_load
    global _work_load_verify
    _work_load = queue.Queue()
    _work_load_verify = queue.Queue()

    query_ids = []
    query_ids_verify = []
    if dataset_name == "imdb":
        query_ids = ["1a", "1b", "1c", "1d", "2a", "2b", "2c", "2d", "3a", "3b", "3c", "4a", "4b", "4c", "5a", "5b",
                     "5c", "6a", "6b", "6c", "6d", "6e", "6f", "7a", "7b", "7c", "8a", "8b", "8c", "8d", "9a", "9b",
                     "9c", "9d", "10a", "10b", "10c", "11a", "11b", "11c", "11d", "12a", "12b", "12c", "13a", "13b",
                     "13c", "13d", "14a", "14b", "14c", "15a", "15b", "15c", "15d", "16a", "16b", "16c", "16d", "17a",
                     "17b", "17c", "17d", "17e", "17f", "18a", "18b", "18c", "19a", "19b", "19c", "19d", "20a", "20b",
                     "20c", "21a", "21b", "21c", "22a", "22b", "22c", "22d", "23a", "23b", "23c", "24a", "24b", "25a",
                     "25b", "25c", "26a", "26b", "26c", "27a", "27b", "27c", "28a", "28b", "28c", "29a", "29b", "29c",
                     "30a", "30b", "30c", "31a", "31b", "31c", "32a", "32b", "33a", "33b", "33c"]
        query_ids_verify = ["21b","8c","17d","5c","1a","6f","5a","1d","17b","26c","14b","32b","16d","33a","5b","29c","6d","9d","13b","31a","21a","20b","4b","18a","26a","24a","19b","15a","27a","14a","19c","15b","28b","18c","1c","14c","33b","8a","29a","6c","3b","17a","31c","22c","19a","9c","9a","10c","2a","30c","8b","22d","30b","7b","25c","7c","25a","8d","17e","13d","15d","23a","10b","30a","20c","20a","12b","11a","29b","15c","7a","10a","28a","13a","27c","25b","11c","33c","12a","11b","16c","11d","23b","26b","28c","1b","18b","24b","9b","16b","31b","27b","12c","19d"]

    elif dataset_name in {"imdb_13k"}:
        query_ids = []
        query_ids_verify = []

        for qt in ["1a", "2a", "2b", "2c", "3a", "3b", "4a", "5a", "6a", "7a", "8a", "9a", "9b", "10a", "11a", "11b"]:
            for i in range(1, 5000):
                query_fname = f"{workload_path}/{qt}{i}.sql"
                if os.path.exists(query_fname):
                    query_ids.append(f"{qt}{i}")
                    query_ids_verify.append(f"{qt}{i}")

    elif dataset_name in {"tpch"}:
        query_ids = []
        query_ids_verify = []
        for i in range(1, 23):
            query_ids.append(f"query{i}")
            query_ids_verify.append(f"query{i}")

    elif dataset_name == "dsb":
        query_ids = []
        query_ids_verify = []
        for qt in ["agg_queries", "multi_block_queries", "spj_queries"]:
            for i in range(1, 103):
                query_fname = f"{workload_path}/{qt}_query{'{0:03}'.format(i)}_0.sql"
                if os.path.exists(query_fname):
                    query_ids.append(f"{qt}_query{'{0:03}'.format(i)}_0")
                    query_ids_verify.append(f"{qt}_query{'{0:03}'.format(i)}_0")

    elif dataset_name == "dsb_s100":
        query_ids = []
        query_ids_verify = []
        for qt in ["agg_queries", "multi_block_queries", "spj_queries"]:
            for i in range(1, 103):
                for j in range(0, 100):
                    query_fname = f"{workload_path}/{qt}_query{'{0:03}'.format(i)}_{j}.sql"
                    if os.path.exists(query_fname):
                        query_ids.append(f"{qt}_query{'{0:03}'.format(i)}_{j}")
                query_ids_verify.append(f"{qt}_query{'{0:03}'.format(i)}_0")


    elif dataset_name in {"tpch_s1", "tpch_s2", "tpch_s3", "tpch_s4", "tpch_s5", "tpch_s6", "tpch_s7", "tpch_s8", "tpch_s9", "tpch_s10"}:
        query_ids = ["query18", "query17","query13","query20","query1","query22"]
        query_ids_verify = ["query18", "query17","query13","query20","query1","query22"]

    elif dataset_name in ["stats", "stats_ceb"]:
        query_ids = [f"query{i}" for i in range(1, 147)]
        query_ids_verify = [f"query{i}" for i in range(1, 147)]

    elif dataset_name == "stackoverflow":
        query_ids = []
        query_ids_verify = ["15107","19433","15188","18618","17605","19298","16505","19955","15391","16463","17669","19381","19088","18129","15428","15029","15588","16022","15156","16298","17597","17443","15923","18158","19506","10940","19231","19260","18768","18439","19416","17449","16809","17337","19101","16927","17376","16354","16145","15629","15338","15028","19476","19958","19253","18062","16797","16300","18637","16226","19110","15018","17637","15934","16124","10085","15817","17838","15008","16922"]
        for i in range(10000, 20000):
            query_fname = f"{workload_path}/{i}.sql"
            if os.path.exists(query_fname):
                query_ids.append(f"{i}")

    elif dataset_name == "publicbibenchmark":
        dbs = ["Eixo",  "CMSprovider",  "Motos",  "Taxpayer",  "Provider",  "Generico",  "MulheresMil",  "RealEstate1",  "MedPayment2",  "Physicians",  "Medicare1",  "Medicare2",  "CommonGovernment",  "USCensus",  "Telco",  "RealEstate2",  "Arade",  "PanCreactomy2",  "SalariesFrance",  "Bimbo",  "Medicare3",  "NYC",  "TrainsUK2"]
        query_ids = []
        # query_ids_tt = ["generico-17", "generico-14", "generico-16", "generico-7", "generico-3", "generico-4", "cmsprovider-3", "motos-3", "generico-11", "generico-15", "commongovernment-5", "commongovernment-19", "uscensus-4", "realestate2-6", "medicare1-1", "eixo-1", "pancreactomy2-6", "pancreactomy2-3", "pancreactomy2-2", "provider-3", "realestate2-2", "realestate2-7", "bimbo-1", "bimbo-2", "salariesfrance-21", "medpayment2-1", "medicare3-1", "telco-1", "provider-36", "nyc-3", "pancreactomy2-5", "medicare1-2", "nyc-4", "generico-1", "pancreactomy2-4", "pancreactomy2-1", "arade-2", "salariesfrance-22", "physicians-1", "mulheresmil-5", "mulheresmil-6"]
        # query_ids = []
        # for qi in query_ids_tt:
        #     query_ids.append(f"queries/{qi}")
        for db in dbs:
            db = db.lower()
            for i in range(0, 200):
                query_fname = f"{workload_path}/queries/{db}-{i}.sql"
                if os.path.exists(query_fname):
                    query_ids.append(f"queries/{db}-{i}")
                    query_ids_verify.append(f"queries/{db}-{i}")
    for query_id in query_ids:
        _work_load.put(query_id)

    for query_id in query_ids_verify:
        _work_load_verify.put(query_id)