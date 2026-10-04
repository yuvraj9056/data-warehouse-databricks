-- Databricks notebook source
-- MAGIC %md
-- MAGIC ##Dimesion: Customers

-- COMMAND ----------

CREATE OR REPLACE VIEW gold.dim_customer AS
SELECT 
  -- 1. Stable, deterministic surrogate key for SCD Type 2 tracking
  MD5(CONCAT(COALESCE(ci.cst_id, 'n/a'), '_', COALESCE(CAST(ci.effective_start_date AS STRING), 'n/a'))) AS customer_key,
  
  -- 2. Business identifiers
  ci.cst_id AS customer_id,
  ci.cst_key AS customer_number,
  ci.cst_firstname AS first_name,
  ci.cst_lastname AS last_name,
  
  -- 3. Consolidated demographic attributes
  CASE 
    WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
    ELSE COALESCE(ca.gen, 'n/a')
  END AS gender,
  
  ci.cst_marital_status AS marital_status,
  COALESCE(cl.cntry, 'n/a') AS country,
  ca.bdate AS birth_date,
  ci.cst_create_date AS create_date,
  
  -- 4. SCD Type 2 tracking columns exposed for downstream point-in-time joins
  ci.effective_start_date,
  ci.effective_end_date,
  ci.is_current
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
  ON ci.cst_key = ca.cid 
 AND ca.is_current = true
LEFT JOIN silver.erp_loc_a101 AS cl
  ON ci.cst_key = cl.cid 
 AND cl.is_current = true
WHERE ci.is_current = true; -- Ensures 1 row per current customer in the primary dimension view

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##Dimension: Product

-- COMMAND ----------

CREATE OR REPLACE VIEW gold.dim_product AS
SELECT 
  -- 1. Stable, deterministic surrogate key for SCD Type 2
  MD5(CONCAT(COALESCE(CAST(pn.prd_id AS STRING), 'n/a'), '_', COALESCE(CAST(pn.effective_start_date AS STRING), 'n/a'))) AS product_key,

  -- 2. Business identifiers
  pn.prd_id AS product_id,
  pn.prd_key AS product_number,
  pn.prd_nm AS product_name,
  pn.cat_id AS category_id,

  -- 3. Consolidated category attributes from ERP
  COALESCE(pc.cat, 'n/a') AS category_name,
  COALESCE(pc.subcat, 'n/a') AS subcategory_name,
  COALESCE(pc.maintenance, 'n/a') AS maintenance,

  -- 4. Product cost and line classification
  pn.prd_cost AS product_cost,
  pn.prd_line AS product_line,

  -- 5. SCD Type 2 validity dates
  pn.effective_start_date AS start_date,
  pn.effective_end_date AS end_date,
  pn.is_current
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
  ON pn.cat_id = pc.id
 AND pc.is_current = true -- Ensures active category record is picked
WHERE pn.is_current = true; -- Filters strictly for current active products

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##FACT:Sales

-- COMMAND ----------

CREATE OR REPLACE VIEW gold.fact_sales AS
SELECT 
  -- 1. Order identification
  sd.sls_ord_num AS order_number,

  -- 2. Foreign Keys to Gold Dimensions (with fallbacks for missing mappings)
  COALESCE(pr.product_key, MD5('unknown')) AS product_key,
  COALESCE(cu.customer_key, MD5('unknown')) AS customer_key,

  -- 3. Date surrogate keys / values
  sd.sls_order_dt AS order_date,
  sd.sls_ship_dt AS shipping_date,
  sd.sls_due_dt AS due_date,

  -- 4. Financial and Order Metrics
  sd.sls_sales AS sales_amount,
  sd.sls_quantity AS quantity,
  sd.sls_price AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_product AS pr
  ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customer AS cu
  ON sd.sls_cust_id = cu.customer_id;