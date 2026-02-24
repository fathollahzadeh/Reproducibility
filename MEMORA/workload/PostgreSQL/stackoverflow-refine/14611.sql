WITH PostCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostTypeStats AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        pc.TotalPosts,
        pc.AvgScore,
        pc.TotalViews,
        us.UserId,
        us.Reputation,
        us.BadgeCount,
        us.TotalBounties
    FROM 
        PostTypes pt
    LEFT JOIN 
        PostCounts pc ON pt.Id = pc.PostTypeId
    LEFT JOIN 
        UserStats us ON us.UserId IS NOT NULL
)
SELECT 
    p.PostTypeId,
    p.PostTypeName,
    p.TotalPosts,
    p.AvgScore,
    p.TotalViews,
    COALESCE(SUM(p.Reputation), 0) AS TotalUserReputation,
    COALESCE(SUM(p.BadgeCount), 0) AS TotalBadges,
    COALESCE(SUM(p.TotalBounties), 0) AS TotalBounties
FROM 
    PostTypeStats p
GROUP BY 
    p.PostTypeId, p.PostTypeName, p.TotalPosts, p.AvgScore, p.TotalViews
ORDER BY 
    p.TotalPosts DESC;