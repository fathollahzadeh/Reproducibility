WITH RECURSIVE UserReputation AS (
    SELECT 
        Id, 
        Reputation, 
        CAST(CreationDate AS DATE) AS CreationDate,
        1 AS Level
    FROM Users
    WHERE Reputation > 1000

    UNION ALL

    SELECT 
        U.Id, 
        U.Reputation, 
        CAST(U.CreationDate AS DATE), 
        Level + 1
    FROM Users U
    INNER JOIN UserReputation UR ON U.Id = UR.Id
    WHERE UR.Reputation < U.Reputation
), 

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(NULLIF(P.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3) 
    WHERE P.CreationDate > '2020-01-01'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.AcceptedAnswerId
), 

TopUsers AS (
    SELECT 
        U.DisplayName,
        U.Id,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 1000
    GROUP BY U.DisplayName, U.Id
    HAVING COUNT(DISTINCT P.Id) > 10
    ORDER BY TotalScore DESC
    LIMIT 10
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.CommentCount,
    PS.TotalBounty,
    TU.DisplayName AS TopUser,
    UR.Reputation AS UserReputation
FROM PostStatistics PS
LEFT JOIN TopUsers TU ON PS.AcceptedAnswerId = TU.Id
LEFT JOIN UserReputation UR ON TU.Id = UR.Id
WHERE PS.Score > 10
ORDER BY PS.CommentCount DESC, PS.TotalBounty DESC;