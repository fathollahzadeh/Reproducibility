-- 
-- Legal Notice 
-- 
-- This document and associated source code (the "Work") is a part of a 
-- benchmark specification maintained by the TPC. 
-- 
-- The TPC reserves all right, title, and interest to the Work as provided 
-- under U.S. and international laws, including without limitation all patent 
-- and trademark rights therein. 
-- 
-- No Warranty 
-- 
-- 1.1 TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE INFORMATION 
--     CONTAINED HEREIN IS PROVIDED "AS IS" AND WITH ALL FAULTS, AND THE 
--     AUTHORS AND DEVELOPERS OF THE WORK HEREBY DISCLAIM ALL OTHER 
--     WARRANTIES AND CONDITIONS, EITHER EXPRESS, IMPLIED OR STATUTORY, 
--     INCLUDING, BUT NOT LIMITED TO, ANY (IF ANY) IMPLIED WARRANTIES, 
--     DUTIES OR CONDITIONS OF MERCHANTABILITY, OF FITNESS FOR A PARTICULAR 
--     PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OF 
--     WORKMANLIKE EFFORT, OF LACK OF VIRUSES, AND OF LACK OF NEGLIGENCE. 
--     ALSO, THERE IS NO WARRANTY OR CONDITION OF TITLE, QUIET ENJOYMENT, 
--     QUIET POSSESSION, CORRESPONDENCE TO DESCRIPTION OR NON-INFRINGEMENT 
--     WITH REGARD TO THE WORK. 
-- 1.2 IN NO EVENT WILL ANY AUTHOR OR DEVELOPER OF THE WORK BE LIABLE TO 
--     ANY OTHER PARTY FOR ANY DAMAGES, INCLUDING BUT NOT LIMITED TO THE 
--     COST OF PROCURING SUBSTITUTE GOODS OR SERVICES, LOST PROFITS, LOSS 
--     OF USE, LOSS OF DATA, OR ANY INCIDENTAL, CONSEQUENTIAL, DIRECT, 
--     INDIRECT, OR SPECIAL DAMAGES WHETHER UNDER CONTRACT, TORT, WARRANTY,
--     OR OTHERWISE, ARISING IN ANY WAY OUT OF THIS OR ANY OTHER AGREEMENT 
--     RELATING TO THE WORK, WHETHER OR NOT SUCH AUTHOR OR DEVELOPER HAD 
--     ADVANCE NOTICE OF THE POSSIBILITY OF SUCH DAMAGES. 
-- 
-- Contributors:
-- Gradient Systems
--
create table dbgen_version
(
    dv_version                varchar(16)                   ,
    dv_create_date            date                          ,
    dv_create_time            time                          ,
    dv_cmdline_args           varchar(200)                  
);

create table customer_address
(
    ca_address_sk             integer               not null,
    ca_address_id             char(16)              not null,
    ca_street_number          char(10)                      ,
    ca_street_name            varchar(60)                   ,
    ca_street_type            char(15)                      ,
    ca_suite_number           char(10)                      ,
    ca_city                   varchar(60)                   ,
    ca_county                 varchar(30)                   ,
    ca_state                  char(2)                       ,
    ca_zip                    char(10)                      ,
    ca_country                varchar(20)                   ,
    ca_gmt_offset             decimal(5,2)                  ,
    ca_location_type          char(20)                      ,
    primary key (ca_address_sk)
);

create table customer_demographics
(
    cd_demo_sk                integer               not null,
    cd_gender                 char(1)                       ,
    cd_marital_status         char(1)                       ,
    cd_education_status       char(20)                      ,
    cd_purchase_estimate      integer                       ,
    cd_credit_rating          char(10)                      ,
    cd_dep_count              integer                       ,
    cd_dep_employed_count     integer                       ,
    cd_dep_college_count      integer                       ,
    primary key (cd_demo_sk)
);

create table date_dim
(
    d_date_sk                 integer               not null,
    d_date_id                 char(16)              not null,
    d_date                    date                          ,
    d_month_seq               integer                       ,
    d_week_seq                integer                       ,
    d_quarter_seq             integer                       ,
    d_year                    integer                       ,
    d_dow                     integer                       ,
    d_moy                     integer                       ,
    d_dom                     integer                       ,
    d_qoy                     integer                       ,
    d_fy_year                 integer                       ,
    d_fy_quarter_seq          integer                       ,
    d_fy_week_seq             integer                       ,
    d_day_name                char(9)                       ,
    d_quarter_name            char(6)                       ,
    d_holiday                 char(1)                       ,
    d_weekend                 char(1)                       ,
    d_following_holiday       char(1)                       ,
    d_first_dom               integer                       ,
    d_last_dom                integer                       ,
    d_same_day_ly             integer                       ,
    d_same_day_lq             integer                       ,
    d_current_day             char(1)                       ,
    d_current_week            char(1)                       ,
    d_current_month           char(1)                       ,
    d_current_quarter         char(1)                       ,
    d_current_year            char(1)                       ,
    primary key (d_date_sk)
);

