/*
	DATA TYPE CONVERTION FUNCTIONS
	SYNTAX
		1) CONVERT(<data_type>, <column_name>)
		2) CAST(<column_name> AS <data_type>)
*/


Select * from CovidDeaths
WHERE continent IS NOT NULL
Order by 3,4

--Select * from CovidVaccinations
--Order by 3,4

-- --> SELECTED DATA THAT WE ARE GOING TO BE USING
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

-- --> TOTAL CASES VS TOTAL DEATHS
-- Shows likelihood of dying if you contract COVID in your country
SELECT location, date, total_cases, total_deaths, 
	CAST((total_deaths /CAST(total_cases AS FLOAT))*100 AS DECIMAL(10,2)) AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%Costa Rica%'
ORDER BY 1,2

-- --> TOTAL CASES VS POPULATION
-- shows what percentage of population got COVID
SELECT location, date, population, total_cases, 
	CAST((total_cases /CAST(population AS FLOAT))*100 AS DECIMAL(10,2)) AS InfectedPopulationPerc
FROM CovidDeaths
WHERE location LIKE '%Costa Rica%'
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
	CAST(MAX(total_cases /CAST(population AS FLOAT))*100 AS DECIMAL(10,2)) AS InfectedPopulationPerc
FROM CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC

-- Showing Countries with Highest Death Count per Population
SELECT location, population, MAX(total_deaths) AS TotalDeathCount, 
	CAST(MAX(total_deaths /CAST(population AS FLOAT))*100 AS DECIMAL(10,2)) AS TotalDeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing Continents with Highest Death Count per Population
SELECT location, MAX(total_deaths) AS TotalDeathCount, 
	CAST(MAX(total_deaths /CAST(population AS FLOAT))*100 AS DECIMAL(10,5)) AS TotalDeathPercentage
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
-- Total new cases around the world vs total new deaths and the percentage BY DATE
SELECT date, SUM(new_cases) AS SumNewCases, SUM(new_deaths) AS SumNewDeaths,
	CAST((SUM(new_deaths) /CAST(SUM(new_cases) AS FLOAT))*100 AS DECIMAL(10,2)) AS PercentGlobalDeathByDay
FROM CovidDeaths
--WHERE location LIKE '%Costa Rica%'
WHERE continent IS NOT NULL AND new_cases IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Total cases around the world vs total deaths and the percentage.
SELECT SUM(new_cases) AS SumNewCases, SUM(new_deaths) AS SumNewDeaths,
	CAST((SUM(new_deaths) /SUM(CONVERT(FLOAT,new_cases)))*100 AS DECIMAL(10,2)) AS GlobalDeathPercentage
FROM CovidDeaths
--WHERE location LIKE '%Costa Rica%'
WHERE continent IS NOT NULL AND new_cases IS NOT NULL
--GROUP BY date
ORDER BY 1,2


-- Looking a Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	-- add the result of the following operation (RollingPeopleVaccinated/population)*100 as a column
	-- but, first we need to either use a CTE or a TempTable, by creating 'RollingPeopleVaccinated' we will be able to access it later
FROM CovidDeaths dea JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- CTE version for 'RollingPeopleVaccinated'
WITH Pop_Vac_CTE (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/CONVERT(FLOAT,population))*100 AS PopulationVaccinationPercentage
FROM Pop_Vac_CTE

-- Temp Table version for 'RollingPeopleVaccinated'
DROP TABLE IF EXISTS #Percent_Population_Vaccinated
CREATE TABLE #Percent_Population_Vaccinated(
	continent varchar(50),
	location varchar(50),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	rollingPeopleVaccinated numeric
)
INSERT INTO #Percent_Population_Vaccinated 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- END TEMP TABLE ---------------------------------------

SELECT *, (RollingPeopleVaccinated/CONVERT(FLOAT,population))*100 AS PopulationVaccinationPercentage
FROM #Percent_Population_Vaccinated 

-- CREATING A VIEW FOR STORING DATA AND LATER VISUALIZATIONS

-- VIEW #1
CREATE VIEW Percent_Population_Vaccinated AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

-- VIEW #2
CREATE VIEW Percent_Continents_Death_Count AS
SELECT location, MAX(total_deaths) AS TotalDeathCount, 
	CAST(MAX(total_deaths /CAST(population AS FLOAT))*100 AS DECIMAL(10,5)) AS TotalDeathPercentage
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
--ORDER BY TotalDeathCount DESC

-- VIEW #3
CREATE VIEW Percent_Global_Death_ByDay AS
SELECT date, SUM(new_cases) AS SumNewCases, SUM(new_deaths) AS SumNewDeaths,
	CAST((SUM(new_deaths) /CAST(SUM(new_cases) AS FLOAT))*100 AS DECIMAL(10,2)) AS PercentGlobalDeathByDay
FROM CovidDeaths
--WHERE location LIKE '%Costa Rica%'
WHERE continent IS NOT NULL AND new_cases IS NOT NULL
GROUP BY date
--ORDER BY 1,2