WITH UserBadges AS (
    SELECT U.Id AS UserId, COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        UB.BadgeCount,
        PS.PostCount,
        PS.TotalScore,
        PS.AvgViewCount,
        PS.LastPostDate
    FROM Users U
    JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    WHERE U.Reputation > 100
)
SELECT 
    A.Id AS UserId,
    A.DisplayName,
    A.BadgeCount,
    COALESCE(A.PostCount, 0) AS PostCount,
    COALESCE(A.TotalScore, 0) AS TotalScore,
    COALESCE(A.AvgViewCount, 0) AS AvgViewCount,
    A.LastPostDate
FROM ActiveUsers A
ORDER BY A.BadgeCount DESC, A.TotalScore DESC
LIMIT 20;