create table warehouse
(
    w_warehouse_sk            integer               not null,
    w_warehouse_id            char(16)              not null,
    w_warehouse_name          varchar(20)                   ,
    w_warehouse_sq_ft         integer                       ,
    w_street_number           char(10)                      ,
    w_street_name             varchar(60)                   ,
    w_street_type             char(15)                      ,
    w_suite_number            char(10)                      ,
    w_city                    varchar(60)                   ,
    w_county                  varchar(30)                   ,
    w_state                   char(2)                       ,
    w_zip                     char(10)                      ,
    w_country                 varchar(20)                   ,
    w_gmt_offset              decimal(5,2)                  ,
    primary key (w_warehouse_sk)
);

create table ship_mode
(
    sm_ship_mode_sk           integer               not null,
    sm_ship_mode_id           char(16)              not null,
    sm_type                   char(30)                      ,
    sm_code                   char(10)                      ,
    sm_carrier                char(20)                      ,
    sm_contract               char(20)                      ,
    primary key (sm_ship_mode_sk)
);

create table time_dim
(
    t_time_sk                 integer               not null,
    t_time_id                 char(16)              not null,
    t_time                    integer                       ,
    t_hour                    integer                       ,
    t_minute                  integer                       ,
    t_second                  integer                       ,
    t_am_pm                   char(2)                       ,
    t_shift                   char(20)                      ,
    t_sub_shift               char(20)                      ,
    t_meal_time               char(20)                      ,
    primary key (t_time_sk)
);

create table reason
(
    r_reason_sk               integer               not null,
    r_reason_id               char(16)              not null,
    r_reason_desc             char(100)                     ,
    primary key (r_reason_sk)
);

create table income_band
(
    ib_income_band_sk         integer               not null,
    ib_lower_bound            integer                       ,
    ib_upper_bound            integer                       ,
    primary key (ib_income_band_sk)
);

create table item
(
    i_item_sk                 integer               not null,
    i_item_id                 char(16)              not null,
    i_rec_start_date          date                          ,
    i_rec_end_date            date                          ,
    i_item_desc               varchar(200)                  ,
    i_current_price           decimal(7,2)                  ,
    i_wholesale_cost          decimal(7,2)                  ,
    i_brand_id                integer                       ,
    i_brand                   char(50)                      ,
    i_class_id                integer                       ,
    i_class                   char(50)                      ,
    i_category_id             integer                       ,
    i_category                char(50)                      ,
    i_manufact_id             integer                       ,
    i_manufact                char(50)                      ,
    i_size                    char(20)                      ,
    i_formulation             char(20)                      ,
    i_color                   char(20)                      ,
    i_units                   char(10)                      ,
    i_container               char(10)                      ,
    i_manager_id              integer                       ,
    i_product_name            char(50)                      ,
    primary key (i_item_sk)
);

create table store
(
    s_store_sk                integer               not null,
    s_store_id                char(16)              not null,
    s_rec_start_date          date                          ,
    s_rec_end_date            date                          ,
    s_closed_date_sk          integer                       ,
    s_store_name              varchar(50)                   ,
    s_number_employees        integer                       ,
    s_floor_space             integer                       ,
    s_hours                   char(20)                      ,
    s_manager                 varchar(40)                   ,
    s_market_id               integer                       ,
    s_geography_class         varchar(100)                  ,
    s_market_desc             varchar(100)                  ,
    s_market_manager          varchar(40)                   ,
    s_division_id             integer                       ,
    s_division_name           varchar(50)                   ,
    s_company_id              integer                       ,
    s_company_name            varchar(50)                   ,
    s_street_number           varchar(10)                   ,
    s_street_name             varchar(60)                   ,
    s_street_type             char(15)                      ,
    s_suite_number            char(10)                      ,
    s_city                    varchar(60)                   ,
    s_county                  varchar(30)                   ,
    s_state                   char(2)                       ,
    s_zip                     char(10)                      ,
    s_country                 varchar(20)                   ,
    s_gmt_offset              decimal(5,2)                  ,
    s_tax_precentage          decimal(5,2)                  ,
    primary key (s_store_sk)
);

