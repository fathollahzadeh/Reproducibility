WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.BadgeCount,
        ps.PostCount,
        ps.TotalScore,
        ps.AverageViewCount
    FROM 
        UserReputation ur
    LEFT JOIN 
        PostStatistics ps ON ur.UserId = ps.OwnerUserId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.BadgeCount,
    COALESCE(up.PostCount, 0) AS PostCount,
    COALESCE(up.TotalScore, 0) AS TotalScore,
    COALESCE(up.AverageViewCount, 0) AS AverageViewCount,
    RANK() OVER (ORDER BY up.TotalScore DESC) AS PerformanceRank
FROM 
    UserPerformance up
WHERE 
    up.Reputation >= 100
ORDER BY 
    PerformanceRank
LIMIT 10;
