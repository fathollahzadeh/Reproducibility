WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation IS NOT NULL
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
TopPosts AS (
    SELECT 
        P.Title,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC NULLS LAST) AS PostRank
    FROM Posts P 
    WHERE P.Score IS NOT NULL
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.ReputationRank,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.BadgeNames, 'None') AS BadgeNames,
    COALESCE(PS.PostCount, 0) AS PostCount,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    TP.Title AS TopPostTitle
FROM RankedUsers U
LEFT JOIN UserBadges UB ON U.UserId = UB.UserId
LEFT JOIN PostStats PS ON U.UserId = PS.OwnerUserId
LEFT JOIN TopPosts TP ON U.UserId = TP.OwnerUserId AND TP.PostRank = 1
WHERE U.ReputationRank <= 10
ORDER BY U.Reputation DESC,
         BadgeCount DESC,
         TotalViews DESC;