create table call_center
(
    cc_call_center_sk         integer               not null,
    cc_call_center_id         char(16)              not null,
    cc_rec_start_date         date                          ,
    cc_rec_end_date           date                          ,
    cc_closed_date_sk         integer                       ,
    cc_open_date_sk           integer                       ,
    cc_name                   varchar(50)                   ,
    cc_class                  varchar(50)                   ,
    cc_employees              integer                       ,
    cc_sq_ft                  integer                       ,
    cc_hours                  char(20)                      ,
    cc_manager                varchar(40)                   ,
    cc_mkt_id                 integer                       ,
    cc_mkt_class              char(50)                      ,
    cc_mkt_desc               varchar(100)                  ,
    cc_market_manager         varchar(40)                   ,
    cc_division               integer                       ,
    cc_division_name          varchar(50)                   ,
    cc_company                integer                       ,
    cc_company_name           char(50)                      ,
    cc_street_number          char(10)                      ,
    cc_street_name            varchar(60)                   ,
    cc_street_type            char(15)                      ,
    cc_suite_number           char(10)                      ,
    cc_city                   varchar(60)                   ,
    cc_county                 varchar(30)                   ,
    cc_state                  char(2)                       ,
    cc_zip                    char(10)                      ,
    cc_country                varchar(20)                   ,
    cc_gmt_offset             decimal(5,2)                  ,
    cc_tax_percentage         decimal(5,2)                  ,
    primary key (cc_call_center_sk)
);

create table customer
(
    c_customer_sk             integer               not null,
    c_customer_id             char(16)              not null,
    c_current_cdemo_sk        integer                       ,
    c_current_hdemo_sk        integer                       ,
    c_current_addr_sk         integer                       ,
    c_first_shipto_date_sk    integer                       ,
    c_first_sales_date_sk     integer                       ,
    c_salutation              char(10)                      ,
    c_first_name              char(20)                      ,
    c_last_name               char(30)                      ,
    c_preferred_cust_flag     char(1)                       ,
    c_birth_day               integer                       ,
    c_birth_month             integer                       ,
    c_birth_year              integer                       ,
    c_birth_country           varchar(20)                   ,
    c_login                   char(13)                      ,
    c_email_address           char(50)                      ,
    c_last_review_date        char(10)                      ,
    primary key (c_customer_sk)
);

create table web_site
(
    web_site_sk               integer               not null,
    web_site_id               char(16)              not null,
    web_rec_start_date        date                          ,
    web_rec_end_date          date                          ,
    web_name                  varchar(50)                   ,
    web_open_date_sk          integer                       ,
    web_close_date_sk         integer                       ,
    web_class                 varchar(50)                   ,
    web_manager               varchar(40)                   ,
    web_mkt_id                integer                       ,
    web_mkt_class             varchar(50)                   ,
    web_mkt_desc              varchar(100)                  ,
    web_market_manager        varchar(40)                   ,
    web_company_id            integer                       ,
    web_company_name          char(50)                      ,
    web_street_number         char(10)                      ,
    web_street_name           varchar(60)                   ,
    web_street_type           char(15)                      ,
    web_suite_number          char(10)                      ,
    web_city                  varchar(60)                   ,
    web_county                varchar(30)                   ,
    web_state                 char(2)                       ,
    web_zip                   char(10)                      ,
    web_country               varchar(20)                   ,
    web_gmt_offset            decimal(5,2)                  ,
    web_tax_percentage        decimal(5,2)                  ,
    primary key (web_site_sk)
);

create table store_returns
(
    sr_returned_date_sk       integer                       ,
    sr_return_time_sk         integer                       ,
    sr_item_sk                integer               not null,
    sr_customer_sk            integer                       ,
    sr_cdemo_sk               integer                       ,
    sr_hdemo_sk               integer                       ,
    sr_addr_sk                integer                       ,
    sr_store_sk               integer                       ,
    sr_reason_sk              integer                       ,
    sr_ticket_number          integer               not null,
    sr_return_quantity        integer                       ,
    sr_return_amt             decimal(7,2)                  ,
    sr_return_tax             decimal(7,2)                  ,
    sr_return_amt_inc_tax     decimal(7,2)                  ,
    sr_fee                    decimal(7,2)                  ,
    sr_return_ship_cost       decimal(7,2)                  ,
    sr_refunded_cash          decimal(7,2)                  ,
    sr_reversed_charge        decimal(7,2)                  ,
    sr_store_credit           decimal(7,2)                  ,
    sr_net_loss               decimal(7,2)                  ,
    primary key (sr_item_sk, sr_ticket_number)
);

create table household_demographics
(
    hd_demo_sk                integer               not null,
    hd_income_band_sk         integer                       ,
    hd_buy_potential          char(15)                      ,
    hd_dep_count              integer                       ,
    hd_vehicle_count          integer                       ,
    primary key (hd_demo_sk)
);

