# Databricks notebook source
# Databricks Orchestrator Pattern
import time

def run_stage(notebook_path, timeout=1200):
    print(f"Starting execution: {notebook_path}")
    start_time = time.time()
    try:
        res = dbutils.notebook.run(notebook_path, timeout)
        duration = round(time.time() - start_time, 2)
        print(f"Success: {notebook_path} completed in {duration}s")
        return res
    except Exception as e:
        print(f"Failed: {notebook_path}")
        raise e

# Pipeline Execution Order
run_stage("/Workspace/Users/ranayuvrajsingh1111@gmail.com/customer_360_notebooks/load_bronze")  # Land raw files into Unity Catalog
run_stage("/Workspace/Users/ranayuvrajsingh1111@gmail.com/customer_360_notebooks/load_silver")          # Apply SCD Type 2 logic & cleansing
run_stage("/Workspace/Users/ranayuvrajsingh1111@gmail.com/customer_360_notebooks/load_gold")            # Refresh Gold views & fact/dim tables