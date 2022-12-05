Select *
From PortfolioProject..Street_Trees

--Looks like the coordinates are backwards and need to be split.
Alter Table PortfolioProject..Street_Trees
Add latitude nvarchar(255);

Alter Table PortfolioProject..Street_Trees
Add longitude nvarchar(255)

alter table PortfolioProject..Street_Trees
Add coordinates nvarchar(255)

Update PortfolioProject..Street_Trees
Set coordinates = SUBSTRING(Geometry, 7, CHARINDEX(')', Geometry))

Update PortfolioProject..Street_Trees
Set latitude = SUBSTRING(coordinates, CHARINDEX(' ', coordinates) + 1, CHARINDEX(')', coordinates) - CHARINDEX(' ', coordinates) -1)

Update PortfolioProject..Street_Trees
Set longitude = SUBSTRING(coordinates, 2, CHARINDEX(' ', coordinates) -1)

--Remove Nulls from Street_name for the tableau map filter
Update PortfolioProject..Street_Trees
Set Street_Name = Case when Street_Name is null then 'Not Listed'
else Street_Name
end

--Looking at trees information broken down by species, location and diameter
Select latitude, longitude, street_name, Species_Short, Diameter
From PortfolioProject..Street_Trees
Where Site_Type ='Tree'
AND Species_Short is not null
and Diameter > 0
and Diameter < 70
and Removal_Date is null
order by Diameter desc

Select Distinct(Species_short), Count(Species_Short) as species_count, avg(diameter) as avg_diameter, max(diameter) as max_diameter, min(diameter) as min_diameter
From PortfolioProject..Street_Trees
Where Site_Type ='Tree'
AND Species_Short is not null
and Diameter > 0
and Diameter < 70 -- seems to be the cutoff point of accurate trunk measurements
and Removal_Date is null
group by Species_short
order by species_count desc

Select sum(case when Diameter > 0 And Diameter <=5 Then 1 Else 0 end) AS '0-5',
sum(case when Diameter >5 And Diameter <=10 Then 1 Else 0 end) AS '5-10',
sum(case when Diameter >10 And Diameter <=15 Then 1 Else 0 end) AS '10-15',
sum(case when Diameter >15 And Diameter <=20 Then 1 Else 0 end) AS '15-20',
sum(case when Diameter >20 And Diameter <=25 Then 1 Else 0 end) AS '20-25',
sum(case when Diameter >25 And Diameter <=30 Then 1 Else 0 end) AS '25-30',
sum(case when Diameter >30 And Diameter <=35 Then 1 Else 0 end) AS '30-35',
sum(case when Diameter >35 And Diameter <=40 Then 1 Else 0 end) AS '35-40',
sum(case when Diameter >40 And Diameter <=45 Then 1 Else 0 end) AS '40-45',
sum(case when Diameter >45 And Diameter <=50 Then 1 Else 0 end) AS '45-50',
sum(case when Diameter >50 And Diameter <=55 Then 1 Else 0 end) AS '50-55',
sum(case when Diameter >55 Then 1 Else 0 end) AS '>55'
From PortfolioProject..Street_Trees
where Site_Type ='Tree'
AND Species_Short is not null
and Diameter < 70
and Removal_Date is null

Select Street_name, count(street_name) as trees_per_street
From PortfolioProject..Street_Trees
Where Site_Type ='Tree'
AND Species_Short is not null
and Removal_Date is null
and Street_name is not null
and Diameter > 0 
and Diameter < 70
group by Street_name
order by trees_per_street desc
