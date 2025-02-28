/*
COVID-19 Data Analysis

Key Skills Demonstrated:
- Advanced Joins
- Common Table Expressions (CTEs)
- Temporary Tables
- Window Functions
- Aggregate Functions
- Data Type Conversions
- View Creation
*/

-- Initial Dataset Exploration
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Base Dataset Selection
SELECT 
    location, 
    date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Mortality Analysis (Case Fatality Rate)
SELECT 
    location, 
    date, 
    total_cases,
    total_deaths,
    ROUND((NULLIF(total_deaths, 0) / NULLIF(total_cases, 0)) * 100, 2) AS case_fatality_rate_percent
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
    AND continent IS NOT NULL
ORDER BY location, date;

-- Infection Prevalence Analysis
SELECT 
    location, 
    date, 
    population,
    total_cases,
    ROUND((NULLIF(total_cases, 0) / NULLIF(population, 0)) * 100, 2) AS infection_prevalence_percent
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Country-level Infection Analysis
SELECT 
    location, 
    population,
    MAX(total_cases) AS peak_infection_count,
    MAX(ROUND((NULLIF(total_cases, 0) / NULLIF(population, 0)) * 100, 2)) AS peak_infection_rate_percent
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY peak_infection_rate_percent DESC;

-- Country-level Mortality Analysis
SELECT 
    location, 
    MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- Continental Mortality Analysis
SELECT 
    continent, 
    MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

-- Global Aggregates
SELECT 
    SUM(new_cases) AS global_cases,
    SUM(CAST(new_deaths AS INT)) AS global_deaths,
    ROUND((SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases), 0)) * 100, 2) AS global_death_rate_percent
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

-- Vaccination Progress Analysis Using CTE
WITH VaccinationProgress AS (
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS BIGINT)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS cumulative_vaccinations
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT 
    *,
    ROUND((cumulative_vaccinations / NULLIF(population, 0)) * 100, 2) AS vaccination_coverage_percent
FROM VaccinationProgress;

-- Vaccination Progress Using Temporary Table
DROP TABLE IF EXISTS #VaccinationMetrics;
CREATE TABLE #VaccinationMetrics (
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    cumulative_vaccinations NUMERIC
);

INSERT INTO #VaccinationMetrics
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS cumulative_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

SELECT 
    *,
    ROUND((cumulative_vaccinations / NULLIF(population, 0)) * 100, 2) AS vaccination_coverage_percent
FROM #VaccinationMetrics;

-- Create View for Visualization
CREATE VIEW VaccinationProgressView AS
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS cumulative_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
