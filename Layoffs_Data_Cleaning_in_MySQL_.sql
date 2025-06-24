-- DATA CLEANING !

-- REMOVE DUPLICATES
-- STANDARDISE DATA
-- NULL VALUES/BLANK VALUES
-- REMOVE ANY COLUMNS

SELECT *
FROM layoffs;

-- create BACKUP TABLE TO AVOID DATA LOSS
-- MAIN TASK HAPPENS IN BACKUP TABLE

CREATE TABLE layoffs_backup
AS
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_backup;

-- Removing duplicates

SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_backup;

-- The syntax returns records with unique row number.
-- from the records, we want to check where row number are greater than 2
-- I will do this using cte

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_backup
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- BEFORE DELETING, it is important to check whether these are duplicates
-- to check, I will run this syntax

SELECT *
FROM layoffs_backup
WHERE company = 'Casper'; -- 	from the results, "Casper" has two duplicates and we want one record

-- in another versions of SQL duplicates can be delete from the CTEs like the syntax below

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_backup
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

-- Here is how I'm gonna do it in this version of MySQL
-- 1. create another table
-- 2. insert into new table data from our backup table

CREATE TABLE `layoffs_backup2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT -- original table colums plus added row_num
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- checking if our table was created successfully

SELECT *
FROM layoffs_backup2;

-- inserting data

INSERT INTO layoffs_backup2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_backup;

SELECT *
FROM layoffs_backup2
WHERE row_num > 1; -- this execution will show the duplicate where row_num >1

DELETE
FROM layoffs_backup2
WHERE row_num > 1; -- this one deletes the duplicates

SELECT *
FROM layoffs_backup2
WHERE row_num > 1; -- just to be sure, check whether the records were deleted

SELECT * 
FROM layoffs_backup2;

-- Standardizing data

SELECT * 
FROM layoffs_backup2; 

SELECT company, TRIM(company)
FROM layoffs_backup2; -- removing white space before and after a string

UPDATE layoffs_backup2
SET company = TRIM(company);

-- Looking at distinct industies to identify whether they need to be updated

SELECT DISTINCT industry 
FROM layoffs_backup2
ORDER BY 1; -- turns out some industries are the same but they are written differently. Take crypto and crypto currency for example

SELECT * 
FROM layoffs_backup2
WHERE industry LIKE '%Crypto%'; -- there are three record of different cryptos

UPDATE layoffs_backup2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'; -- in this syntax we are updating the crypto% to Crypto

SELECT *
FROM layoffs_backup2;


SELECT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_backup2;

UPDATE layoffs_backup2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'; -- Updating United States with trailings by removing them

SELECT DISTINCT country
FROM layoffs_backup2
WHERE country LIKE 'United States%'; -- confirming

SELECT `date`
FROM layoffs_backup2;

SELECT `date`,
STR_TO_DATE (`date`, '%m/%d/%Y')
FROM layoffs_backup2;

UPDATE layoffs_backup2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); -- date conversion. Starting with column converson gives an eror.
											  -- best practice is to convert records first.
                                              
ALTER TABLE layoffs_backup2
MODIFY COLUMN `date` DATE; 

-- NULL values/Blanks
-- here I am looking for any useless records,
-- whether they make the data unreadable or they are just useless and remove them
-- this one is complex, there might be some conversions in order to make conclusive decisions

SELECT *
FROM layoffs_backup2;

SELECT * 
FROM layoffs_backup2
WHERE industry IS NULL
OR industry = ''; -- here I look for industry where records are null or blank

SELECT * 
FROM layoffs_backup2
WHERE company = 'Airbnb'; -- here what I see is the industry being null in one record and the other has the industry
						  -- the solution is to populate the blank with "Travel" industry
                          
UPDATE layoffs_backup2
SET industry = 'Travel'
WHERE industry = ''
AND location = 'SF Bay Area'; -- this syntax is not executed because this changes only the Airbnb.
							  -- what I really want is for any company with null/blank industry to be populated with its respective industry
                              
-- using JOIN will be the solution here because self join will populate the blank or null industry if there is one of them that is not null/blank

SELECT t1.industry, t2.industry -- selecting industry (column) in t1 and t2 as aliases
FROM layoffs_backup2 t1
JOIN layoffs_backup2 t2
	ON t1.company = t2.company -- join table 1 and 2 columns "company"
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '') -- 
AND t2.industry IS NOT NULL; -- here is where it all goes down. JOINing where t2 industry is not null


UPDATE layoffs_backup2 t1
JOIN layoffs_backup2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;                   -- unfortunately this changes nothing.
												-- Tried this too and unfortunately it changes nothing.  
                                              -- now let's try changing these values to NULL from blank
                                              
UPDATE layoffs_backup2 t1
SET industry = NULL
WHERE industry = ''; -- after updating the values I tried again to update the the table using join.
					 -- and it worked.
                     
-- checking if there are null or blank values in industry

SELECT *
FROM layoffs_backup2
WHERE industry IS NULL
OR industry = ''; -- still have one company with null industry

SELECT *
FROM layoffs_backup2
WHERE company like 'Bally%'; -- and there is no other Bally% to populate with so leave it like that

SELECT *
FROM layoffs_backup2;
 -- looking at the table now I can see that there are still null values.
 -- however I am not going to populate these because they are impossible to.
 -- for example to populate total_laid_off we need another mising column (company employees maybe?) to do calculations from percentage_laid_off.
 
 SELECT *
 FROM layoffs_backup2
 WHERE total_laid_off IS NULL
 AND percentage_laid_off IS NULL; -- These records are imposible to populate, nor conclude that they were laid off. 
								  -- only solution is to remove the data because it cannot be used.


 DELETE
 FROM layoffs_backup2
 WHERE total_laid_off IS NULL
 AND percentage_laid_off IS NULL;
 
SELECT *
FROM layoffs_backup2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; -- Now the data is gone


SELECT *
FROM layoffs_backup2;

-- Final step is to remove any unwanted column

ALTER TABLE layoffs_backup2
DROP COLUMN row_num;

-- There we have it, our cleaned data!!

SELECT *
FROM layoffs_backup2;



