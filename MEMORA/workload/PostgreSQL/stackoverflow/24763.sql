
WITH UserAnalytics AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           COUNT(DISTINCT P.Id) AS PostCount,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
           SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
           AVG(U.Reputation) OVER (PARTITION BY CASE WHEN U.Reputation IS NULL OR U.Reputation = 0 THEN 'No Reputation' ELSE 'Has Reputation' END) AS AvgReputation,
           MAX(U.CreationDate) AS LastActive
    FROM Users AS U
    LEFT JOIN Posts AS P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes AS V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT PH.PostId,
           COUNT(*) AS EditCount,
           SUM(CASE WHEN PHT.Name LIKE 'Edit%' THEN 1 ELSE 0 END) AS EditsMade,
           SUM(CASE WHEN PHT.Name LIKE 'Rollback%' THEN 1 ELSE 0 END) AS Rollbacks,
           MAX(PH.CreationDate) AS LastEditDate
    FROM PostHistory AS PH
    JOIN PostHistoryTypes AS PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.PostId
)
SELECT UA.UserId,
       UA.DisplayName,
       UA.PostCount,
       UA.QuestionsAsked,
       UA.AnswersGiven,
       UA.TotalBounties,
       UA.AvgReputation,
       UA.LastActive,
       COALESCE(PHS.EditCount, 0) AS EditCount,
       COALESCE(PHS.EditsMade, 0) AS EditsMade,
       COALESCE(PHS.Rollbacks, 0) AS Rollbacks,
       COALESCE(B.Id, -1) AS BadgeId,
       COALESCE(B.Name, 'No Badge') AS BadgeName
FROM UserAnalytics AS UA
LEFT JOIN PostHistoryStats AS PHS ON PHS.PostId IN (
    SELECT Id FROM Posts WHERE OwnerUserId = UA.UserId
)
LEFT JOIN Badges AS B ON UA.UserId = B.UserId AND B.Class = 1 
WHERE UA.PostCount > 10
  AND UA.AvgReputation > 100
  AND (COALESCE(PHS.Rollbacks, 0) > 5 OR COALESCE(PHS.EditsMade, 0) > 10)
ORDER BY UA.LastActive DESC, UA.DisplayName ASC;
