
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
PostRanked AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        UR.UserId,
        P.OwnerUserId,
        COUNT(P.PostId) AS PostCount,
        SUM(P.Score) AS TotalScore
    FROM UserReputation UR
    JOIN PostRanked P ON UR.UserId = P.OwnerUserId
    GROUP BY UR.UserId, P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName,
    UR.Reputation,
    COALESCE(PS.PostCount, 0) AS PostCount,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    COALESCE(CP.CloseCount, 0) AS ClosedPostCount,
    (CASE 
        WHEN UR.Reputation > 1000 THEN 'Expert'
        WHEN UR.Reputation BETWEEN 500 AND 1000 THEN 'Veteran'
        ELSE 'Novice'
    END) AS UserLevel
FROM Users U
JOIN UserReputation UR ON U.Id = UR.UserId
LEFT JOIN PostStats PS ON U.Id = PS.UserId
LEFT JOIN ClosedPosts CP ON U.Id = CP.PostId
WHERE UR.TotalBounty > 0 OR UR.BadgeCount > 0
ORDER BY UR.Reputation DESC, PS.PostCount DESC;
