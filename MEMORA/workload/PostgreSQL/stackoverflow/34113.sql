WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        0 AS Level
    FROM Users U
    WHERE U.Reputation IS NOT NULL
    UNION ALL
    SELECT 
        U.Id,
        U.Reputation,
        UR.Level + 1
    FROM Users U
    JOIN UserReputation UR ON U.Id = UR.UserId
    WHERE U.Reputation > (SELECT AVG(Reputation) FROM Users) 
)
, UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS TotalBadges,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
)
, PostScores AS (
    SELECT 
        P.OwnerUserId,
        SUM(P.Score) AS TotalScore,
        COUNT(P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY P.OwnerUserId
)
, RecentUserPosts AS (
    SELECT 
        P.OwnerUserId,
        P.Title,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month' 
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(UB.TotalBadges, 0) AS TotalBadges,
    COALESCE(UB.BadgeNames, 'None') AS BadgeNames,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    STRING_AGG(RUP.Title, '; ') AS RecentPosts
FROM Users U
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
LEFT JOIN PostScores PS ON U.Id = PS.OwnerUserId
LEFT JOIN RecentUserPosts RUP ON U.Id = RUP.OwnerUserId AND RUP.PostRank <= 5
WHERE U.Reputation > (SELECT AVG(Reputation) FROM Users) 
GROUP BY U.Id, U.DisplayName, U.Reputation, UB.TotalBadges, UB.BadgeNames, PS.TotalScore, PS.TotalPosts, PS.TotalViews
ORDER BY U.Reputation DESC;