create table web_page
(
    wp_web_page_sk            integer               not null,
    wp_web_page_id            char(16)              not null,
    wp_rec_start_date         date                          ,
    wp_rec_end_date           date                          ,
    wp_creation_date_sk       integer                       ,
    wp_access_date_sk         integer                       ,
    wp_autogen_flag           char(1)                       ,
    wp_customer_sk            integer                       ,
    wp_url                    varchar(100)                  ,
    wp_type                   char(50)                      ,
    wp_char_count             integer                       ,
    wp_link_count             integer                       ,
    wp_image_count            integer                       ,
    wp_max_ad_count           integer                       ,
    primary key (wp_web_page_sk)
);

create table promotion
(
    p_promo_sk                integer               not null,
    p_promo_id                char(16)              not null,
    p_start_date_sk           integer                       ,
    p_end_date_sk             integer                       ,
    p_item_sk                 integer                       ,
    p_cost                    decimal(15,2)                 ,
    p_response_target         integer                       ,
    p_promo_name              char(50)                      ,
    p_channel_dmail           char(1)                       ,
    p_channel_email           char(1)                       ,
    p_channel_catalog         char(1)                       ,
    p_channel_tv              char(1)                       ,
    p_channel_radio           char(1)                       ,
    p_channel_press           char(1)                       ,
    p_channel_event           char(1)                       ,
    p_channel_demo            char(1)                       ,
    p_channel_details         varchar(100)                  ,
    p_purpose                 char(15)                      ,
    p_discount_active         char(1)                       ,
    primary key (p_promo_sk)
);

create table catalog_page
(
    cp_catalog_page_sk        integer               not null,
    cp_catalog_page_id        char(16)              not null,
    cp_start_date_sk          integer                       ,
    cp_end_date_sk            integer                       ,
    cp_department             varchar(50)                   ,
    cp_catalog_number         integer                       ,
    cp_catalog_page_number    integer                       ,
    cp_description            varchar(100)                  ,
    cp_type                   varchar(100)                  ,
    primary key (cp_catalog_page_sk)
);

create table inventory
(
    inv_date_sk               integer               not null,
    inv_item_sk               integer               not null,
    inv_warehouse_sk          integer               not null,
    inv_quantity_on_hand      integer                       ,
    primary key (inv_date_sk, inv_item_sk, inv_warehouse_sk)
);

create table catalog_returns
(
    cr_returned_date_sk       integer                       ,
    cr_returned_time_sk       integer                       ,
    cr_item_sk                integer               not null,
    cr_refunded_customer_sk   integer                       ,
    cr_refunded_cdemo_sk      integer                       ,
    cr_refunded_hdemo_sk      integer                       ,
    cr_refunded_addr_sk       integer                       ,
    cr_returning_customer_sk  integer                       ,
    cr_returning_cdemo_sk     integer                       ,
    cr_returning_hdemo_sk     integer                       ,
    cr_returning_addr_sk      integer                       ,
    cr_call_center_sk         integer                       ,
    cr_catalog_page_sk        integer                       ,
    cr_ship_mode_sk           integer                       ,
    cr_warehouse_sk           integer                       ,
    cr_reason_sk              integer                       ,
    cr_order_number           integer               not null,
    cr_return_quantity        integer                       ,
    cr_return_amount          decimal(7,2)                  ,
    cr_return_tax             decimal(7,2)                  ,
    cr_return_amt_inc_tax     decimal(7,2)                  ,
    cr_fee                    decimal(7,2)                  ,
    cr_return_ship_cost       decimal(7,2)                  ,
    cr_refunded_cash          decimal(7,2)                  ,
    cr_reversed_charge        decimal(7,2)                  ,
    cr_store_credit           decimal(7,2)                  ,
    cr_net_loss               decimal(7,2)                  ,
    primary key (cr_item_sk, cr_order_number)
);

create table web_returns
(
    wr_returned_date_sk       integer                       ,
    wr_returned_time_sk       integer                       ,
    wr_item_sk                integer               not null,
    wr_refunded_customer_sk   integer                       ,
    wr_refunded_cdemo_sk      integer                       ,
    wr_refunded_hdemo_sk      integer                       ,
    wr_refunded_addr_sk       integer                       ,
    wr_returning_customer_sk  integer                       ,
    wr_returning_cdemo_sk     integer                       ,
    wr_returning_hdemo_sk     integer                       ,
    wr_returning_addr_sk      integer                       ,
    wr_web_page_sk            integer                       ,
    wr_reason_sk              integer                       ,
    wr_order_number           integer               not null,
    wr_return_quantity        integer                       ,
    wr_return_amt             decimal(7,2)                  ,
    wr_return_tax             decimal(7,2)                  ,
    wr_return_amt_inc_tax     decimal(7,2)                  ,
    wr_fee                    decimal(7,2)                  ,
    wr_return_ship_cost       decimal(7,2)                  ,
    wr_refunded_cash          decimal(7,2)                  ,
    wr_reversed_charge        decimal(7,2)                  ,
    wr_account_credit         decimal(7,2)                  ,
    wr_net_loss               decimal(7,2)                  ,
    primary key (wr_item_sk, wr_order_number)
);

