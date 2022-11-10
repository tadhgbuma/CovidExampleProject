select *
From CovidProject..CovidDeaths
order by 3,4

--select *
--From CovidProject..CovidVaccinations
--order by 3,4

--Select data that we are going to use

select location, date, total_cases, new_cases, total_deaths, population
From CovidProject..CovidDeaths
order by 1,2

--Looking at Total Cases vs Total Deaths
--Likelihood of dying from contracting Covid in the U.S.
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
From CovidProject..CovidDeaths
Where location like '%states%'
order by 1,2

--Looking at total cases vs population
--percentage of U.S. population that has had Covid
select location, date, total_cases, population, (total_cases/population)*100 AS case_percentage
From CovidProject..CovidDeaths
Where location like '%states%'
order by 1,2

--Looking at countries with highest infection rate compared to population
select location, population, MAX(total_cases) AS Total_Infection_Count, MAX((total_cases/population))*100 AS max_infection_percentage
From CovidProject..CovidDeaths
group by location, population
order by max_infection_percentage desc

--Highest death rate per population
select location, MAX(cast(total_deaths as int)) AS Total_Death_Count
From CovidProject..CovidDeaths
where continent is not null
group by location
order by Total_Death_Count desc

--Death count per continent
select location, MAX(cast(total_deaths as int)) AS Total_Death_Count_cont
From CovidProject..CovidDeaths
where continent is null
group by location
order by Total_Death_Count_cont desc

--Global Numbers
Select date, SUM(new_cases) AS CASES, SUM(cast(new_deaths as int)) AS DEATHS, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS death_percentage
From CovidProject..CovidDeaths
where continent is not null
group by date
order by 1

--Looking at total population vaccination rates

with PopVsVac (continent, location, date, population, new_vaccination, rolling_vaccincation_count) as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vaccination_count
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null
)
Select *, (rolling_vaccincation_count/population)*100 as vaccination_percentage
From PopVsVac
