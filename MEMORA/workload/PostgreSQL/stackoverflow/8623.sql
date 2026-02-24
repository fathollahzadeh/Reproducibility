WITH UserReputations AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostEngagements AS (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate > '2020-01-01'
    GROUP BY P.OwnerUserId
),
CombinedData AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.PostCount,
        UR.TotalBounty,
        PE.CommentCount,
        PE.TotalViews,
        PE.AverageScore
    FROM UserReputations UR
    LEFT JOIN PostEngagements PE ON UR.UserId = PE.OwnerUserId
)
SELECT 
    CD.DisplayName,
    CD.Reputation,
    CD.PostCount,
    CD.TotalBounty,
    COALESCE(CD.CommentCount, 0) AS CommentCount,
    COALESCE(CD.TotalViews, 0) AS TotalViews,
    COALESCE(CD.AverageScore, 0) AS AverageScore
FROM CombinedData CD
ORDER BY CD.Reputation DESC, CD.TotalViews DESC
LIMIT 50;
