-- Create staging table
CREATE TABLE layoffs_staging LIKE layoffs;
INSERT INTO layoffs_staging SELECT * FROM layoffs;
SELECT * FROM layoffs_staging;

-- Find duplicates
SELECT *,
       ROW_NUMBER() OVER(
         PARTITION BY company, location, industry, total_laid_off,
                      percentage_laid_off, `date`, stage, country, funds_raised_millions
         ORDER BY company
       ) AS row_num
FROM layoffs_staging;

-- Identify duplicates
WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER(
             PARTITION BY company, location, industry, total_laid_off,
                          percentage_laid_off, `date`, stage, country, funds_raised_millions
             ORDER BY company
           ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Delete duplicates

CREATE TABLE layoffs_staging2 (
   company TEXT,
   location TEXT,
   industry TEXT,
   total_laid_off INT DEFAULT NULL,
   percentage_laid_off TEXT,
   `date` TEXT,
   stage TEXT,
   country TEXT,
   funds_raised_millions INT DEFAULT NULL,
   row_num INT
);

INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER(
         PARTITION BY company, location, industry, total_laid_off,
                      percentage_laid_off, `date`, stage, country, funds_raised_millions
         ORDER BY company
       ) AS row_num
FROM layoffs_staging;

DELETE FROM layoffs_staging2 WHERE row_num > 1;
SELECT * FROM layoffs_staging2;


-- Next cleaning steps
-- Standardize data → trim spaces, lowercase/uppercase company names, fix inconsistent country names (e.g., "United States" vs "USA").

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Handle NULL & blank values → replace with NULL or impute.
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '' OR industry IS NULL;

-- Remove unnecessary columns
ALTER TABLE layoffs_staging2 DROP COLUMN row_num;


