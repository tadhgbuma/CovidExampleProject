## load necessary packages

library(tidyverse)
library(lubridate)
library(ggplot2)
library(readr)

## set the working directory
getwd()
setwd("/Users/likea/OneDrive/Desktop/Cyclist_Case_Study")

## load the csv files
june_2021 <- read_csv("2021-06-divvy-tripdata-cleaned.csv")
july_2021 <- read_csv("2021-07-divvy-tripdata-cleaned.csv")
august_2021 <- read_csv("2021-08-divvy-tripdata-cleaned.csv")
september_2021 <- read_csv("2021-09-divvy-tripdata-cleaned.csv")
october_2021 <- read_csv("2021-10-divvy-tripdata-cleaned.csv")
november_2021 <- read_csv("2021-11-divvy-tripdata-cleaned.csv")
december_2021 <- read_csv("2021-12-divvy-tripdata-cleaned.csv")
january_2022 <- read_csv("2022-01-divvy-tripdata-cleaned.csv")
february_2022 <- read_csv("2022-02-divvy-tripdata-cleaned.csv")
march_2022 <- read_csv("2022-03-divvy-tripdata-cleaned.csv")
april_2022 <- read_csv("2022-04-divvy-tripdata-cleaned.csv")
may_2022 <- read_csv("2022-05-divvy-tripdata-cleaned.csv")

## check to make sure the column names and data types match for each data set
colnames(june_2021)
colnames(july_2021)
colnames(august_2021)
colnames(september_2021)
colnames(october_2021)
colnames(november_2021)
colnames(december_2021)
colnames(january_2022)
colnames(february_2022)
colnames(march_2022)
colnames(april_2022)
colnames(may_2022)

str(june_2021)
str(july_2021)
str(august_2021)
str(september_2021)
str(october_2021)
str(november_2021)
str(december_2021)
str(january_2022)
str(february_2022)
str(march_2022)
str(april_2022)
str(may_2022)

## combine each month into a single dataframe
all_trips <- bind_rows(june_2021, july_2021, august_2021, september_2021, october_2021, november_2021, december_2021, january_2022, february_2022, march_2022, april_2022, may_2022)
head(all_trips)

## remove columns that are not relevant to analysis
all_trips <- all_trips %>% 
	select(-c(start_lat, start_lng, end_lat, end_lng))

## check for inconsistent row values in member_casual
all_trips %>% filter(member_casual != "member" && member != "casual")

## preview data frame for further cleaning
head(all_trips)
tail(all_trips)
summary(all_trips)
str(all_trips)

## creating time of day, month, day, and year columns to group individual ride data
all_trips$date <- mdy_hm(all_trips$started_at, tz=Sys.timezone())
all_trips$time <- format(as.POSIXct(all_trips$date), "%H")
all_trips$month <- format(as.Date(all_trips$date), "%m")
all_trips$day <- format(as.Date(all_trips$date), "%d")
all_trips$year <- format(as.Date(all_trips$date), "%Y")

## create a column for end of trip time for consistent format in order to calculate ride length
all_trips$date_end <- mdy_hm(all_trips$ended_at, tz=Sys.timezone())

## calculate ridelength and converting to numeric
all_trips$ride_length <- difftime(all_trips$date_end, all_trips$date)
is.factor(all_trips$ride_length)
all_trips$ride_length <- as.numeric(as.character(all_trips$ride_length))
is.numeric(all_trips$ride_length)

## remove inconsistent rows with negative ride length
all_trips_2 <- all_trips[!(all_trips$ride_length<0),]

## checking the min, median, mean, and max of overall ride lengths, ride length by membership type, and by membership type and day of the week (1=Sunday and 7=Saturday)
summary(all_trips_2$ride_length)

aggregate(all_trips_2$ride_length ~ all_trips_2$member_casual, FUN=mean)
aggregate(all_trips_2$ride_length ~ all_trips_2$member_casual, FUN=median)
aggregate(all_trips_2$ride_length ~ all_trips_2$member_casual, FUN=max)
aggregate(all_trips_2$ride_length ~ all_trips_2$member_casual, FUN=min)

aggregate(all_trips_2$ride_length ~ all_trips_2$member_casual + all_trips_2$day_of_week, FUN = mean)

## create a data frame of num of rides and avg duration of ride by both user types, grouped by day of the week
count_week <- all_trips_2 %>% 
group_by(member_casual, day_of_week) %>% 
summarise(number_of_rides=n(), average_duration=mean(ride_length))


## visualising num of rides and average ride length using ggplot
count_week %>% 
  ggplot(aes(x = day_of_week, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge")

count_week %>% 
  ggplot(aes(x = day_of_week, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge")


## another data frame, this time grouped by month instead of day of the week
count_month <- all_trips_2 %>% 
group_by(member_casual, month, year) %>% 
summarise(number_of_rides=n(), average_duration=mean(ride_length))

## visualizing data grouped by month
count_month %>% 
  ggplot(aes(x = month, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge")

count_month %>% 
  ggplot(aes(x = month, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge")

## one more data frame, now grouped by the starting time of the bike ride
count_start_time <- all_trips_2 %>% 
group_by(member_casual, time) %>% 
summarise(number_of_rides=n(), average_duration=mean(ride_length))

count_start_time %>% 
  ggplot(aes(x = time, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge")

## export the new data frames as csv files for further analysis and visualisation in Tableau
write.csv(count_week, file='C:/Users/likea/OneDrive/Desktop/Cyclist_Case_Study/count_week.csv')
write.csv(count_month, file='C:/Users/likea/OneDrive/Desktop/Cyclist_Case_Study/count_month.csv')
write.csv(count_start_time, file='C:/Users/likea/OneDrive/Desktop/Cyclist_Case_Study/count_start_time.csv')


