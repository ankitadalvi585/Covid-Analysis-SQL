/*
Covid Data Exploration 

Skills used: Aggregate Functions, Changes in Datatype, Joins, Window functions, Common Table expression(cte), Temp table, Views

*/

--We are only taking into account data for analysis if the continent value is available.

Select *
From CovidDeaths
Where continent is not null 
order by location, date

-- DeathRate : Calculating percentage of covid cases who died which shows likelihood of dying if you get infected with covid

Select location, date, total_cases, total_deaths,
cast((total_deaths/total_cases)*100 as decimal(10,2)) as DeathRate
From CovidDeaths
Where continent is not null 
order by location, date


-- InfectionRate : Calculating percentage of population infected with Covid

Select location, date, population, total_cases, cast((total_cases/population)*100 as decimal(10,2)) as InfectionRate
From CovidDeaths
Where continent is not null 
order by location,date


-- Countries with Highest Infection Rate compared to Population

Select location, population, 
MAX(total_cases) as HighestInfectionCount,  Max(cast((total_cases/population)*100 as decimal(10,2))) as InfectionRate
From CovidDeaths
Where continent is not null
Group by Location, Population
order by InfectionRate desc


-- Countries with Highest Death Count 

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- Global Numbers
Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
From CovidDeaths
where continent is not null 


-- Total number of vaccinations done 
Select continent, location, date, new_vaccinations
, SUM(new_vaccinations) OVER (Partition by Location Order by location, Date) as PeopleVaccinated
From  CovidVaccinations 
where continent is not null 
order by location, date desc


--Calculate percentage of population fully vaccinated for each location

-- Using CTE 
With cte (Continent, Location, Date, Population, PeoplefullyVaccinated,rownum)
as
(
Select d.continent, d.location, d.date, d.population, v.people_fully_vaccinated
, row_number() OVER (Partition by d.Location Order by v.people_fully_vaccinated desc) as rownum
From CovidDeaths d
Join CovidVaccinations v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null 
--order by 2,3 desc
)
Select Continent,Location,Date, Population,PeoplefullyVaccinated,(PeoplefullyVaccinated/Population)*100 as PercentPopulationVaccinated
From cte 
where rownum=1
order by Continent,Location 

-- Using Temp Table to performing above analysis

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
PeoplefullyVaccinated numeric,
rownum numeric
)

Insert into #PercentPopulationVaccinated
Select d.continent, d.location, d.date, d.population, v.people_fully_vaccinated
, row_number() OVER (Partition by d.Location Order by v.people_fully_vaccinated desc) as rownum
From CovidDeaths d
Join CovidVaccinations v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null
--order by 2,3

Select Continent,Location,Date, Population,PeoplefullyVaccinated,
(PeoplefullyVaccinated/Population)*100 as PercentPopulationVaccinated
From #PercentPopulationVaccinated 
where rownum=1
order by Continent,Location


-- Creating View to store data for vaccinations data of various locations 
Create View PercentPopulationVaccinated as
With cte (Continent, Location, Date, Population, PeoplefullyVaccinated,rownum)
as
(
Select d.continent, d.location, d.date, d.population, v.people_fully_vaccinated
, row_number() OVER (Partition by d.Location Order by v.people_fully_vaccinated desc) as rownum
From CovidDeaths d
Join CovidVaccinations v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null 
--order by 2,3 desc
)
Select Continent,Location,Date, Population,PeoplefullyVaccinated,(PeoplefullyVaccinated/Population)*100 as PercentPopulationVaccinated
From cte 
where rownum=1

--Retrieving data from the view created above
--Select * from PercentPopulationVaccinated

