
WITH RecentUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyEarned,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        RANK() OVER (ORDER BY COALESCE(SUM(V.BountyAmount), 0) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON V.UserId = U.Id
    WHERE U.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY U.Id, U.DisplayName
),

TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalBountyEarned, 
        UserRank
    FROM RecentUserActivity
    WHERE UserRank <= 10
),

PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        AVG(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpvotes,
        MAX(P.Score) AS MaxScore,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '3 months'
    GROUP BY P.Id, P.Title
)

SELECT 
    U.DisplayName,
    U.TotalBountyEarned,
    P.Title,
    P.CommentCount,
    P.VoteCount,
    P.AvgUpvotes,
    P.MaxScore,
    CASE 
        WHEN P.CommentCount > 10 THEN 'Very Active'
        WHEN P.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityStatus
FROM TopUsers U
JOIN PostStats P ON U.UserId = P.OwnerUserId
WHERE (P.MaxScore IS NOT NULL OR P.CommentCount > 0)
  AND P.VoteCount > (SELECT AVG(VoteCount) 
                     FROM PostStats)
ORDER BY U.TotalBountyEarned DESC, P.MaxScore DESC;
