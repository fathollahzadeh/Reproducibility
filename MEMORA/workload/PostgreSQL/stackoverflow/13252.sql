WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS AverageViews,
        AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
)

SELECT 
    p.PostTypeId,
    ps.TotalPosts,
    ps.TotalViews,
    ps.TotalScore,
    ps.AverageViews,
    ps.AverageScore,
    COUNT(DISTINCT us.UserId) AS TotalUsers,
    SUM(us.Reputation) AS TotalReputation,
    SUM(us.TotalBadges) AS TotalBadges,
    SUM(us.TotalBounty) AS TotalBounty
FROM 
    PostStats ps
JOIN 
    Posts p ON p.PostTypeId = ps.PostTypeId
JOIN 
    UserStats us ON p.OwnerUserId = us.UserId
GROUP BY 
    p.PostTypeId, ps.TotalPosts, ps.TotalViews, ps.TotalScore, ps.AverageViews, ps.AverageScore
ORDER BY 
    p.PostTypeId;