# olist-ecommerce-analysis
SQL analysis of Brazilian e-commerce dataset
# Olist E-commerce SQL Analysis

## Overview
Comprehensive SQL analysis of the Brazilian e-commerce public dataset from Olist, demonstrating advanced SQL techniques including CTEs, window functions, and business intelligence reporting.

## Dataset Source
[Olist E-commerce Dataset on Kaggle](https://www.kaggle.com/datasets/terencicp/e-commerce-dataset-by-olist-as-an-sqlite-database)

## Analysis Components

### 1. Database Exploration
- Schema inspection
- Dimension tables analysis (customers, sellers, products)
- Date range validation

### 2. Business Metrics
- Revenue analysis by category, customer, and location
- Top/bottom performers ranking
- Customer lifetime value

### 3. Time-Series Analysis
- Sales trends by year/month
- Seasonality patterns
- Moving averages and cumulative metrics

### 4. Advanced Analytics
- Customer segmentation (VIP, Regular, Repeat, One-time)
- Product performance tracking
- Delivery performance by state
- Review score impact analysis

### 5. Custom Reports (Views)
- Customer Report: RFM metrics and segmentation
- Product Report: Performance and lifecycle analysis
- Category Report: Market share and contribution
- Seller Report: Performance tracking

## SQL Techniques Used
- Common Table Expressions (CTEs)
- Window Functions (LAG, RANK, PARTITION BY)
- Aggregate Functions
- Date Functions (DATETRUNC, DATEDIFF)
- CASE statements for segmentation
- Subqueries and JOINs

## Technologies
- SQL Server / T-SQL
- Database: Ecommerce_dataset

## How to Use
1. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/terencicp/e-commerce-dataset-by-olist-as-an-sqlite-database)
2. Import into SQL Server as `Ecommerce_dataset`
3. Execute queries from `sql/analysis.sql` in order
4. Views will be created for ongoing reporting

## Repository Structure
```
olist-ecommerce-analysis/
├── README.md
└── sql/
    └── analysis.sql
```

## Author
[Your Name]

## License
MIT License

## Acknowledgments
- Dataset provided by Olist and available on Kaggle
- Brazilian e-commerce data (2016-2018)
