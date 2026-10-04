-- Databricks notebook source
-- MAGIC %md
-- MAGIC #DDL Silver - with SCD 2 columns

-- COMMAND ----------

-- =============================================================================
-- 1. CRM Customers (SCD Type 2)
-- =============================================================================
DROP TABLE IF EXISTS silver.crm_cust_info;

CREATE TABLE IF NOT EXISTS silver.crm_cust_info (
  cst_id STRING,
  cst_key STRING,
  cst_firstname STRING,
  cst_lastname STRING,
  cst_marital_status STRING,
  cst_gndr STRING,
  cst_create_date TIMESTAMP,
  effective_start_date TIMESTAMP,
  effective_end_date TIMESTAMP,
  is_current BOOLEAN,
  dwh_create_date TIMESTAMP
) USING DELTA;

-- =============================================================================
-- 2. CRM Products (SCD Type 2)
-- =============================================================================
DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE IF NOT EXISTS silver.crm_prd_info (
  prd_id INT,
  cat_id STRING,
  prd_key STRING,
  prd_nm STRING,
  prd_cost INT,
  prd_line STRING,
  prd_start_dt TIMESTAMP,
  prd_end_dt TIMESTAMP,
  effective_start_date TIMESTAMP,
  effective_end_date TIMESTAMP,
  is_current BOOLEAN,
  dwh_create_date TIMESTAMP
) USING DELTA;

-- =============================================================================
-- 3. ERP Customer AZ12 (SCD Type 2)
-- =============================================================================
DROP TABLE IF EXISTS silver.erp_cust_az12;

CREATE TABLE IF NOT EXISTS silver.erp_cust_az12 (
  CID STRING,
  BDATE DATE,
  GEN STRING,
  effective_start_date TIMESTAMP,
  effective_end_date TIMESTAMP,
  is_current BOOLEAN,
  dwh_create_date TIMESTAMP
) USING DELTA;

-- =============================================================================
-- 4. ERP Products Category G1V2 (SCD Type 2)
-- =============================================================================
DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;

CREATE TABLE IF NOT EXISTS silver.erp_px_cat_g1v2 (
  ID STRING,
  CAT STRING,
  SUBCAT STRING,
  MAINTENANCE STRING,
  effective_start_date TIMESTAMP,
  effective_end_date TIMESTAMP,
  is_current BOOLEAN,
  dwh_create_date TIMESTAMP
) USING DELTA;

-- =============================================================================
-- 5. ERP Locations A101 (SCD Type 2)
-- =============================================================================
DROP TABLE IF EXISTS silver.erp_loc_a101;

CREATE TABLE IF NOT EXISTS silver.erp_loc_a101 (
  CID STRING,
  CNTRY STRING,
  effective_start_date TIMESTAMP,
  effective_end_date TIMESTAMP,
  is_current BOOLEAN,
  dwh_create_date TIMESTAMP
) USING DELTA;

-- =============================================================================
-- 6. CRM Sales Details (Transactional Fact - No SCD)
-- =============================================================================
DROP TABLE IF EXISTS silver.crm_sales_details;

CREATE TABLE IF NOT EXISTS silver.crm_sales_details (
  sls_ord_num STRING,
  sls_prd_key STRING,
  sls_cust_id INT,
  sls_order_dt INT,
  sls_ship_dt INT,
  sls_due_dt INT,
  sls_sales INT,
  sls_quantity INT,
  sls_price INT,
  dwh_create_date TIMESTAMP
) USING DELTA;