

--1 RFM Model
WITH Cte_Recency_Monetary AS (
					SELECT Name
					, PLATFORM
					, Year_of_Release
					, CASE
					  WHEN DATEDIFF(YEAR,Year_of_Release,GETDATE()) < 10
					  THEN 5
					  WHEN DATEDIFF(YEAR,Year_of_Release,GETDATE()) < 20
					  THEN 4
					  WHEN DATEDIFF(YEAR,Year_of_Release,GETDATE()) < 30
					  THEN 3
					  WHEN DATEDIFF(YEAR,Year_of_Release,GETDATE()) < 40
					  THEN 2
					  ELSE 1
					  END AS Game_Score_Status
					  , SUM(Global_Sales) AS 'Global_Sales_Per_Game_Platform'
					FROM video_games
					WHERE Year_of_Release IS NOT NULL
					GROUP BY Name, PLATFORM, Year_of_Release
					                                        ),
Cte_Frequency AS (
				 SELECT Name 
			    , COUNT(NAME) AS 'Game_Number_Platforms'
			    , CASE
				  WHEN COUNT(NAME) > 8
				  THEN 5
				  WHEN COUNT(NAME) > 6
				  THEN 4
				  WHEN COUNT(NAME) > 4
				  THEN 3
				  WHEN COUNT(NAME) > 2
				  THEN 2
				  ELSE 1
				  END AS Platform_Frequency_Status
				 FROM video_games
				 WHERE Name IS NOT NULL
				 GROUP BY Name
				              )
--QUERY
SELECT CRM.Name
, CRM.Platform
, CRM.Year_of_Release
, ROUND((CRM.Game_Score_Status * 0.3) + (CF.Platform_Frequency_Status * 0.4) + (CRM.Global_Sales_Per_Game_Platform * 0.3), 2) AS Final_RFM_Score
FROM Cte_Recency_Monetary CRM INNER JOIN Cte_Frequency CF
ON CRM.Name = CF.Name
ORDER BY  Final_RFM_Score DESC              



			 


-- 2a.How many games have been released with 3 or more Platforms?


SELECT Name
, COUNT(Name) AS 'Number_Of_Platform'
FROM video_games
GROUP BY Name
HAVING COUNT(Name) >= 3



-- 2b.In which year were the highest number of Genres at their peak ? Please find the Year & The Genres

--CTE
WITH Cte_t1 AS 
         (
          SELECT *
		 , RANK () OVER (PARTITION BY Genre ORDER BY Geners_PerYear DESC) AS rn
		  FROM (  SELECT Genre
		         , Year_of_Release
		         , COUNT(Genre) AS 'Geners_PerYear'
		         FROM video_games
		         WHERE Genre IS NOT NULL AND Year_of_Release IS NOT NULL
		         GROUP BY Genre , Year_of_Release ) AS tbl
				                                          )
		
--QUERY
SELECT Genre
, Year_of_Release
, Geners_PerYear
FROM Cte_t1
WHERE rn = 1



-- 3. Calculate the weighted average, normal Average, and the mode of critic_score per rating. Please present all numbers rounded with 1 decimal point. Which two ratings have the same values for all three measures? Please explain why

--Cte
WITH
Cte_Mode AS 
               (
				SELECT *
				, RANK () OVER (PARTITION BY Rating ORDER BY Critic_Score_CountPerRating DESC) AS RnMode
				FROM (SELECT Rating
					, Critic_Score
					, COUNT(Critic_Score) AS 'Critic_Score_CountPerRating'
					 FROM video_games
					 WHERE Rating IS NOT NULL AND Critic_Score IS NOT NULL 
					 GROUP BY Rating , Critic_Score ) AS Tbl_Mode
                                                                   ),
Cte_AVG_WeighedtAvg AS 
            (
				SELECT Rating
				, AVG(Critic_Score) AS 'Normal_Avg'
				, ( SUM( Critic_Score * Critic_Count) / ( SUM(Critic_Count) ) ) AS 'WeighedtAvg'
				FROM video_games
				WHERE Rating IS NOT NULL AND Critic_Score IS NOT NULL AND Critic_Count IS NOT NULL
				GROUP BY Rating 
			                    )
--QUERY
SELECT CA.Rating
, CA.Normal_Avg
, CA.WeighedtAvg
, CM.Critic_Score
FROM Cte_Mode CM INNER JOIN Cte_AVG_WeighedtAvg CA
ON CM.Rating = CA.Rating
WHERE CM.RnMode = 1





-- 4.Please provide the global sales by genre, Platform, and Year. Remember: Some of the combinations in between do not exist (such as for Platform '2600' for Action genre, the years 1984-1986 lack in the data 


--Cte
WITH Cte_Combinations AS (
    -- Generate all possible combinations of Genre, Platform, and Year_of_Release
    SELECT DISTINCT Genre, Platform, Year_of_Release
    FROM video_games
    WHERE Genre IS NOT NULL AND Platform IS NOT NULL AND Year_of_Release IS NOT NULL
)
--Query
SELECT C.Genre
    , C.Platform
    , C.Year_of_Release
    , COALESCE(SUM(v.Global_Sales), 0) AS Global_Sales
FROM  Cte_Combinations C
LEFT JOIN video_games v
    ON C.Genre = v.Genre
    AND C.Platform = v.Platform
    AND C.Year_of_Release = v.Year_of_Release
GROUP BY C.Genre, C.Platform, C.Year_of_Release
ORDER BY C.Genre, C.Platform, C.Year_of_Release;



--5 Year over Year analysis (aka: YoY) Analyze per platform the year with the highest YoY % (Year of Year relative growth
--equation > (a – b) / b), in terms of Global_Sales. Which of the following had recorded the most significant growth rate within the dataset, and in which year?


SELECT PLATFORM 
, Year_of_Release
, GlobalSales_PerYear
, ROUND( ( ( LEAD(GlobalSales_PerYear,1) OVER(ORDER BY Year_of_Release)  - GlobalSales_PerYear ) / GlobalSales_PerYear ) * 100,2) AS 'YOY'
FROM (SELECT PLATFORM 
	 , Year_of_Release
	 , SUM(Global_Sales) AS 'GlobalSales_PerYear'
	 , ROW_NUMBER () OVER (PARTITION BY PLATFORM ORDER BY Year_of_Release) AS RN 
	 FROM video_games
	 WHERE PLATFORM IS NOT NULL AND Global_Sales IS NOT NULL AND Year_of_Release IS NOT NULL
	 GROUP BY PLATFORM , Year_of_Release ) AS tbl