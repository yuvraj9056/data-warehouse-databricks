-- Databricks notebook source
-- MAGIC %md
-- MAGIC #Load Silver

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##crm_cust_info

-- COMMAND ----------

-- =============================================================================
-- Step 1: Expire active records in Silver where changes are detected
-- =============================================================================
MERGE INTO silver.crm_cust_info AS target
USING (
  SELECT
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE 
      WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
      WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
      ELSE 'n/a'
    END AS cst_marital_status,
    CASE 
      WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
      WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
      ELSE 'n/a'
    END AS cst_gndr,
    cst_create_date
  FROM (
    SELECT 
      *, 
      ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
  ) t 
  WHERE flag_last = 1
) AS source
ON target.cst_id = source.cst_id AND target.is_current = true

-- Expire current version if attributes have changed
WHEN MATCHED AND (
    target.cst_firstname <> source.cst_firstname OR
    target.cst_lastname <> source.cst_lastname OR
    target.cst_marital_status <> source.cst_marital_status OR
    target.cst_gndr <> source.cst_gndr
) THEN
  UPDATE SET 
    target.is_current = false,
    target.effective_end_date = source.cst_create_date;


-- =============================================================================
-- Step 2: Insert new customer records & new active versions of updated records
-- =============================================================================
INSERT INTO silver.crm_cust_info (
  cst_id,
  cst_key,
  cst_firstname,
  cst_lastname,
  cst_marital_status,
  cst_gndr,
  cst_create_date,
  effective_start_date,
  effective_end_date,
  is_current,
  dwh_create_date
)
SELECT 
  source.cst_id,
  source.cst_key,
  source.cst_firstname,
  source.cst_lastname,
  source.cst_marital_status,
  source.cst_gndr,
  source.cst_create_date,
  source.cst_create_date AS effective_start_date,
  NULL AS effective_end_date,
  true AS is_current,
  current_timestamp() AS dwh_create_date
FROM (
  SELECT
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE 
      WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
      WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
      ELSE 'n/a'
    END AS cst_marital_status,
    CASE 
      WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
      WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
      ELSE 'n/a'
    END AS cst_gndr,
    cst_create_date
  FROM (
    SELECT 
      *, 
      ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
  ) t 
  WHERE flag_last = 1
) AS source
LEFT JOIN silver.crm_cust_info AS target
  ON source.cst_id = target.cst_id AND target.is_current = true
WHERE target.cst_id IS NULL -- Brand-new customers
   OR (                     -- Existing customers with changed attributes
        target.cst_firstname <> source.cst_firstname OR
        target.cst_lastname <> source.cst_lastname OR
        target.cst_marital_status <> source.cst_marital_status OR
        target.cst_gndr <> source.cst_gndr
      );

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##crm_prd_info

-- COMMAND ----------

-- =============================================================================
-- Step 1: Expire active product records in Silver where changes are detected
-- =============================================================================
MERGE INTO silver.crm_prd_info AS target
USING (
  SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
    prd_nm,
    COALESCE(prd_cost, 0) AS prd_cost,
    CASE 
      WHEN TRIM(prd_line) = 'M' THEN 'Mountain'
      WHEN TRIM(prd_line) = 'R' THEN 'Road'
      WHEN TRIM(prd_line) = 'S' THEN 'Other Sales'
      WHEN TRIM(prd_line) = 'T' THEN 'Touring'
      ELSE 'n/a'
    END AS prd_line,
    CAST(prd_start_dt AS TIMESTAMP) AS prd_start_dt,
    CAST(
      DATE_SUB(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt), 1)
    AS TIMESTAMP) AS prd_end_dt
  FROM bronze.crm_prd_info
) AS source
ON target.prd_id = source.prd_id AND target.is_current = true

-- Expire current product record if key attributes modified
WHEN MATCHED AND (
    target.cat_id <> source.cat_id OR
    target.prd_key <> source.prd_key OR
    target.prd_nm <> source.prd_nm OR
    target.prd_cost <> source.prd_cost OR
    target.prd_line <> source.prd_line
) THEN
  UPDATE SET 
    target.is_current = false,
    target.effective_end_date = COALESCE(source.prd_start_dt, current_timestamp());


-- =============================================================================
-- Step 2: Insert new product records & active versions of updated products
-- =============================================================================
INSERT INTO silver.crm_prd_info (
  prd_id,
  cat_id,
  prd_key,
  prd_nm,
  prd_cost,
  prd_line,
  prd_start_dt,
  prd_end_dt,
  effective_start_date,
  effective_end_date,
  is_current,
  dwh_create_date
)
SELECT 
  source.prd_id,
  source.cat_id,
  source.prd_key,
  source.prd_nm,
  source.prd_cost,
  source.prd_line,
  source.prd_start_dt,
  source.prd_end_dt,
  COALESCE(source.prd_start_dt, current_timestamp()) AS effective_start_date,
  NULL AS effective_end_date,
  true AS is_current,
  current_timestamp() AS dwh_create_date
