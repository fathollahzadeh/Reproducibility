
WITH UserReputation AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostSummary AS (
    SELECT P.OwnerUserId,
           COUNT(P.Id) AS PostCount,
           SUM(V.BountyAmount) AS TotalBounty,
           AVG(CASE WHEN P.ViewCount > 0 THEN P.Score / NULLIF(P.ViewCount, 0) ELSE 0 END) AS AverageScorePerView
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY P.OwnerUserId
),
ClosedQuestions AS (
    SELECT PH.UserId,
           COUNT(PH.Id) AS ClosedCount
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId = 10 
    GROUP BY PH.UserId
)
SELECT U.UserId, 
       U.DisplayName,
       COALESCE(P.PostCount, 0) AS NumberOfPosts,
       COALESCE(P.TotalBounty, 0) AS TotalBountyEarned,
       COALESCE(P.AverageScorePerView, 0) AS AverageScorePerView,
       COALESCE(C.ClosedCount, 0) AS NumberOfClosedQuestions,
       U.Reputation AS UserReputation,
       U.ReputationRank
FROM UserReputation U
LEFT JOIN PostSummary P ON U.UserId = P.OwnerUserId
LEFT JOIN ClosedQuestions C ON U.UserId = C.UserId
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, C.ClosedCount DESC
LIMIT 10;