create table web_sales
(
    ws_sold_date_sk           integer                       ,
    ws_sold_time_sk           integer                       ,
    ws_ship_date_sk           integer                       ,
    ws_item_sk                integer               not null,
    ws_bill_customer_sk       integer                       ,
    ws_bill_cdemo_sk          integer                       ,
    ws_bill_hdemo_sk          integer                       ,
    ws_bill_addr_sk           integer                       ,
    ws_ship_customer_sk       integer                       ,
    ws_ship_cdemo_sk          integer                       ,
    ws_ship_hdemo_sk          integer                       ,
    ws_ship_addr_sk           integer                       ,
    ws_web_page_sk            integer                       ,
    ws_web_site_sk            integer                       ,
    ws_ship_mode_sk           integer                       ,
    ws_warehouse_sk           integer                       ,
    ws_promo_sk               integer                       ,
    ws_order_number           integer               not null,
    ws_quantity               integer                       ,
    ws_wholesale_cost         decimal(7,2)                  ,
    ws_list_price             decimal(7,2)                  ,
    ws_sales_price            decimal(7,2)                  ,
    ws_ext_discount_amt       decimal(7,2)                  ,
    ws_ext_sales_price        decimal(7,2)                  ,
    ws_ext_wholesale_cost     decimal(7,2)                  ,
    ws_ext_list_price         decimal(7,2)                  ,
    ws_ext_tax                decimal(7,2)                  ,
    ws_coupon_amt             decimal(7,2)                  ,
    ws_ext_ship_cost          decimal(7,2)                  ,
    ws_net_paid               decimal(7,2)                  ,
    ws_net_paid_inc_tax       decimal(7,2)                  ,
    ws_net_paid_inc_ship      decimal(7,2)                  ,
    ws_net_paid_inc_ship_tax  decimal(7,2)                  ,
    ws_net_profit             decimal(7,2)                  ,
    primary key (ws_item_sk, ws_order_number)
);

create table catalog_sales
(
    cs_sold_date_sk           integer                       ,
    cs_sold_time_sk           integer                       ,
    cs_ship_date_sk           integer                       ,
    cs_bill_customer_sk       integer                       ,
    cs_bill_cdemo_sk          integer                       ,
    cs_bill_hdemo_sk          integer                       ,
    cs_bill_addr_sk           integer                       ,
    cs_ship_customer_sk       integer                       ,
    cs_ship_cdemo_sk          integer                       ,
    cs_ship_hdemo_sk          integer                       ,
    cs_ship_addr_sk           integer                       ,
    cs_call_center_sk         integer                       ,
    cs_catalog_page_sk        integer                       ,
    cs_ship_mode_sk           integer                       ,
    cs_warehouse_sk           integer                       ,
    cs_item_sk                integer               not null,
    cs_promo_sk               integer                       ,
    cs_order_number           integer               not null,
    cs_quantity               integer                       ,
    cs_wholesale_cost         decimal(7,2)                  ,
    cs_list_price             decimal(7,2)                  ,
    cs_sales_price            decimal(7,2)                  ,
    cs_ext_discount_amt       decimal(7,2)                  ,
    cs_ext_sales_price        decimal(7,2)                  ,
    cs_ext_wholesale_cost     decimal(7,2)                  ,
    cs_ext_list_price         decimal(7,2)                  ,
    cs_ext_tax                decimal(7,2)                  ,
    cs_coupon_amt             decimal(7,2)                  ,
    cs_ext_ship_cost          decimal(7,2)                  ,
    cs_net_paid               decimal(7,2)                  ,
    cs_net_paid_inc_tax       decimal(7,2)                  ,
    cs_net_paid_inc_ship      decimal(7,2)                  ,
    cs_net_paid_inc_ship_tax  decimal(7,2)                  ,
    cs_net_profit             decimal(7,2)                  ,
    primary key (cs_item_sk, cs_order_number)
);

create table store_sales
(
    ss_sold_date_sk           integer                       ,
    ss_sold_time_sk           integer                       ,
    ss_item_sk                integer               not null,
    ss_customer_sk            integer                       ,
    ss_cdemo_sk               integer                       ,
    ss_hdemo_sk               integer                       ,
    ss_addr_sk                integer                       ,
    ss_store_sk               integer                       ,
    ss_promo_sk               integer                       ,
    ss_ticket_number          integer               not null,
    ss_quantity               integer                       ,
    ss_wholesale_cost         decimal(7,2)                  ,
    ss_list_price             decimal(7,2)                  ,
    ss_sales_price            decimal(7,2)                  ,
    ss_ext_discount_amt       decimal(7,2)                  ,
    ss_ext_sales_price        decimal(7,2)                  ,
    ss_ext_wholesale_cost     decimal(7,2)                  ,
    ss_ext_list_price         decimal(7,2)                  ,
    ss_ext_tax                decimal(7,2)                  ,
    ss_coupon_amt             decimal(7,2)                  ,
    ss_net_paid               decimal(7,2)                  ,
    ss_net_paid_inc_tax       decimal(7,2)                  ,
    ss_net_profit             decimal(7,2)                  ,
    primary key (ss_item_sk, ss_ticket_number)
);

