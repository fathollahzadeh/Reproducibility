WITH UserPostCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
BadgeCount AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
FinalUserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(upc.PostCount, 0) AS PostCount,
        COALESCE(upc.TotalScore, 0) AS TotalScore,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        UserPostCount upc ON u.Id = upc.UserId
    LEFT JOIN 
        BadgeCount bc ON u.Id = bc.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    BadgeCount,
    Reputation,
    (PostCount + TotalScore + BadgeCount) AS PerformanceMetric
FROM 
    FinalUserMetrics
ORDER BY 
    PerformanceMetric DESC
LIMIT 10;