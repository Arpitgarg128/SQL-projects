# SQL-projects

# Layoffs Dataset — SQL Data Cleaning & Exploratory Data Analysis

This project cleans a raw dataset of global tech layoffs and explores it using MySQL, uncovering trends across companies, industries, countries, and time.

## 📌 Overview

The raw `layoffs` table contains inconsistencies typical of real-world data: duplicate records, inconsistent text formatting, dates stored as strings, and missing values. This script transforms it into an analysis-ready table (`layoffs_staging2`) using a staged approach that never modifies the original raw data.

## 🧹 Cleaning Steps

1. **Remove Duplicates**
   Used `ROW_NUMBER()` with `PARTITION BY` across all columns to identify exact duplicate rows, then removed them.

2. **Standardize Data**
   - Trimmed extra whitespace from company names
   - Consolidated inconsistent industry labels (e.g. `Crypto`, `CryptoCurrency` → `Crypto`)
   - Removed trailing periods from country names (e.g. `United States.` → `United States`)
   - Converted the `date` column from text to a proper `DATE` type

3. **Handle Null / Blank Values**
   - Converted blank strings to `NULL` for consistency
   - Backfilled missing `industry` values using other records from the same company

4. **Remove Unusable Data**
   - Deleted rows where both `total_laid_off` and `percentage_laid_off` were `NULL` (no usable layoff figures)
   - Dropped the helper `row_num` column used only for de-duplication

## 🗂️ Approach

| Table | Purpose |
|---|---|
| `layoffs` | Original raw data (untouched) |
| `layoffs_staging` | Working copy of raw data |
| `layoffs_staging2` | Final cleaned table, ready for analysis |

Working in staging tables ensures the raw data is always preserved and the cleaning process is fully reproducible.

## 🛠️ Tools Used

- MySQL
- Window functions (`ROW_NUMBER() OVER (PARTITION BY ...)`)
- Self-joins for null backfilling
- String and date functions (`TRIM`, `STR_TO_DATE`)

## 🔎 Exploratory Data Analysis

Once the data was cleaned, `eda_layoffs.sql` was used to answer questions like:

- Which companies laid off 100% of their staff, and how much funding had they raised?
- Which companies, industries, and countries had the highest total layoffs?
- What time period does the dataset cover?
- How did layoffs trend year over year?
- What does the cumulative (rolling) monthly layoff total look like?
- Which companies had the most layoffs in each year (top 5 per year)?

Key techniques used:
- Aggregate functions (`SUM`, `MIN`, `MAX`) with `GROUP BY`
- Window functions for rolling totals (`SUM() OVER (ORDER BY ...)`)
- `DENSE_RANK()` with `PARTITION BY` to find top-N per group
- CTEs to break multi-step logic into readable pieces

## 📁 Files

- `data_cleaning_layoffs.sql` — full, commented data cleaning script
- `eda_layoffs.sql` — full, commented exploratory data analysis script

## 📊 Dataset

The dataset contains layoff records for companies worldwide, including company name, location, industry, number/percentage of employees laid off, date, company stage, country, and total funds raised.

---

*Part of my data analysis portfolio — feedback welcome!*