COPY call_center FROM 'call_center.dat' (DELIMITER '|');
COPY catalog_page FROM 'catalog_page.dat' (DELIMITER '|');
COPY catalog_returns FROM 'catalog_returns.dat' (DELIMITER '|');
COPY catalog_sales FROM 'catalog_sales.dat' (DELIMITER '|');
COPY customer_address FROM 'customer_address.dat' (DELIMITER '|');
COPY customer FROM 'customer.dat' (DELIMITER '|');
COPY customer_demographics FROM 'customer_demographics.dat' (DELIMITER '|');
COPY date_dim FROM 'date_dim.dat' (DELIMITER '|');
COPY dbgen_version FROM 'dbgen_version.dat' (DELIMITER '|');
COPY household_demographics FROM 'household_demographics.dat' (DELIMITER '|');
COPY income_band FROM 'income_band.dat' (DELIMITER '|');
COPY inventory FROM 'inventory.dat' (DELIMITER '|');
COPY item FROM 'item.dat' (DELIMITER '|');
COPY promotion FROM 'promotion.dat' (DELIMITER '|');
COPY reason FROM 'reason.dat' (DELIMITER '|');
COPY ship_mode.dat FROM '' (DELIMITER '|');
COPY store FROM 'ship_mode.dat' (DELIMITER '|');
COPY store_returns FROM 'store_returns.dat' (DELIMITER '|');
COPY store_sales FROM 'store_sales.dat' (DELIMITER '|');
COPY time_dim FROM 'time_dim.dat' (DELIMITER '|');
COPY warehouse FROM 'warehouse.dat' (DELIMITER '|');
COPY web_page FROM 'web_page.dat' (DELIMITER '|');
COPY web_returns FROM 'web_returns.dat' (DELIMITER '|');
COPY web_sales FROM 'web_sales.dat' (DELIMITER '|');
COPY web_site FROM 'web_site.dat' (DELIMITER '|');



