WITH UserReputation AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           U.Reputation, 
           COUNT(DISTINCT P.Id) AS PostCount,
           SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT UserId, 
           DisplayName, 
           Reputation, 
           PostCount, 
           TotalScore,
           RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserReputation
),
PostDetails AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.CreationDate,
           COALESCE(COUNT(C.Id), 0) AS CommentCount,
           COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
           P.ViewCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount
),
RecentEdits AS (
    SELECT P.Title, 
           PH.CreationDate AS EditDate, 
           PH.UserDisplayName 
    FROM PostHistory PH
    INNER JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId IN (4, 5) 
      AND PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT TU.DisplayName, 
       TU.Reputation,
       TU.PostCount,
       PD.PostId,
       PD.Title,
       PD.CreationDate,
       PD.CommentCount,
       PD.TotalBounty,
       PD.ViewCount,
       RE.EditDate,
       RE.UserDisplayName AS EditorName
FROM TopUsers TU
JOIN PostDetails PD ON PD.CommentCount > 5   
LEFT JOIN RecentEdits RE ON PD.Title = RE.Title
WHERE TU.ScoreRank <= 10                      
ORDER BY TU.Reputation DESC, PD.TotalBounty DESC
LIMIT 50;