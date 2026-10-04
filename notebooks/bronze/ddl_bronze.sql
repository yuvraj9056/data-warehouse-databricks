-- Databricks notebook source
-- MAGIC %md
-- MAGIC This notebook creates script to create tables for bronze layer of medallian architecture. It will drop the tables if already exixts and then create new tables.

-- COMMAND ----------

-- DBTITLE 1,CRM Customers
-- CRM Customers
DROP TABLE IF EXISTS bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
cst_id              INT,
cst_key             STRING,
cst_firstname       STRING,
cst_lastname        STRING,
cst_marital_status  STRING,
cst_gndr            STRING,
cst_create_date     DATE,
etl_time            TIMESTAMP,
source_file         STRING
)

-- COMMAND ----------

-- DBTITLE 1,CRM Products
-- CRM Products
DROP TABLE IF EXISTS bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info (
prd_id       INT,
prd_key      STRING,
prd_nm       STRING,
prd_cost     INT,
prd_line     STRING,
prd_start_dt TIMESTAMP,
prd_end_dt   TIMESTAMP,
etl_time     TIMESTAMP,
source_file  STRING
)

-- COMMAND ----------

-- DBTITLE 1,CRM Sales
-- CRM Sales
DROP TABLE IF EXISTS bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details (
sls_ord_num  STRING,
sls_prd_key  STRING,
sls_cust_id  INT,
sls_order_dt INT,
sls_ship_dt  INT,
sls_due_dt   INT,
sls_sales    INT,
sls_quantity INT,
sls_price    INT,
etl_time            TIMESTAMP,
source_file         STRING
)

-- COMMAND ----------

-- DBTITLE 1,ERP Customer AZ12
-- ERP Customer AZ12
DROP TABLE IF EXISTS bronze.erp_cust_az12;
CREATE TABLE bronze.erp_cust_az12 (
CID   STRING,
BDATE DATE,
GEN   STRING,
etl_time            TIMESTAMP,
source_file         STRING
)

-- COMMAND ----------

-- DBTITLE 1,ERP Locations
-- ERP Locations
DROP TABLE IF EXISTS bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101 (
CID   STRING,
CNTRY STRING,
etl_time            TIMESTAMP,
source_file         STRING
)

-- COMMAND ----------

-- DBTITLE 1,ERP Products Category
-- ERP Products Category
DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2 (
ID   STRING,
CAT STRING,
SUBCAT STRING,
MAINTENANCE STRING,
etl_time            TIMESTAMP,
source_file         STRING
)