create index _dta_index_store_sales_6_1333579789__k1_k23_k14_k6_k8_k5_k7_3_4_9_10_11_12_13_16_17_20 on store_sales
(
	ss_sold_date_sk asc,
	ss_net_profit asc,
	ss_sales_price asc,
	ss_hdemo_sk asc,
	ss_store_sk asc,
	ss_cdemo_sk asc,
	ss_addr_sk asc
)
-- include(ss_item_sk,ss_customer_sk,ss_promo_sk,ss_ticket_number,ss_quantity,ss_wholesale_cost,ss_list_price,ss_ext_sales_price,ss_ext_wholesale_cost,ss_coupon_amt) 
;
create index _dta_index_store_sales_6_1333579789__k1_k5_k8_k3_11_13_14_20 on store_sales
(
	ss_sold_date_sk asc,
	ss_cdemo_sk asc,
	ss_store_sk asc,
	ss_item_sk asc
)
-- include(ss_quantity,ss_list_price,ss_sales_price,ss_coupon_amt) 
;
create index _dta_index_store_sales_6_1333579789__k1_k3_k10_k4_k8_9_16_23 on store_sales
(
	ss_sold_date_sk asc,
	ss_item_sk asc,
	ss_ticket_number asc,
	ss_customer_sk asc,
	ss_store_sk asc
)
-- include(ss_promo_sk,ss_ext_sales_price,ss_net_profit) 
;
create index _dta_index_store_sales_6_1333579789__k4_1_3_10_11_14 on store_sales
(
	ss_customer_sk asc
)
-- include(ss_sold_date_sk,ss_item_sk,ss_ticket_number,ss_quantity,ss_sales_price) 
;
create index _dta_index_store_sales_6_1333579789__k1_k3_k10_k4_k8_23 on store_sales
(
	ss_sold_date_sk asc,
	ss_item_sk asc,
	ss_ticket_number asc,
	ss_customer_sk asc,
	ss_store_sk asc
)
-- include(ss_net_profit) 
;
create index _dta_index_store_sales_6_1333579789__k1_k8_3_14_16 on store_sales
(
	ss_sold_date_sk asc,
	ss_store_sk asc
)
-- include(ss_item_sk,ss_sales_price,ss_ext_sales_price) 
;
create index _dta_index_store_sales_6_1333579789__k3_k10_k4_k1_k8 on store_sales
(
	ss_item_sk asc,
	ss_ticket_number asc,
	ss_customer_sk asc,
	ss_sold_date_sk asc,
	ss_store_sk asc
)
;
create index _dta_index_store_sales_6_1333579789__k1_k3_k7_16 on store_sales
(
	ss_sold_date_sk asc,
	ss_item_sk asc,
	ss_addr_sk asc
)
-- include(ss_ext_sales_price) 
;
create index _dta_index_store_sales_6_1333579789__k1_k7_k3_16 on store_sales
(
	ss_sold_date_sk asc,
	ss_addr_sk asc,
	ss_item_sk asc
)
-- include(ss_ext_sales_price) 
;
create index _dta_index_store_sales_6_1333579789__k1_k3_11_13 on store_sales
(
	ss_sold_date_sk asc,
	ss_item_sk asc
)
-- include(ss_quantity,ss_list_price) 
;
create index _dta_index_store_sales_6_1333579789__k1_k4_k3_k10 on store_sales
(
	ss_sold_date_sk asc,
	ss_customer_sk asc,
	ss_item_sk asc,
	ss_ticket_number asc
)
;
create index _dta_index_store_sales_6_1333579789__k4_k1_16 on store_sales
(
	ss_customer_sk asc,
	ss_sold_date_sk asc
)
-- include(ss_ext_sales_price) 
;
create index _dta_index_store_sales_6_1333579789__k3_k10_k4 on store_sales
(
	ss_item_sk asc,
	ss_ticket_number asc,
	ss_customer_sk asc
)
;
create index _dta_index_store_sales_6_1333579789__k10_k3 on store_sales
(
	ss_ticket_number asc,
	ss_item_sk asc
)
;
create index _dta_index_catalog_sales_6_1301579675__k1_k16_k5_k4_3_6_18_19_21_22_28_34 on catalog_sales
(
	cs_sold_date_sk asc,
	cs_item_sk asc,
	cs_bill_cdemo_sk asc,
	cs_bill_customer_sk asc
)
-- include(cs_ship_date_sk,cs_bill_hdemo_sk,cs_order_number,cs_quantity,cs_list_price,cs_sales_price,cs_coupon_amt,cs_net_profit) 
;
create index _dta_index_catalog_sales_6_1301579675__k17_k6_k3_k5_k1_k16_12_14_15_18_19 on catalog_sales
(
	cs_promo_sk asc,
	cs_bill_hdemo_sk asc,
	cs_ship_date_sk asc,
	cs_bill_cdemo_sk asc,
	cs_sold_date_sk asc,
	cs_item_sk asc
)
-- include(cs_call_center_sk,cs_ship_mode_sk,cs_warehouse_sk,cs_order_number,cs_quantity) 
;
create index _dta_index_catalog_sales_6_1301579675__k1_4_16_18_19_21_24 on catalog_sales
(
	cs_sold_date_sk asc
)
-- include(cs_bill_customer_sk,cs_item_sk,cs_order_number,cs_quantity,cs_list_price,cs_ext_sales_price) 
;
create index _dta_index_catalog_sales_6_1301579675__k3_k12_k14_k15_16_18 on catalog_sales
(
	cs_ship_date_sk asc,
	cs_call_center_sk asc,
	cs_ship_mode_sk asc,
	cs_warehouse_sk asc
)
-- include(cs_item_sk,cs_order_number) 
;
create index _dta_index_catalog_sales_6_1301579675__k1_k16_k4_18_34 on catalog_sales
(
	cs_sold_date_sk asc,
	cs_item_sk asc,
	cs_bill_customer_sk asc
)
-- include(cs_order_number,cs_net_profit) 
;
create index _dta_index_catalog_sales_6_1301579675__k3_1_12_14_15 on catalog_sales
(
	cs_ship_date_sk asc
)
-- include(cs_sold_date_sk,cs_call_center_sk,cs_ship_mode_sk,cs_warehouse_sk) 
;
create index _dta_index_catalog_sales_6_1301579675__k16_k4_k1_34 on catalog_sales
(
	cs_item_sk asc,
	cs_bill_customer_sk asc,
	cs_sold_date_sk asc
)
-- include(cs_net_profit) 
;
create index _dta_index_catalog_sales_6_1301579675__k16_k18_26 on catalog_sales
(
	cs_item_sk asc,
	cs_order_number asc
)
-- include(cs_ext_list_price) 
;
create index _dta_index_catalog_sales_6_1301579675__k1_k4 on catalog_sales
(
	cs_sold_date_sk asc,
	cs_bill_customer_sk asc
)
;
create index _dta_index_catalog_sales_6_1301579675__k1_4 on catalog_sales
(
	cs_sold_date_sk asc
)
-- include(cs_bill_customer_sk) 
;
create index _dta_index_web_sales_6_1269579561__k3_k18_k12_k14_16_29_34 on web_sales
(
	ws_ship_date_sk asc,
	ws_order_number asc,
	ws_ship_addr_sk asc,
	ws_web_site_sk asc
)
-- include(ws_warehouse_sk,ws_ext_ship_cost,ws_net_profit) 
;
create index _dta_index_web_sales_6_1269579561__k1_k4_k5_18 on web_sales
(
	ws_sold_date_sk asc,
	ws_item_sk asc,
	ws_bill_customer_sk asc
)
-- include(ws_order_number) 
;
create index _dta_index_web_sales_6_1269579561__k1_8_24 on web_sales
(
	ws_sold_date_sk asc
)
-- include(ws_bill_addr_sk,ws_ext_sales_price) 
;
create index _dta_index_web_sales_6_1269579561__k18_16 on web_sales
(
	ws_order_number asc
)
-- include(ws_warehouse_sk) 
;
create index _dta_index_web_sales_6_1269579561__k1_k5 on web_sales
(
	ws_sold_date_sk asc,
	ws_bill_customer_sk asc
)
;
create index _dta_index_store_returns_6_1013578649__k1_3_4_10_20 on store_returns
(
	sr_returned_date_sk asc
)
-- include(sr_item_sk,sr_customer_sk,sr_ticket_number,sr_net_loss) 
;
create index _dta_index_store_returns_6_1013578649__k5_1_3_10_11 on store_returns
(
	sr_cdemo_sk asc
)
-- include(sr_returned_date_sk,sr_item_sk,sr_ticket_number,sr_return_quantity) 
;
create index _dta_index_store_returns_6_1013578649__k1_3_4_10 on store_returns
(
	sr_returned_date_sk asc
)
-- include(sr_item_sk,sr_customer_sk,sr_ticket_number) 
;


