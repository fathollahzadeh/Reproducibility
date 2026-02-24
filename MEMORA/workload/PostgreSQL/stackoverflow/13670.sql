WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore,
        AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - p.CreationDate)) / 3600) AS AvgAgeHours
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(b.Class) AS BadgeScore,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.TotalViews,
    ps.AvgScore,
    ps.AvgAgeHours,
    us.DisplayName,
    us.TotalBadges,
    us.BadgeScore,
    us.AvgReputation
FROM 
    PostStats ps
JOIN 
    UserStats us ON us.AvgReputation > 1000 
ORDER BY 
    ps.TotalPosts DESC, us.AvgReputation DESC;