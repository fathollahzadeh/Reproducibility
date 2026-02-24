WITH UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS PostCount,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        UB.BadgeCount,
        PS.PostCount,
        PS.TotalScore,
        PS.TotalViews,
        PS.LastPostDate
    FROM 
        Users U
    JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    DisplayName, 
    Reputation, 
    BadgeCount, 
    PostCount, 
    TotalScore, 
    TotalViews, 
    LastPostDate
FROM 
    CombinedStats
WHERE 
    Reputation > 1000 
    AND BadgeCount > 0
ORDER BY 
    TotalScore DESC, 
    PostCount DESC
LIMIT 10;
