# Medallion Customer 360 Lakehouse Architecture

An end-to-end, production-grade ETL/ELT pipeline built on **Databricks**, **Delta Lake**, and **Unity Catalog**. This project implements a **Medallion Architecture** (Bronze landing, Silver curated history with SCD Type 2 tracking, and Gold dimensional analytics) to build an enterprise-ready Customer 360 data foundation.

---

## Architecture Overview


[ Raw CSV Files ]
       │
       ▼
┌──────────────┐
│ Bronze Layer │  Raw landing volume, schema preservation, file lineage tracking
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Silver Layer │  Data cleansing, standardization, deduplication & SCD Type 2 tracking
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Gold Layer  │  Star Schema (Fact & Dimension views, deterministic MD5 surrogate keys) 
└──────────────┘

<img width="935" height="621" alt="image" src="https://github.com/user-attachments/assets/91e35e95-82c3-4b88-b273-aa8e5cd5f723" />

## Pipeline Layers & Technical Implementation

### 1. Bronze Layer (Landing & Archival)
* **Storage:** Native Unity Catalog Volumes (`/Volumes/catalog/schema/landing/`).
* **Transformations:** Reads raw multi-source CSV files (`CRM` & `ERP`), adds ingestion timestamps (`dwh_create_date`), and preserves raw data structures without modification.
* **Lineage:** Standardized metadata file path logging using Unity Catalog `_metadata.file_path`.

### 2. Silver Layer (Cleansing & SCD Type 2 History)
* **Storage:** Delta Lake tables.
* **Idempotency:** Replaced destructive `TRUNCATE` loads with **`MERGE INTO`** statements to enable incremental updates and history preservation.
* **SCD Type 2 Implementation:** Applied to dimension tables (`crm_cust_info`, `crm_prd_info`, `erp_cust_az12`, `erp_loc_a101`, `erp_px_cat_g1v2`) using:
  * `effective_start_date` & `effective_end_date`
  * `is_current` boolean flag
* **Data Cleansing:**
  * Standardization of text case, gender codes (`M`/`F` → `Male`/`Female`), and country names.
  * Handling null and invalid date formats (`yyyyMMdd` parsing).
  * Business rule fixes (calculating derived unit price and line item sales amount).

### 3. Gold Layer (Star Schema Analytics)
* **Modeling:** Dimensional Star Schema with views optimized for BI reporting tools (Power BI, Tableau, Databricks SQL Dashboards).
* **Surrogate Keys:** Generated deterministic, hash-based surrogate keys (`MD5(CONCAT(...))`) instead of non-deterministic row numbers to ensure stable join keys across pipeline re-runs.
* **Tables/Views:**
  * `gold.dim_customer`: Unified profile joining CRM customer attributes with ERP demographics and country locations.
  * `gold.dim_product`: Consolidated product catalog joining CRM product info with ERP categories.
  * `gold.fact_sales`: Transactional fact view joining sales order details with Gold dimensions via natural and surrogate keys.

## Project Structure


medallion-customer360-lakehouse/
│
├── .gitignore                          # Git ignore rules for Databricks/Python artifacts
├── LICENSE                             # Repository license file
├── README.md                           # Master project documentation
│
├── Workflows/                          # Databricks Job DAG export & Asset Bundle definitions
│   └── ETL_Job.yaml                    # Multi-Task DAG workflow configuration
│
├── data/                               # Sample raw CRM and ERP dataset files
│
└── notebooks/                          # Databricks ETL scripts & DDLs
    ├── setup/                          # Environment configuration & master runner
    │   ├── .gitkeep
    │   ├── create_schema.py            # Catalogs, schemas, and volumes setup
    │   └── master_orchestrator.py      # Master execution entry-point
    │
    ├── bronze/                         # Raw ingestion & archive landing
    │   ├── .gitkeep
    │   ├── ddl_bronze.sql              # DDL definitions for landing tables
    │   ├── ddl_bronze_archive.sql      # DDL definitions for archive tables
    │   └── load_bronze.py              # Ingestion logic from source CSVs
    │
    ├── silver/                         # Data cleansing & SCD Type 2 history
    │   ├── .gitkeep
    │   ├── ddl_silver.sql              # DDL definitions for Silver Delta tables
    │   └── load_silver.sql             # SCD Type 2 MERGE INTO updates
    │
    └── gold/                           # Analytics & Star Schema views
        ├── .gitkeep
        └── load_gold.sql               # Star Schema dimension & fact view definitions

## Databricks Workflow DAG

The pipeline is orchestrated using a multi-task **Databricks Workflow Job**:

1. **`CSV_to_Bronze`**: Ingests raw CRM & ERP source files into Delta Bronze tables.
2. **`Bronze_to_Silver`**: Runs cleansing, normalization, and SCD Type 2 `MERGE` updates.
3. **`Silver_to_Gold`**: Re-computes Gold dimensional views and fact joins.

<img width="847" height="110" alt="image" src="https://github.com/user-attachments/assets/e0bf4cd3-54aa-4d98-83b7-c1d3bd9f99b8" />

---

## Getting Started

### Prerequisites
* **Databricks Workspace** with Unity Catalog enabled.
* **Serverless** or **Single Node** Spark Compute Cluster.
* Access permissions to create Catalogs, Schemas, Tables, and Volumes in Unity Catalog.

### Execution Steps
1. **Clone the repository** into your Databricks Workspace Git Folders:
   ```bash
   git clone [https://github.com/your-username/medallion-customer360-lakehouse.git](https://github.com/your-username/medallion-customer360-lakehouse.git)
2. Upload source data files to your target Unity Catalog Volume path.
3. Execute DDL scripts (notebooks/silver/ddl_silver.sql) to prepare target Delta schema definitions.
4. Run the master notebook notebooks/setup/master_orchestrator.py or trigger the Databricks Workflow Job using Workflows/ETL_Job.yaml.

### Key Delta Lake Features Used:
1. SCD Type 2 History: Full audit trail for dimension attribute updates over time.
2. ACID Transactions: Atomic updates with Delta Lake MERGE INTO.
3. Unity Catalog Governance: Fine-grained access control and end-to-end data lineage tracking.
4. Optimized Reads: Z-Ordering and automatic Delta log maintenance (OPTIMIZE / VACUUM).
