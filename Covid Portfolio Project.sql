SELECT*FROM portfolio_project..vaccination --checking the tables

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM portfolio_project..death
ORDER BY location asc,date 

--Looking for Total cases vs Total death
--shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_rate
FROM portfolio_project..death
WHERE location Like '%states'
ORDER BY death_rate DESC OFFSET 0 ROWS FETCH FIRST 10 ROWS ONLY

--Looking at Total cases vs population
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infection_rate
FROM portfolio_project..death
ORDER BY infection_rate DESC 

--Looking at countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM portfolio_project..death
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC 


--Showing Countries with Highest Death Count per Population
SELECT location, MAX(total_deaths) AS HighestDeathCount
FROM portfolio_project..death
WHERE continent is NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC 

--LET'S BREAK THINGS DOWN BY CONTINENT
SELECT continent, MAX(cast(total_deaths AS int)) AS totaldeathcount
FROM portfolio_project..death
WHERE continent is not null
GROUP BY continent 
ORDER BY totaldeathcount DESC

--GLOBAL NUMBERS
SELECT  date, SUM(new_cases),SUM(cast(new_deaths AS int)), 
SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS death_rate
FROM portfolio_project..death
WHERE continent is not null
GROUP BY date
ORDER BY death_rate DESC


--vaccination Table join with death table
SELECT *FROM 
portfolio_project..death AS dea
join
portfolio_project..vaccination AS vac
ON dea.location=vac.location
AND dea.date=vac.date

-- Total Population Vs Vaccination
SELECT dea.continent, dea.location,dea.date,dea.population, vac.new_vaccinations, 
SUM(convert(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location 
ORDER BY dea.location,dea.date) AS rollingpeoplevaccinated
--(rollingpeoplecaccinated/dea.population)*100
FROM portfolio_project..death AS dea
JOIN
portfolio_project..vaccination AS vac
ON dea.location=vac.location
AND dea.date=vac.date
WHERE dea.continent is not Null 
ORDER BY 2,3

--cte

WITH popvsVac(continant,location,date,population,new_vaccinations,rollingpeoplevaccinated)
AS
(
SELECT dea.continent, dea.location,dea.date,dea.population, vac.new_vaccinations, 
SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) AS rollingpeoplevaccinated
--(rollingpeoplecaccinated/dea.population)*100
FROM portfolio_project..death AS dea
JOIN
portfolio_project..vaccination AS vac
ON dea.location=vac.location
AND dea.date=vac.date
WHERE dea.continent is not Null 

)
SELECT * ,(rollingpeoplevaccinated/population)*100
FROM popvsVac

--Temp table
DROP TABLE IF EXISTS #percent_rollingpeoplevaccinated
CREATE TABLE #percent_rollingpeoplevaccinated(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)

INSERT INTO #percent_rollingpeoplevaccinated

SELECT dea.continent, dea.location,dea.date,dea.population, vac.new_vaccinations, 
SUM(convert(numeric,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) 
AS rollingpeoplevaccinated
--(rollingpeoplecaccinated/dea.population)*100
FROM portfolio_project..death AS dea
JOIN
portfolio_project..vaccination AS vac
ON dea.location=vac.location
AND dea.date=vac.date
WHERE dea.continent is not Null 



SELECT * ,(rollingpeoplevaccinated/population)*100
FROM #percent_rollingpeoplevaccinated

--Creating View to store data for later
CREATE VIEW percentpopulationvaccinated 
AS
SELECT dea.continent, dea.location,dea.date,dea.population, vac.new_vaccinations, 
SUM(convert(numeric,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) AS rollingpeoplevaccinated
--(rollingpeoplecaccinated/dea.population)*100
FROM portfolio_project..death AS dea
JOIN
portfolio_project..vaccination AS vac
ON dea.location=vac.location
AND dea.date=vac.date
WHERE dea.continent is not Null 

SELECT *FROM percentpopulationvaccinated