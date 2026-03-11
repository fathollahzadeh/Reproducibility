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

def get_dataset_table_names(dataset_name:str):
    tbl_names = []
    if dataset_name == 'tpch':
        tbl_names = ["nation", "region", "supplier", "customer", "part", "partsupp", "orders", "lineitem"]

    elif dataset_name == 'imdb':
            tbl_names = ['aka_name', 'aka_title', 'cast_info', 'char_name', 'comp_cast_type', 'company_name', 'company_type', 'complete_cast', 'info_type', 'keyword', 'kind_type', 'link_type', 'movie_companies', 'movie_info', 'movie_info_idx', 'movie_keyword', 'movie_link', 'name', 'person_info', 'role_type', 'title']

    elif dataset_name == 'stats':
            tbl_names = ['badges', 'comments', 'posthistory', 'postlinks', 'posts', 'tags', 'users', 'votes']

    elif dataset_name == 'stats_ceb':
            tbl_names = ['badges', 'comments', 'posthistory', 'postlinks', 'posts', 'tags', 'users', 'votes']

    elif dataset_name == 'dsb':
            tbl_names = ['call_center', 'catalog_page', 'catalog_returns', 'catalog_sales', 'customer', 'customer_address', 'customer_demographics', 'date_dim', 'dbgen_version', 'household_demographics', 'income_band', 'inventory', 'item', 'promotion', 'reason', 'ship_mode', 'store', 'store_returns', 'store_sales', 'time_dim', 'warehouse', 'web_page', 'web_returns', 'web_sales', 'web_site']

    elif dataset_name == 'publicbibenchmark':
            tbl_names = ['arade1', 'bimbo1', 'cmsprovider1', 'cmsprovider2', 'commongovernment1', 'commongovernment10', 'commongovernment11', 'commongovernment12', 'commongovernment13', 'commongovernment2', 'commongovernment3', 'commongovernment4', 'commongovernment5', 'commongovernment6', 'commongovernment7', 'commongovernment8', 'commongovernment9', 'eixo1', 'generico1', 'generico2', 'generico3', 'generico4', 'generico5', 'medicare11', 'medicare12', 'medicare21', 'medicare22', 'medicare31', 'medpayment21', 'motos1', 'motos2', 'mulheresmil1', 'nyc1', 'nyc2', 'pancreactomy21', 'pancreactomy22', 'physicians1', 'provider1', 'provider2', 'provider3', 'provider4', 'provider5', 'provider6', 'provider7', 'provider8', 'realestate11', 'realestate12', 'realestate21', 'realestate22', 'realestate23', 'realestate24', 'realestate25', 'realestate26', 'realestate27', 'salariesfrance1', 'salariesfrance10', 'salariesfrance11', 'salariesfrance12', 'salariesfrance13', 'salariesfrance2', 'salariesfrance3', 'salariesfrance4', 'salariesfrance5', 'salariesfrance6', 'salariesfrance7', 'salariesfrance8', 'salariesfrance9', 'taxpayer1', 'taxpayer10', 'taxpayer2', 'taxpayer3', 'taxpayer4', 'taxpayer5', 'taxpayer6', 'taxpayer7', 'taxpayer8', 'taxpayer9', 'telco1', 'trainsuk21', 'trainsuk22', 'uscensus1', 'uscensus2', 'uscensus3']   
    elif dataset_name == 'stackoverflow':
          tbl_names = ['Badges', 'CloseReasonTypes', 'Comments', 'LinkTypes', 'PostHistory', 'PostHistoryTypes', 'PostLinks', 'PostTypes', 'Posts', 'Tags', 'Users', 'VoteTypes', 'Votes']             

                 
    return tbl_names
if __name__ == "__main__":
    args = parse_arguments()
    tables_name = get_dataset_table_names(args.dataset_name)

        
    con = duckdb.connect()

    # install and load postgres extension
    con.execute("INSTALL postgres")
    con.execute("LOAD postgres")

    # connection string
    conn = f"host=localhost port=5432 dbname={args.dataset_name} user=postgres password=postgres"

    print(tables_name)

    for table_name in tables_name:   
        print(table_name)     
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