;
create index _dta_index_customer_6_949578421__k9_k10 on customer
(
	c_first_name asc,
	c_last_name asc
)
;
create index _dta_index_customer_6_949578421__k1_k5 on customer
(
	c_customer_sk asc,
	c_current_addr_sk asc
)
;
create index _dta_index_item_6_853578079__k1_2_5 on item
(
	i_item_sk asc
)
-- include(i_item_id,i_item_desc) 
;


;
create index _dta_index_item_6_853578079__k13_k11_k1 on item
(
	i_category asc,
	i_class asc,
	i_item_sk asc
)
;


;
create index _dta_index_item_6_853578079__k18 on item
(
	i_color asc
)
;


;
create index _dta_index_item_6_853578079__k2_k1 on item
(
	i_item_id asc,
	i_item_sk asc
)
;
create index _dta_index_date_dim_6_661577395__k7_k4_k9_k1 on date_dim
(
	d_year asc,
	d_month_seq asc,
	d_moy asc,
	d_date_sk asc
)
;
create index _dta_index_date_dim_6_661577395__k7_k9_k1 on date_dim
(
	d_year asc,
	d_moy asc,
	d_date_sk asc
)
;
create index _dta_index_date_dim_6_661577395__k1_k7_k9 on date_dim
(
	d_date_sk asc,
	d_year asc,
	d_moy asc
)
;
create index _dta_index_date_dim_6_661577395__k7_k11_k1 on date_dim
(
	d_year asc,
	d_qoy asc,
	d_date_sk asc
)
;
create index _dta_index_date_dim_6_661577395__k9_k7_k1 on date_dim
(
	d_moy asc,
	d_year asc,
	d_date_sk asc
)
;
create index _dta_index_date_dim_6_661577395__k4_1 on date_dim
(
	d_month_seq asc
)
-- include(d_date_sk) 
;
create index _dta_index_date_dim_6_661577395__k7_k1 on date_dim
(
	d_year asc,
	d_date_sk asc
)
;
create index _dta_index_date_dim_6_661577395__k7_k9 on date_dim
(
	d_year asc,
	d_moy asc
)
;
create index _dta_index_date_dim_6_661577395__k4_k3 on date_dim
(
	d_month_seq asc,
	d_date asc
)
;
create index _dta_index_store_6_885578193__k1_2_6 on store
(
	s_store_sk asc
)
-- include(s_store_id,s_store_name) 
;


;
create index _dta_index_store_6_885578193__k25_k1 on store
(
	s_state asc,
	s_store_sk asc
)
;
-- indexes created for q19

create index _dta_index_store_sales_5_1333579789__k4_k8_k3_k1_16 on store_sales
(
	ss_customer_sk asc,
	ss_store_sk asc,
	ss_item_sk asc,
	ss_sold_date_sk asc
)
-- include(ss_ext_sales_price) 
;
create index _dta_index_customer_5_949578421__k13_k5 on customer
(
	c_birth_month asc,
	c_current_addr_sk asc
)
;