FROM (
  SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
    prd_nm,
    COALESCE(prd_cost, 0) AS prd_cost,
    CASE 
      WHEN TRIM(prd_line) = 'M' THEN 'Mountain'
      WHEN TRIM(prd_line) = 'R' THEN 'Road'
      WHEN TRIM(prd_line) = 'S' THEN 'Other Sales'
      WHEN TRIM(prd_line) = 'T' THEN 'Touring'
      ELSE 'n/a'
    END AS prd_line,
    CAST(prd_start_dt AS TIMESTAMP) AS prd_start_dt,
    CAST(
      DATE_SUB(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt), 1)
    AS TIMESTAMP) AS prd_end_dt
  FROM bronze.crm_prd_info
) AS source
LEFT JOIN silver.crm_prd_info AS target
  ON source.prd_id = target.prd_id AND target.is_current = true
WHERE target.prd_id IS NULL -- Brand-new products
   OR (                     -- Existing products with attribute changes
        target.cat_id <> source.cat_id OR
        target.prd_key <> source.prd_key OR
        target.prd_nm <> source.prd_nm OR
        target.prd_cost <> source.prd_cost OR
        target.prd_line <> source.prd_line
      );

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##crm_sales_details

-- COMMAND ----------

MERGE INTO silver.crm_sales_details AS target
USING (
  SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE 
      WHEN sls_order_dt = 0 OR LENGTH(CAST(sls_order_dt AS STRING)) != 8 THEN NULL
      ELSE CAST(UNIX_TIMESTAMP(CAST(sls_order_dt AS STRING), 'yyyyMMdd') AS INT)
    END AS sls_order_dt,
    CASE 
      WHEN sls_ship_dt = 0 OR LENGTH(CAST(sls_ship_dt AS STRING)) != 8 THEN NULL
      ELSE CAST(UNIX_TIMESTAMP(CAST(sls_ship_dt AS STRING), 'yyyyMMdd') AS INT)
    END AS sls_ship_dt,
    CASE 
      WHEN sls_due_dt = 0 OR LENGTH(CAST(sls_due_dt AS STRING)) != 8 THEN NULL
      ELSE CAST(UNIX_TIMESTAMP(CAST(sls_due_dt AS STRING), 'yyyyMMdd') AS INT)
    END AS sls_due_dt,
    CASE 
      WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
      ELSE sls_sales
    END AS sls_sales,
    sls_quantity,
    CASE 
      WHEN sls_price IS NULL OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
      ELSE sls_price
    END AS sls_price
  FROM bronze.crm_sales_details
) AS source
ON target.sls_ord_num = source.sls_ord_num 
AND target.sls_prd_key = source.sls_prd_key 
AND target.sls_cust_id = source.sls_cust_id

-- Update existing sale records if data changed
WHEN MATCHED THEN
  UPDATE SET
    target.sls_order_dt = source.sls_order_dt,
    target.sls_ship_dt = source.sls_ship_dt,
    target.sls_due_dt = source.sls_due_dt,
    target.sls_sales = source.sls_sales,
    target.sls_quantity = source.sls_quantity,
    target.sls_price = source.sls_price,
    target.dwh_create_date = current_timestamp()

-- Insert new transaction records
WHEN NOT MATCHED THEN
  INSERT (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price,
    dwh_create_date
  )
  VALUES (
    source.sls_ord_num,
    source.sls_prd_key,
    source.sls_cust_id,
    source.sls_order_dt,
    source.sls_ship_dt,
    source.sls_due_dt,
    source.sls_sales,
    source.sls_quantity,
    source.sls_price,
    current_timestamp()
  );

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##erp_cust_az12

-- COMMAND ----------

-- =============================================================================
-- Step 1: Expire active ERP customer records in Silver where changes are detected
-- =============================================================================
MERGE INTO silver.erp_cust_az12 AS target
USING (
  SELECT
    CASE 
      WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
      ELSE cid
    END AS cid,
    CASE 
      WHEN bdate > current_date() THEN NULL
      ELSE bdate
    END AS bdate,
    CASE 
      WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
      WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
      ELSE 'n/a'
    END AS gen
  FROM bronze.erp_cust_az12
) AS source
ON target.cid = source.cid AND target.is_current = true

-- Expire current version if attributes have changed
WHEN MATCHED AND (
    target.bdate <=> source.bdate = false OR
    target.gen <> source.gen
) THEN
  UPDATE SET 
    target.is_current = false,
    target.effective_end_date = current_timestamp();


