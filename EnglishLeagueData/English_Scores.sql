Select *
From PortfolioProject..English_Scores
order by season desc

--add column to make it clearer which team won the game.
Alter Table PortfolioProject..English_Scores
Add winner nvarchar(255)

Update PortfolioProject..English_Scores
Set winner = Case When result = 'H' Then home
When result = 'A' Then visitor
else 'Draw' end

--tier and division are the same exact column, but division contains nulls, so I'm getting rid of it.
Alter Table PortfolioProject..English_Scores
Drop column division 

--add column containing absolute value of goal differential in order to calculate the average per game (on average, by how much does one team outscore the opponent).
Alter table PortfolioProject..English_Scores
Add goaldif_abs numeric

Update PortfolioProject..English_Scores
Set goaldif_abs = case when goaldif < 0 Then goaldif*(-1)
Else goaldif
End

--making tables of historical home and away records, as well as goals scored and conceded, in order to get a comprehensive view by season.
Create Table home_record
(team nvarchar(255), Season numeric, Hwins numeric, Hdraws numeric, Hlosses numeric, Hscored numeric, Hconceded numeric)

Insert into home_record
select distinct home, Season, sum(case when result = 'H' Then 1 Else 0 End), sum(case when result = 'D' Then 1 Else 0 End), sum(case when result = 'A' Then 1 Else 0 End), sum(hgoal), sum(vgoal)
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

--combining home and away records and computing league points and goal differential for each season, getting the final table for each season in the first tier.
With team_record (team, season, wins, draws, losses, goals_scored, goals_conceded)
as (
Select H.team, H.season, (H.Hwins + A.Awins), (H.Hdraws + A.Adraws), (H.Hlosses + A.Alosses), (H.Hscored+A.Ascored), (H.Hconceded + A.Aconceded)
From home_record H
Join away_record A
	ON H.team = A.team
	AND H.Season = A.Season
	)
select *, ((wins*3) + draws) as points, (goals_scored-goals_conceded) as goal_diff
from team_record
order by season desc, points desc

--looking at the overall record for these teams in the 1st tier of soccer.
With total_record (team, games_played, tot_wins, tot_draws, tot_losses, tot_scored, tot_conceded)
as (
Select H.team, (sum(H.Hwins + A.Awins) + sum(H.Hdraws + A.Adraws) + sum(H.Hlosses + A.Alosses)), sum(H.Hwins + A.Awins), sum(H.Hdraws + A.Adraws), sum(H.Hlosses + A.Alosses), sum(H.Hscored+A.Ascored), sum(H.Hconceded + A.Aconceded)
From home_record H
Join away_record A
	ON H.team = A.team
	AND H.Season = A.Season
	group by H.team
	)
Select *,tot_scored - tot_conceded as tot_goal_diff, (tot_wins/games_played)*100 as win_percentage, (tot_draws/games_played)*100 as draw_percentage, (tot_losses/games_played)*100 as loss_percentage
From total_record
order by tot_wins desc

--Calculating average goals scored and the average difference in score per game for each season.
Select Season, sum(totgoal) as Total_Season_Goals, Count(*) as Games_In_Season, sum(totgoal)/Count(*) as Avg_Goals_Per_Game, sum(goaldif_abs)/count(*) as Avg_Goal_Diff
From PortfolioProject..English_Scores
where tier=1
group by Season
order by Season desc