WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        AVG(p.Score) AS AvgScore,
        COUNT(pc.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments pc ON p.Id = pc.PostId
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Reputation,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN p.Id IS NOT NULL THEN 1 ELSE 0 END) AS PostsCount,
        SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS VotesCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Reputation
)
SELECT 
    pts.PostTypeId,
    pts.TotalPosts,
    pts.TotalViews,
    pts.TotalScore,
    pts.AvgScore,
    pts.TotalComments,
    us.Reputation,
    us.TotalBadges,
    us.PostsCount,
    us.VotesCount
FROM 
    PostStats pts
CROSS JOIN 
    UserStats us
ORDER BY 
    pts.TotalPosts DESC;