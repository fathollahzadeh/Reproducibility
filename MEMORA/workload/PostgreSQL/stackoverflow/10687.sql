
WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, DisplayName, LastAccessDate, Views
    FROM Users
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS TotalAnswers,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId
),
TopActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties
    FROM Users U
    JOIN Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName, U.Reputation
    ORDER BY TotalPosts DESC
    LIMIT 10
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    PS.PostId,
    PS.Title,
    PS.PostCreationDate,
    PS.Score,
    PS.ViewCount,
    PS.TotalComments,
    PS.TotalAnswers,
    COALESCE(TBA.TotalBounties, 0) AS TotalBounties
FROM TopActiveUsers UA
JOIN PostStatistics PS ON UA.UserId = PS.OwnerUserId
LEFT JOIN (
    SELECT 
        UserId,
        SUM(BountyAmount) AS TotalBounties
    FROM Votes
    GROUP BY UserId
) TBA ON TBA.UserId = UA.UserId
ORDER BY UA.Reputation DESC;
