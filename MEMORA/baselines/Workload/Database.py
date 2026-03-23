import psycopg2
import duckdb
import mysql.connector

class PostgreDB (object):
    def __init__(self):
        pass

    def connect(self):
        from Config import _dataset_name, _pgsql_user, _pgsql_password, _pgsql_host, _pgsql_port
        conn = psycopg2.connect(database=_dataset_name, user=_pgsql_user, password=_pgsql_password,
                                host=_pgsql_host, port=_pgsql_port, )
        return conn, conn.cursor()

    def close_connect(self, conn, cursor):
        cursor.close()
        conn.close()


    def execute(self, cursor, query):
        cursor.execute(query)
        result = cursor.fetchall()
        return result


class MySQLDB (object):
    def __init__(self):
        pass

    def connect(self):
        from Config import _dataset_name, _mysql_port, _mysql_user, _mysql_password, _mysql_host
        conn = mysql.connector.connect(
            host=_mysql_host,  # e.g., 'localhost' or IP address
            user=_mysql_user,  # your MySQL username
            password=_mysql_password,  # your MySQL password
            database=_dataset_name  # the database you want to use
        )
        return conn, conn.cursor()

    def close_connect(self, conn, cursor):
        cursor.close()
        conn.close()


    def execute(self, cursor, query):
        cursor.execute(query)
        result = cursor.fetchall()
        return result

class DuckDB:
    def __init__(self):
        pass

    def connect(self, threads: int=-1):
        from Config import _dataset_name, _database_path
        if threads == -1:
            conn = duckdb.connect(f"{_database_path}/{_dataset_name}")  # ,config = {'threads': 1}
        else:
            conn = duckdb.connect(f"{_database_path}/{_dataset_name}", config = {'threads': threads})
        return conn

    def close_connect(self, conn):
        conn.close()


    def execute(self, conn, query):
        result = conn.execute(query).fetchdf()
        return result