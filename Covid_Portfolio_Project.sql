SELECT *
FROM coviddeaths

ORDER BY 3, 4;  -- sorted value by third column and fort column

-- Select Data 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY 1,2;

-- Total Cases vs Total Deaths -> Show likelihood of dying if you contract covid in your country
SELECT location, STR_TO_DATE(date, '%m/%d/%y') AS date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage -- How many people die from the total cases
FROM coviddeaths
WHERE location like '%states%'
ORDER BY 1, 2;

-- The dates are in a string format and are being sorted based on their string values, rather than their date values.

-- Total Cases vs Population -> Shows what percentage of population got Covid
SELECT Location, STR_TO_DATE(date, '%m/%d/%y') AS date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM coviddeaths
WHERE location like '%states%'
ORDER BY 1, 2;

-- Countries with highest infection rate compared to population
SELECT Location, population, MAX(CAST(COALESCE(total_cases, '0') AS SIGNED)) AS HighestTotalCasesCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM coviddeaths
GROUP BY Location, population -- Include all the columns that are not used with aggreagate function
ORDER BY PercentPopulationInfected DESC;

-- We need to convert data type to int in order to get the right result -> We use COALESCE to replace NaN with 0 and change data type to integer by using CAST with SIGNE
-- Showing continent with highest death count per population
SELECT continent, MAX(CAST(COALESCE(total_deaths, '0') AS SIGNED)) AS TotalDeathCount  -- The SIGNED keyword in MySQL refers to the signed integer data type, which can store both positive and negative whole numbers
FROM coviddeaths
WHERE continent IS NOT NULL AND continent != ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Showing countries with highest death count per population
SELECT Location, MAX(CAST(COALESCE(total_deaths, '0') AS SIGNED)) AS TotalDeathCount  -- The SIGNED keyword in MySQL refers to the signed integer data type, which can store both positive and negative whole numbers
FROM coviddeaths
WHERE Location NOT IN('High income', 'Europe', 'North America', 'South America', 'European Union') -- exclude High income
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-- Global death percentage by day
SELECT STR_TO_DATE(date, '%m/%d/%y') AS date, SUM(new_cases) AS total_cases, SUM(CAST(COALESCE(new_deaths, '0') AS SIGNED)) AS total_deaths,SUM(CAST(COALESCE(new_deaths, '0') AS SIGNED))/SUM(new_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL AND continent != ''
GROUP BY date
ORDER BY 1, 2;

-- Global death percentage 
SELECT SUM(new_cases) AS total_cases, SUM(CAST(COALESCE(new_deaths, '0') AS SIGNED)) AS total_deaths,SUM(CAST(COALESCE(new_deaths, '0') AS SIGNED))/SUM(new_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL AND continent != ''
ORDER BY 1, 2;


-- Total population vs vaccination
-- PARTITION BY -> cumulative value
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(COALESCE(vac.new_vaccinations, '0') AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS CumulativeVaccinated
FROM coviddeaths as dea
JOIN covidvaccinations as vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent != ''
ORDER BY 2,3;

-- Use CTE to find %Vaccination by population
WITH popvsvac (continent, location, date, population, new_vaccinations, CumulativeVaccinated) -- every column from subqueries should be the same with CTE(Common Table Expression
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(COALESCE(vac.new_vaccinations, '0') AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS CumulativeVaccinated
FROM coviddeaths as dea
JOIN covidvaccinations as vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent != ''
) -- you can use normal order by with CTE
SELECT *, (CumulativeVaccinated/population)*100 AS VaccinatedPercentage
FROM popvsvac 

-- TEMP TABLE 
DROP TABLE percentpopulationvaccianted;
CREATE TABLE percentpopulationvaccianted
(
continent varchar(255),
location varchar(255), 
date datetime,
population numeric, 
new_vaccinations numeric, 
cumulativeVaccinated numeric
);

-- CASE WHEN...THEN...END= IF-ELSE

INSERT INTO percentpopulationvaccianted
SELECT dea.continent, dea.location, 
       STR_TO_DATE(dea.date, '%m/%d/%y') AS date,
       dea.population, 
       CASE WHEN vac.new_vaccinations = '' OR vac.new_vaccinations IS NULL THEN '0' ELSE vac.new_vaccinations END, 
       SUM(CAST(CASE WHEN vac.new_vaccinations = '' OR vac.new_vaccinations IS NULL THEN '0' ELSE vac.new_vaccinations END AS SIGNED)) 
       OVER (PARTITION BY dea.location ORDER BY dea.location, STR_TO_DATE(dea.date, '%m/%d/%y')) AS CumulativeVaccinated
FROM coviddeaths as dea
JOIN covidvaccinations as vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent != '';

SELECT *, (CumulativeVaccinated/population)*100 AS VaccinatedPercentage
FROM percentpopulationvaccianted; 

-- Creating view to store data for later
CREATE VIEW populationvaccianted AS 
SELECT dea.continent, dea.location, 
       STR_TO_DATE(dea.date, '%m/%d/%y') AS date,
       dea.population, 
       CASE WHEN vac.new_vaccinations = '' OR vac.new_vaccinations IS NULL THEN '0' ELSE vac.new_vaccinations END, 
       SUM(CAST(CASE WHEN vac.new_vaccinations = '' OR vac.new_vaccinations IS NULL THEN '0' ELSE vac.new_vaccinations END AS SIGNED)) 
       OVER (PARTITION BY dea.location ORDER BY dea.location, STR_TO_DATE(dea.date, '%m/%d/%y')) AS CumulativeVaccinated
FROM coviddeaths as dea
JOIN covidvaccinations as vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent != '';
