/* ==========================================================================
   PROJECT: World Layoffs - Exploratory Data Analysis (EDA)
   ==========================================================================
   Goal: Explore the cleaned `layoffs_staging2` table (produced by
   data_cleaning_layoffs.sql) to surface trends and patterns, such as:

     - Companies/industries/countries hit hardest by layoffs
     - The overall time range covered by the data
     - Layoffs trends over time (yearly totals, rolling monthly totals)
     - Top companies by layoffs for each year

   This script is read-only: it does not modify the underlying table.
   ========================================================================== */


-- Full look at the cleaned dataset
SELECT *
FROM layoffs_staging2;


-- Companies that laid off 100% of their staff (percentage_laid_off = 1),
-- sorted by how much funding they had raised — highlights well-funded
-- companies that still shut down entirely.
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;


-- Total layoffs per company, largest first
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;


-- Date range covered by the dataset
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;


-- Total layoffs per industry, largest first
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;


-- Total layoffs per country, largest first
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;


-- Total layoffs per year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;


-- Rolling (cumulative) total of layoffs by month.
-- Step 1: aggregate total layoffs per month (YYYY-MM)
-- Step 2: use a running SUM() window function to build a cumulative total
WITH rolling_total AS (
    SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`,
           SUM(total_laid_off)     AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `MONTH`
    ORDER BY 1 ASC
)
SELECT `MONTH`,
       total_off,
       SUM(total_off) OVER (ORDER BY `MONTH`) AS rolling_total
FROM rolling_total;


-- Top 5 companies by total layoffs, for each year.
-- Step 1: aggregate total layoffs per company, per year
-- Step 2: rank companies within each year using DENSE_RANK()
-- Step 3: keep only the top 5 ranked companies per year
WITH company_year (company, years, total_laid_off) AS (
    SELECT company, YEAR(`date`), SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
company_year_rank AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
    FROM company_year
    WHERE years IS NOT NULL
)
SELECT *
FROM company_year_rank
WHERE ranking <= 5;
