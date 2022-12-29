Select *
From PortfolioProject..English_Scores
order by season desc

--add column to make it clearer which team won the game.
Alter Table PortfolioProject..English_Scores
Add winner nvarchar(255)
Add loser nvarchar(255)

Update PortfolioProject..English_Scores
Set winner = Case When result = 'H' Then home
When result = 'A' Then visitor
else 'Draw' end,
loser = Case When result = 'H' Then visitor
When result = 'A' Then home
else 'Draw' end

--tier and division are the same exact column, but division contains nulls, so I'm getting rid of it.
Alter Table PortfolioProject..English_Scores
Drop column division 

Update PortfolioProject..English_Scores
Set goaldif_abs = case when goaldif < 0 Then goaldif*(-1)
Else goaldif
End

--making tables of historical home and away records, as well as goals scored and conceded, in order to get a comprehensive view by season.
Drop table if exists home_record, away_record
Create Table home_record
(team nvarchar(255), Season numeric, Hwins numeric, Hdraws numeric, Hlosses numeric, Hscored numeric, Hconceded numeric)

Insert into home_record
select home, Season, sum(case when result = 'H' Then 1 Else 0 End), sum(case when result = 'D' Then 1 Else 0 End), sum(case when result = 'A' Then 1 Else 0 End), sum(hgoal), sum(vgoal)
From PortfolioProject..English_Scores
Where Tier = 1
Group by home, Season
Order by Season Desc

Create Table away_record
(team nvarchar(255), Season numeric, Awins numeric, Adraws numeric, Alosses numeric, Ascored numeric, Aconceded numeric)

Insert into away_record
select distinct visitor, Season, sum(case when result = 'A' Then 1 Else 0 End), sum(case when result = 'D' Then 1 Else 0 End), sum(case when result = 'H' Then 1 Else 0 End), sum(vgoal), sum(hgoal)
From PortfolioProject..English_Scores
Where Tier = 1
Group by visitor, Season
Order by Season Desc

--combining home and away records and computing league points and goal differential for each season, getting the final table for each season in the first tier, including win percentage and avg goals per game.
With team_record (team, season, wins, draws, losses, points, goals_scored, goals_conceded, goal_difference)
as (
Select distinct H.team, H.season, (H.Hwins + A.Awins), (H.Hdraws + A.Adraws), (H.Hlosses + A.Alosses), ((H.Hwins + A.Awins)*3 + (H.Hdraws + A.Adraws)), (H.Hscored+A.Ascored), (H.Hconceded + A.Aconceded), ((H.Hscored+A.Ascored)-(H.Hconceded + A.Aconceded))
From home_record H
Join away_record A
	ON H.team = A.team
	AND H.Season = A.Season
	)
select *, goals_scored/(wins+draws+losses) as avg_goals_per_game, (wins+(0.5*draws))/(wins+draws+losses) as win_percentage, RANK() Over ( Partition By Season Order By points Desc, goal_difference Desc) as league_position 
from team_record
order by season desc, points desc

--looking at the overall best records for teams in the 1st tier of soccer.
With total_record (team, games_played, tot_wins, tot_draws, tot_losses, tot_scored, tot_conceded)
as (
Select H.team, (sum(H.Hwins + A.Awins) + sum(H.Hdraws + A.Adraws) + sum(H.Hlosses + A.Alosses)), sum(H.Hwins + A.Awins), sum(H.Hdraws + A.Adraws), sum(H.Hlosses + A.Alosses), sum(H.Hscored+A.Ascored), sum(H.Hconceded + A.Aconceded)
From home_record H
Join away_record A
	ON H.team = A.team
	AND H.Season = A.Season
	group by H.team
	)
Select top 10 *, tot_scored/games_played as avg_goals_per_game, tot_scored - tot_conceded as tot_goal_diff, ((tot_wins + (0.5*tot_draws))/games_played)*100 as win_percentage
from total_record
order by win_percentage desc

--Creating a view of Manchester United vs Manchester City for Data visualisation
Select Season, sum(case when winner = 'Manchester City' and loser = 'Manchester United' then 1 else 0 end) as City_Wins, 
sum(case when winner='Manchester United' and loser='Manchester City' then 1 else 0 end) as MU_Wins, 
sum(case when winner = 'Draw' and home = 'Manchester United' and visitor = 'Manchester City' then 1
	when winner = 'Draw' and home = 'Manchester City' and visitor = 'Manchester United' then 1 
	else 0 end) as Draws,
sum(case when home = 'Manchester City' and visitor = 'Manchester United' then hgoal 
	when home = 'Manchester United' and visitor = 'Manchester City' then vgoal 
	else 0 end) as City_Goals,
sum(case when home = 'Manchester United' and visitor = 'Manchester City' then hgoal 
	when home = 'Manchester City' and visitor = 'Manchester United' then vgoal 
	else 0 end) as MU_Goals
From PortfolioProject..English_Scores
Where tier=1
group by Season
order by Season desc
