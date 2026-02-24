
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(v.BountyAmount) AS AverageBountyAmount,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostTypeId,
    ps.TotalPosts,
    ps.PositiveScorePosts,
    ps.AverageBountyAmount,
    ps.TotalComments,
    COUNT(DISTINCT us.UserId) AS ActiveUsers,
    AVG(us.AverageReputation) AS AverageUserReputation
FROM 
    PostStats ps
LEFT JOIN 
    UserStats us ON ps.TotalPosts > 0
GROUP BY 
    ps.PostTypeId, ps.TotalPosts, ps.PositiveScorePosts, ps.AverageBountyAmount, ps.TotalComments
ORDER BY 
    ps.PostTypeId;
