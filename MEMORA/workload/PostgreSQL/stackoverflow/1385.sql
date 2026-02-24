WITH UserReputation AS (
    SELECT Id, Reputation, 
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostSummary AS (
    SELECT P.OwnerUserId,
           COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
           COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
           COUNT(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 END) AS TagWikis,
           SUM(V.BountyAmount) AS TotalBounty
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.OwnerUserId
),
ClosedPosts AS (
    SELECT Ph.UserId, 
           COUNT(*) AS ClosedPostCount
    FROM PostHistory Ph
    WHERE Ph.PostHistoryTypeId = 10
    GROUP BY Ph.UserId
)

SELECT U.DisplayName,
       COALESCE(UR.Reputation, 0) AS Reputation,
       COALESCE(PS.Questions, 0) AS TotalQuestions,
       COALESCE(PS.Answers, 0) AS TotalAnswers,
       COALESCE(PS.TagWikis, 0) AS TotalTagWikis,
       COALESCE(CL.ClosedPostCount, 0) AS TotalClosedPosts,
       CASE 
           WHEN COALESCE(PS.TotalBounty, 0) > 0 THEN 'Has Bounty'
           ELSE 'No Bounty'
       END AS BountyStatus,
       CASE 
           WHEN COALESCE(UR.Reputation, 0) >= 1000 THEN 'Expert'
           WHEN COALESCE(UR.Reputation, 0) >= 500 THEN 'Intermediate'
           ELSE 'Novice'
       END AS UserLevel
FROM Users U
LEFT JOIN UserReputation UR ON U.Id = UR.Id
LEFT JOIN PostSummary PS ON U.Id = PS.OwnerUserId
LEFT JOIN ClosedPosts CL ON U.Id = CL.UserId
WHERE U.Location IS NOT NULL
ORDER BY Reputation DESC, TotalQuestions DESC
LIMIT 100;
