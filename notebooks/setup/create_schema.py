# Databricks notebook source
# MAGIC %sql
# MAGIC --Create Schema for Medallion Architecture
# MAGIC create schema if not exists bronze;
# MAGIC create schema if not exists bronze_archive;
# MAGIC create schema if not exists silver;
# MAGIC create schema if not exists gold;