/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/




select * from sqlproject..covidDeaths
where continent is not null
order by 3,4



-- Select Data that we are going to be starting with

select location, date, total_cases, new_cases, total_deaths, population
from sqlproject..covidDeaths
where continent is not null
order by 1,2



-- Total cases vs Total deaths
-- Shows likelihood of dying if you contract covid in your country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from sqlproject..covidDeaths
where location='india' and continent is not null
order by 1,2




-- Total Cases vs Population
-- Shows what percentage of population got covid
select location, date, population, total_cases, (total_cases/population)*100 as CasesPercentage
from sqlproject..covidDeaths
where location='india' and continent is not null
order by 1,2




-- Countries with Highest Infection Rate compared to Population

select location, population, max(total_cases) as HighestCaseCount, max((total_cases/population))*100 as InfectPercentage
from sqlproject..covidDeaths
where continent is not null
group by location, population
order by InfectPercentage desc



-- Countries with Highest Death Count

select location, max(cast(total_deaths as int)) as TotalDeathCount
from sqlproject..covidDeaths
where continent is not null
group by location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Continent with Highest Death Count By Continent

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from sqlproject..covidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc




-- Global numbers

select SUM(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
(sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage
from sqlproject..covidDeaths
where continent is not null
--group by date
order by 1,2




-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location, cd.date) as RollingPeopleVaccinated
from sqlproject..covidDeaths cd
join sqlproject..covidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
order by 2, 3


-- Using CTE to perform Calculation on Partition By in previous query

with PopVsVac(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location, cd.date) as RollingPeopleVaccinated
from sqlproject..covidDeaths cd
join sqlproject..covidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
)

select *, (RollingPeopleVaccinated/population)*100 as  RollingPeopleVaccinatedPercentage
from PopVsVac
order by 2, 3





-- Using Temp Table to perform Calculation on Partition By in previous query

drop table if exists #PopulationVaccinated
create table #PopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)

insert into #PopulationVaccinated
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location, cd.date) as RollingPeopleVaccinated
from sqlproject..covidDeaths cd
join sqlproject..covidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null


select *, (RollingPeopleVaccinated/population)*100
from #PopulationVaccinated
order by 2, 3




-- Creating View to store data for later visualizations

create view PopulationVaccinated as
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location, cd.date) as RollingPeopleVaccinated
from sqlproject..covidDeaths cd
join sqlproject..covidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
