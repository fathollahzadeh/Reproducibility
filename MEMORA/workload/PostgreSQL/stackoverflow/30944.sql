WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, CreationDate, LastAccessDate, WebsiteUrl,
           Location, UpVotes, DownVotes, 1 AS Level
    FROM Users
    WHERE Reputation > 1000 

    UNION ALL

    SELECT U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate, U.WebsiteUrl,
           U.Location, U.UpVotes, U.DownVotes, UH.Level + 1
    FROM Users U
    JOIN UserHierarchy UH ON U.Reputation < UH.Reputation 
)
SELECT U.DisplayName, U.Reputation, U.Location, 
       COUNT(DISTINCT PH.PostId) AS PostCount,
       SUM(COALESCE(P.Score, 0)) AS TotalScore,
       AVG(PH.CommentEvaluation) AS AvgCommentEval
FROM Users U 
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN (
    SELECT PH.UserId, PH.PostId,
           CASE 
               WHEN PH.PostHistoryTypeId = 10 THEN COUNT(*) 
               ELSE 0
           END AS CommentEvaluation
    FROM PostHistory PH
    GROUP BY PH.UserId, PH.PostId, PH.PostHistoryTypeId
) AS PH ON P.Id = PH.PostId
WHERE U.Reputation > 500 
GROUP BY U.DisplayName, U.Reputation, U.Location
HAVING COUNT(DISTINCT P.Id) > 5 
ORDER BY TotalScore DESC, U.Reputation ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;