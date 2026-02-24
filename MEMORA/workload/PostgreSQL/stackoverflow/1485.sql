WITH UserReputation AS (
    SELECT Id, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank,
           CASE 
               WHEN Reputation >= 5000 THEN 'High Reputation'
               WHEN Reputation BETWEEN 1000 AND 4999 THEN 'Medium Reputation'
               ELSE 'Low Reputation'
           END AS ReputationCategory
    FROM Users
),
PostStats AS (
    SELECT Posts.OwnerUserId, 
           COUNT(Posts.Id) AS TotalPosts, 
           SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           AVG(Posts.Score) AS AverageScore
    FROM Posts
    GROUP BY Posts.OwnerUserId
),
PostHistoryAnalysis AS (
    SELECT PH.PostId, 
           P.Title, 
           P.Body, 
           COUNT(PH.Id) AS EditCount,
           STRING_AGG(PH.Comment, '; ') AS EditComments
    FROM PostHistory PH
    JOIN Posts P ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId IN (4, 5, 24)  
    GROUP BY PH.PostId, P.Title, P.Body
)
SELECT U.DisplayName, 
       UReputation.Reputation, 
       UReputation.ReputationCategory,
       PS.TotalPosts, 
       PS.TotalQuestions, 
       PS.TotalAnswers, 
       PS.AverageScore,
       PHA.EditCount, 
       PHA.EditComments
FROM Users U
LEFT JOIN UserReputation UReputation ON U.Id = UReputation.Id
LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN PostHistoryAnalysis PHA ON U.Id = PHA.PostId
WHERE PS.TotalPosts > 5 OR (UReputation.ReputationCategory = 'High Reputation' AND PHA.EditCount > 0)
ORDER BY UReputation.Reputation DESC, PS.TotalPosts DESC;