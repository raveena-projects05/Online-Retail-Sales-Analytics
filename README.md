# Online Retail Sales Analytics — Oracle SQL Project

## Project overview
An end-to-end retail transaction analytics project using Oracle SQL and the Online Retail dataset. It covers data import, cleaning, transaction classification, KPI reporting, sales trends, product/customer analysis, and data-quality checks.

## Dataset
Source CSV extracted from `online_retail.csv` in the uploaded archive. The dataset contains 541,909 rows before cleaning and these fields: InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country.

## Key analysis results (calculated from the supplied CSV)
- Revenue from valid positive sales: £10,642,110.80
- Valid sales invoices: 19,960
- Units sold: 5,572,420
- Identified customers: 4,338
- Average order value: £533.17
- Exact duplicate rows identified: 5,268
- Missing CustomerID values after deduplication: 135,037

## Project structure
- `online_retail_analytics_oracle.sql` — Oracle SQL setup and 23 analysis/validation sections.
- `cleaned_transactions.csv` — typed and deduplicated dataset export for inspection.
- `sample_clean_sales_1000_rows.csv` — sample of the valid sales view.
- `data_quality_and_kpis.csv` — quality checks and headline KPIs.
- `monthly_sales.csv`, `country_sales.csv`, `top_20_products.csv`, `top_20_customers.csv` — analysis outputs.
- `monthly_revenue.png`, `top_countries.png` — charts.
- `project_report.docx` — concise project report.

## How to run in Oracle SQL Developer
1. Create/open an Oracle schema where you have permission to create tables and views.
2. Open `online_retail_analytics_oracle.sql` and run only the `CREATE TABLE online_retail_stg` statement first.
3. Right-click `ONLINE_RETAIL_STG` → **Import Data**. Select the extracted CSV file and map the eight columns in source order. Import as text columns as defined in the staging table.
4. Run the remaining SQL sections in order. If your CSV date format differs, inspect `InvoiceDate` values and adjust the `TO_DATE` formats in the typed-table statement.
5. Review the KPI and validation results against the CSV outputs. Save screenshots of Oracle SQL Developer results for a portfolio.

## Important integrity note
The CSV analysis and project files are prepared. The SQL script has **not** been executed against your Oracle database in this workspace. Run it in Oracle SQL Developer and verify the results before stating on a resume that Oracle execution was completed. The SQL uses Oracle 12.2+ conversion syntax (`DEFAULT NULL ON CONVERSION ERROR`) and `FETCH FIRST` row limiting.

## Resume bullet (use after you personally run and validate the SQL)
**Online Retail Sales Analytics | Oracle SQL, Data Cleaning, Business Analysis**
- Built an Oracle SQL analytics workflow to clean and analyze retail transactions, classify sales/returns/cancellations, and report revenue, order, customer, product, and country-level KPIs.
- Analyzed monthly revenue trends, customer repeat-purchase behavior, top products, and market contribution; documented data-quality checks and business insights.
