# Databricks notebook source
# MAGIC %md
# MAGIC #Bronze

# COMMAND ----------

# MAGIC %md
# MAGIC #### Two Schema's: Bronze_Archive, append hostorical data and Bronze: Truncate and append

# COMMAND ----------

# MAGIC %md
# MAGIC ##Imports

# COMMAND ----------

#Import
from pyspark.sql import SparkSession
from pyspark.sql.functions import col,current_timestamp, input_file_name

# COMMAND ----------

# MAGIC %md
# MAGIC ##crm_cust_info

# COMMAND ----------

# Define Volume path and source file
volume_path = "/Volumes/workspace/default/data-warehouse-databricks/"
file_name = "crm_cust_info.csv"

# Read raw file from Volume
df_raw = (spark.read
          .option("header", "true")
          .option("inferSchema", "true")
          .csv(f"{volume_path}{file_name}"))

# Add audit and ingestion metadata
df_bronze = (df_raw
             .withColumn("etl_time", current_timestamp())
             .withColumn("source_file", col('_metadata.file_path')))

# df_bronze.show(5)

# COMMAND ----------

# 1. APPEND to Bronze Archive (Preserves complete historical record)
(df_bronze.write
 .format("delta")
 .mode("append")
 .saveAsTable("bronze_archive.crm_cust_info"))

# 2. OVERWRITE/TRUNCATE Bronze Landing (Holds current batch data only)
(df_bronze.write
 .format("delta")
 .mode("overwrite")
 .saveAsTable("bronze.crm_cust_info"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## crm_prd_info

# COMMAND ----------

# Define Volume path and source file
volume_path = "/Volumes/workspace/default/data-warehouse-databricks/"
file_name = "crm_prd_info.csv"

# 1. Read raw file from Volume
df_prd = (spark.read
          .option("header", "true")
          .option("inferSchema", "true")
          .csv(f"{volume_path}{file_name}"))

# 2. Fix data types and add audit metadata columns
df_prd_fixed = df_prd \
    .withColumn('prd_start_dt', col('prd_start_dt').cast('timestamp')) \
    .withColumn('prd_end_dt', col('prd_end_dt').cast('timestamp')) \
    .withColumn('etl_time', current_timestamp()) \
    .withColumn('source_file', col('_metadata.file_path'))


# COMMAND ----------

# 3. APPEND to Archive schema (preserves full historical record)
df_prd_fixed.write.format('delta') \
    .mode('append') \
    .saveAsTable('bronze_archive.crm_prd_info')

# 4. OVERWRITE Landing schema (holds current batch for Silver transforms)
df_prd_fixed.write.format('delta') \
    .mode('overwrite') \
    .option('overwriteSchema', 'true') \
    .saveAsTable('bronze.crm_prd_info')

# COMMAND ----------

# MAGIC %md
# MAGIC ##crm_sales_details

# COMMAND ----------

# Define Volume path and source file
volume_path = "/Volumes/workspace/default/data-warehouse-databricks/"
file_name = "crm_sales_details.csv"

# Read raw file from Volume
df_raw = (spark.read
          .option("header", "true")
          .option("inferSchema", "true")
          .csv(f"{volume_path}{file_name}"))

# Add audit and ingestion metadata
df_bronze = (df_raw
             .withColumn("etl_time", current_timestamp())
             .withColumn("source_file", col('_metadata.file_path')))


# COMMAND ----------

# 1. APPEND to Bronze Archive (Preserves complete historical record)
(df_bronze.write
 .format("delta")
 .mode("append")
 .saveAsTable("bronze_archive.crm_sales_details"))

# 2. OVERWRITE/TRUNCATE Bronze Landing (Holds current batch data only)
(df_bronze.write
 .format("delta")
 .mode("overwrite")
 .saveAsTable("bronze.crm_sales_details"))

# COMMAND ----------

# MAGIC %md
# MAGIC ##erp_cust_az12

# COMMAND ----------

# Define Volume path and source file
volume_path = "/Volumes/workspace/default/data-warehouse-databricks/"
file_name = "erp_CUST_AZ12.csv"

# Read raw file from Volume
df_raw = (spark.read
          .option("header", "true")
          .option("inferSchema", "true")
          .csv(f"{volume_path}{file_name}"))

# Add audit and ingestion metadata
df_bronze = (df_raw
             .withColumn("etl_time", current_timestamp())
             .withColumn("source_file", col('_metadata.file_path')))


# COMMAND ----------

# 1. APPEND to Bronze Archive (Preserves complete historical record)
(df_bronze.write
 .format("delta")
 .mode("append")
 .saveAsTable("bronze_archive.erp_CUST_AZ12"))

# 2. OVERWRITE/TRUNCATE Bronze Landing (Holds current batch data only)
(df_bronze.write
 .format("delta")
 .mode("overwrite")
 .saveAsTable("bronze.erp_CUST_AZ12"))

# COMMAND ----------

# MAGIC %md
# MAGIC ##erp_loc_a101

# COMMAND ----------

# Define Volume path and source file
volume_path = "/Volumes/workspace/default/data-warehouse-databricks/"
file_name = "erp_LOC_A101.csv"

# Read raw file from Volume
df_raw = (spark.read
          .option("header", "true")
          .option("inferSchema", "true")
          .csv(f"{volume_path}{file_name}"))

# Add audit and ingestion metadata
df_bronze = (df_raw
             .withColumn("etl_time", current_timestamp())
             .withColumn("source_file", col('_metadata.file_path')))


# COMMAND ----------

# 1. APPEND to Bronze Archive (Preserves complete historical record)
(df_bronze.write
 .format("delta")
 .mode("append")
 .saveAsTable("bronze_archive.erp_LOC_A101"))

# 2. OVERWRITE/TRUNCATE Bronze Landing (Holds current batch data only)
(df_bronze.write
 .format("delta")
 .mode("overwrite")
 .saveAsTable("bronze.erp_LOC_A101"))

# COMMAND ----------

# MAGIC %md
# MAGIC ##erp_px_cat_g1v2

# COMMAND ----------

# Define Volume path and source file
volume_path = "/Volumes/workspace/default/data-warehouse-databricks/"
file_name = "erp_PX_CAT_G1V2.csv"

# Read raw file from Volume
df_raw = (spark.read
          .option("header", "true")
          .option("inferSchema", "true")
          .csv(f"{volume_path}{file_name}"))

# Add audit and ingestion metadata
df_bronze = (df_raw
             .withColumn("etl_time", current_timestamp())
             .withColumn("source_file", col('_metadata.file_path')))


# COMMAND ----------

# 1. APPEND to Bronze Archive (Preserves complete historical record)
(df_bronze.write
 .format("delta")
 .mode("append")
 .saveAsTable("bronze_archive.erp_PX_CAT_G1V2"))

# 2. OVERWRITE/TRUNCATE Bronze Landing (Holds current batch data only)
(df_bronze.write
 .format("delta")
 .mode("overwrite")
 .saveAsTable("bronze.erp_PX_CAT_G1V2"))