-- =============================================================================
-- Step 2: Insert new ERP customer records & active versions of updated records
-- =============================================================================
INSERT INTO silver.erp_cust_az12 (
  cid,
  bdate,
  gen,
  effective_start_date,
  effective_end_date,
  is_current,
  dwh_create_date
)
SELECT 
  source.cid,
  source.bdate,
  source.gen,
  current_timestamp() AS effective_start_date,
  NULL AS effective_end_date,
  true AS is_current,
  current_timestamp() AS dwh_create_date
FROM (
  SELECT
    CASE 
      WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
      ELSE cid
    END AS cid,
    CASE 
      WHEN bdate > current_date() THEN NULL
      ELSE bdate
    END AS bdate,
    CASE 
      WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
      WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
      ELSE 'n/a'
    END AS gen
  FROM bronze.erp_cust_az12
) AS source
LEFT JOIN silver.erp_cust_az12 AS target
  ON source.cid = target.cid AND target.is_current = true
WHERE target.cid IS NULL -- Brand-new customers
   OR (                  -- Existing customers with changed attributes
        target.bdate <=> source.bdate = false OR
        target.gen <> source.gen
      );

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##erp_loc_a101

-- COMMAND ----------

-- =============================================================================
-- Step 1: Expire active ERP location records in Silver where changes are detected
-- =============================================================================
MERGE INTO silver.erp_loc_a101 AS target
USING (
  SELECT
    REPLACE(cid, '-', '') AS cid,
    CASE 
      WHEN TRIM(cntry) = 'DE' THEN 'Germany'
      WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
      WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
      ELSE TRIM(cntry)
    END AS cntry
  FROM bronze.erp_loc_a101
) AS source
ON target.cid = source.cid AND target.is_current = true

-- Expire current version if country mapping has changed
WHEN MATCHED AND target.cntry <> source.cntry THEN
  UPDATE SET 
    target.is_current = false,
    target.effective_end_date = current_timestamp();


-- =============================================================================
-- Step 2: Insert new ERP location records & active versions of updated records
-- =============================================================================
INSERT INTO silver.erp_loc_a101 (
  cid,
  cntry,
  effective_start_date,
  effective_end_date,
  is_current,
  dwh_create_date
)
SELECT 
  source.cid,
  source.cntry,
  current_timestamp() AS effective_start_date,
  NULL AS effective_end_date,
  true AS is_current,
  current_timestamp() AS dwh_create_date
FROM (
  SELECT
    REPLACE(cid, '-', '') AS cid,
    CASE 
      WHEN TRIM(cntry) = 'DE' THEN 'Germany'
      WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
      WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
      ELSE TRIM(cntry)
    END AS cntry
  FROM bronze.erp_loc_a101
) AS source
LEFT JOIN silver.erp_loc_a101 AS target
  ON source.cid = target.cid AND target.is_current = true
WHERE target.cid IS NULL       -- Brand-new customer location records
   OR target.cntry <> source.cntry; -- Existing customer location with changed country

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##erp_px_cat_g1v2

-- COMMAND ----------

-- =============================================================================
-- Step 1: Expire active ERP product category records in Silver where changes are detected
-- =============================================================================
MERGE INTO silver.erp_px_cat_g1v2 AS target
USING (
  SELECT
    id,
    cat,
    subcat,
    maintenance
  FROM bronze.erp_px_cat_g1v2
) AS source
ON target.id = source.id AND target.is_current = true

-- Expire current version if product category or maintenance attributes have changed
WHEN MATCHED AND (
    target.cat <=> source.cat = false OR
    target.subcat <=> source.subcat = false OR
    target.maintenance <=> source.maintenance = false
) THEN
  UPDATE SET 
    target.is_current = false,
    target.effective_end_date = current_timestamp();


-- =============================================================================
-- Step 2: Insert new product category records & active versions of updated records
-- =============================================================================
INSERT INTO silver.erp_px_cat_g1v2 (
  id,
  cat,
  subcat,
  maintenance,
  effective_start_date,
  effective_end_date,
  is_current,
  dwh_create_date
)
SELECT 
  source.id,
  source.cat,
  source.subcat,
  source.maintenance,
  current_timestamp() AS effective_start_date,
  NULL AS effective_end_date,
  true AS is_current,
  current_timestamp() AS dwh_create_date
FROM (
  SELECT
    id,
    cat,
    subcat,
    maintenance
  FROM bronze.erp_px_cat_g1v2
) AS source
LEFT JOIN silver.erp_px_cat_g1v2 AS target
  ON source.id = target.id AND target.is_current = true
WHERE target.id IS NULL -- Brand-new product category IDs
   OR (                 -- Existing records with attribute updates
        target.cat <=> source.cat = false OR
        target.subcat <=> source.subcat = false OR
        target.maintenance <=> source.maintenance = false
      );