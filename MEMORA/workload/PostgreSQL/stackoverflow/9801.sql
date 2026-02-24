
WITH UserActivity AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           COUNT(P.Id) AS TotalPosts, 
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
           AVG(COALESCE(P.Score, 0)) AS AverageScore,
           MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT UserId, 
           DisplayName, 
           TotalPosts, 
           TotalQuestions, 
           TotalAnswers, 
           TotalBounty, 
           AverageScore,
           LastPostDate,
           RANK() OVER (ORDER BY TotalPosts DESC, TotalBounty DESC) AS UserRank
    FROM UserActivity
),
RecentPosts AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.CreationDate,
           U.DisplayName AS AuthorName,
           P.Score,
           COUNT(C.Id) AS CommentCount
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, U.DisplayName, P.Score
)
SELECT T.DisplayName, 
       T.TotalPosts, 
       T.TotalQuestions, 
       T.TotalAnswers, 
       T.TotalBounty, 
       T.AverageScore,
       T.LastPostDate,
       R.PostId,
       R.Title AS RecentPostTitle,
       R.CreationDate AS RecentPostDate,
       R.Score AS RecentPostScore,
       R.CommentCount
FROM TopUsers T
LEFT JOIN RecentPosts R ON T.DisplayName = R.AuthorName
WHERE T.UserRank <= 10
ORDER BY T.UserRank, R.CreationDate DESC;
