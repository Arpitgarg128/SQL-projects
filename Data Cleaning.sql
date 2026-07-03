/* ==========================================================================
   PROJECT: World Layoffs - Data Cleaning
   ==========================================================================
   Goal: Clean the raw `layoffs` dataset so it is ready for exploratory
   data analysis. This script covers four standard data cleaning steps:

     1. Remove duplicate records
     2. Standardize data (trim whitespace, fix inconsistent naming, dates)
     3. Handle NULL / blank values
     4. Remove irrelevant/unusable columns or rows

   A staging-table approach is used throughout so the original raw table
   (`layoffs`) is never modified directly.
   ========================================================================== */


-- Quick look at the raw, untouched data
SELECT *
FROM layoffs;


/* ==========================================================================
   STEP 1: REMOVE DUPLICATES
   ========================================================================== */

-- Create a staging table with the same structure as the raw table,
-- so we always have the original data as a backup.
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Copy all raw data into the staging table
INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;

-- Identify duplicate rows using ROW_NUMBER().
-- Partitioning by every column means only true duplicate rows get row_num > 1.
WITH duplicates_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off,
                            percentage_laid_off, `date`, stage, country,
                            funds_raised_millions
           ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;

-- Spot-check one of the duplicated companies to confirm the rows are real duplicates
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- MySQL does not allow deleting directly from a CTE, so we materialize
-- the row_num calculation into a second staging table instead.
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

-- Populate the new table with the row_num column included
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off,
                        percentage_laid_off, `date`, stage, country,
                        funds_raised_millions
       ) AS row_num
FROM layoffs_staging;

-- Rows with row_num > 1 are duplicates
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Delete the duplicate rows, keeping only the first occurrence of each
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;


/* ==========================================================================
   STEP 2: STANDARDIZE DATA
   ========================================================================== */

-- --- Company names: remove leading/trailing whitespace ---
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- --- Industry: fix inconsistent naming (e.g. "Crypto", "Crypto Currency", "CryptoCurrency") ---
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- --- Country: remove trailing periods (e.g. "United States." vs "United States") ---
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- --- Date: convert text dates (stored as strings) into a proper DATE type ---
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Now that the values are valid dates, change the column type itself
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Spot-check a well-known company after standardization
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';


/* ==========================================================================
   STEP 3: HANDLE NULL / BLANK VALUES
   ========================================================================== */

-- Find rows where industry is missing (NULL or empty string)
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

-- Convert blank strings to true NULLs for consistency
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- For companies with multiple entries, some rows have a NULL industry
-- while other rows for the SAME company have it filled in.
-- Self-join to find those fixable cases.
SELECT t1.company, t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;

-- Backfill the missing industry using the matching, non-null value
-- from another row of the same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;


/* ==========================================================================
   STEP 4: REMOVE UNUSABLE ROWS / COLUMNS
   ========================================================================== */

-- Rows where BOTH total_laid_off and percentage_laid_off are NULL
-- carry no useful information for analysis
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- The row_num column was only needed to identify duplicates in Step 1
-- and is no longer needed in the final, cleaned dataset
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final cleaned dataset, ready for exploratory data analysis
SELECT *
FROM layoffs_staging2;
