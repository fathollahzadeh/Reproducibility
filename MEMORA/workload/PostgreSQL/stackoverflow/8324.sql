WITH UserBadgeCounts AS (
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
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    PostCount,
    TotalScore,
    TotalViews,
    CASE 
        WHEN BadgeCount > 5 THEN 'Expert' 
        WHEN BadgeCount BETWEEN 3 AND 5 THEN 'Proficient' 
        ELSE 'Novice' 
    END AS UserLevel
FROM 
    UserEngagement
WHERE 
    Reputation > 1000
ORDER BY 
    TotalScore DESC, PostCount DESC;