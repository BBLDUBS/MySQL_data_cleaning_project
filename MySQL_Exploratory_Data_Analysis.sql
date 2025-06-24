-- Explorarory Data Analysis


SELECT *
FROM layoffs_backup2;


SELECT DISTINCT company, total_laid_off, percentage_laid_off
FROM layoffs_backup2
ORDER BY total_laid_off DESC; -- exploring the total number of employees that were laid off and their percentage per company

SELECT company, COUNT(company) AS branch_num, SUM(total_laid_off), SUM(percentage_laid_off)
FROM layoffs_backup2
GROUP BY company
ORDER BY branch_num DESC; -- sum of total_laid_off and the total number of branches and their sum of percentage_laid_off from the date below

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_backup2; --  the above syntax shows the totals from 2020-03-11 to 2023-03-06
					  -- from this data, the laying offs could be of many reason but judging by the date range they could have also been afected by COVID 19


SELECT industry, SUM(total_laid_off)
FROM layoffs_backup2
GROUP BY industry
ORDER BY 2 DESC; -- the top industry have large number of total lay offs 


SELECT country, SUM(total_laid_off)
FROM layoffs_backup2
GROUP BY country
ORDER BY 2 DESC; -- sum of total laid off by country


SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_backup2
GROUP BY YEAR(`date`);	-- sum of total laid off by year


SELECT stage, SUM(total_laid_off)
FROM layoffs_backup2
GROUP BY stage
ORDER BY 2 DESC;  -- sum of total laid off by stage


SELECT *
FROM layoffs_backup2;

SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off)
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_backup2
WHERE  SUBSTRING(`date`, 1, 7) IS NOT NULL 
GROUP BY  SUBSTRING(`date`, 1, 7)
ORDER BY  1 ASC; -- sum of total laid off per month from start date


WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) total_off
FROM layoffs_backup2
WHERE  SUBSTRING(`date`, 1, 7) IS NOT NULL 
GROUP BY  SUBSTRING(`date`, 1, 7)
ORDER BY  1 ASC
)
SELECT `MONTH`, total_off, SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total; -- this is basically adding the next month and displays the rolling total of employees laid off around the countries in the data







