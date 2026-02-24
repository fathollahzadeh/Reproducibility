WITH UserReputation AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation, 
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostStats AS (
    SELECT 
        RP.OwnerUserId,
        COUNT(RP.PostId) AS PostCount,
        SUM(RP.Score) AS TotalScore,
        AVG(RP.Score) AS AverageScore,
        STRING_AGG(DISTINCT RP.Title, ', ') AS PostTitles
    FROM RecentPosts RP
    GROUP BY RP.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.Id AS UserId,
        UR.DisplayName,
        UR.Reputation,
        PS.PostCount,
        PS.TotalScore
    FROM UserReputation UR
    LEFT JOIN PostStats PS ON UR.Id = PS.OwnerUserId
    WHERE UR.Reputation > 1000
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    COALESCE(TU.PostCount, 0) AS PostCount,
    COALESCE(TU.TotalScore, 0) AS TotalScore,
    CASE 
        WHEN TU.PostCount > 5 THEN 'Active Contributor'
        WHEN TU.PostCount BETWEEN 1 AND 5 THEN 'New Contributor'
        ELSE 'No Contributions'
    END AS ContributionLevel
FROM TopUsers TU
LEFT JOIN Badges B ON TU.UserId = B.UserId AND B.Class = 1 
WHERE B.Id IS NULL
ORDER BY TU.Reputation DESC, TU.TotalScore DESC;