
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
OverallStats AS (
    SELECT 
        SUM(PostCount) AS OverallPostCount,
        SUM(TotalViews) AS OverallViews,
        AVG(AverageScore) AS OverallAverageScore
    FROM 
        PostStats
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalReputation,
    u.TotalPosts,
    u.TotalBadges,
    ps.PostType,
    ps.PostCount,
    ps.TotalViews,
    ps.AverageScore,
    os.OverallPostCount,
    os.OverallViews,
    os.OverallAverageScore
FROM 
    UserReputation u
CROSS JOIN 
    OverallStats os
JOIN 
    PostStats ps ON ps.PostCount > 0
ORDER BY 
    u.TotalReputation DESC, 
    ps.PostCount DESC;
