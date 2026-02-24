WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(PC.PostCount, 0) AS PostCount,
        COALESCE(BC.BadgeCount, 0) AS BadgeCount,
        PC.TotalScore,
        PC.TotalViewCount
    FROM 
        Users U
    LEFT JOIN 
        UserPostCounts PC ON U.Id = PC.UserId
    LEFT JOIN 
        BadgeCounts BC ON U.Id = BC.UserId
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    BadgeCount,
    TotalScore,
    TotalViewCount
FROM 
    UserMetrics
ORDER BY 
    Reputation DESC, PostCount DESC;