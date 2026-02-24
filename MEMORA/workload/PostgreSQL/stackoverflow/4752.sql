
WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        PS.PostCount,
        PS.TotalViews,
        PS.AverageScore,
        RANK() OVER (ORDER BY UR.Reputation DESC) AS UserRank
    FROM UserReputation UR
    JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(COUNT(C.Id), 0) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    RANK() OVER (ORDER BY TU.Reputation DESC) AS GlobalRank,
    RP.Title,
    RP.CreationDate,
    RP.CommentCount,
    CASE 
        WHEN TU.Reputation > 1000 THEN 'Expert'
        WHEN TU.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM TopUsers TU
JOIN RecentPosts RP ON TU.UserId = RP.OwnerUserId
WHERE TU.UserRank <= 10
ORDER BY TU.Reputation DESC, RP.CreationDate DESC
LIMIT 5;
