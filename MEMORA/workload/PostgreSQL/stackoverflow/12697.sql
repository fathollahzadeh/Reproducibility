WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.ViewCount > 0 THEN 1 ELSE 0 END) AS ViewedPosts,
        AVG(p.ViewCount) AS AvgViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPostsByUser,
        SUM(p.Score) AS TotalScoreByUser,
        COUNT(b.Id) AS TotalBadgesByUser
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
VoteStats AS (
    SELECT 
        v.VoteTypeId,
        COUNT(*) AS TotalVotes,
        COUNT(DISTINCT v.PostId) AS UniquePostsVoted
    FROM 
        Votes v
    GROUP BY 
        v.VoteTypeId
)
SELECT 
    pts.PostTypeId,
    pts.TotalPosts,
    pts.PositiveScorePosts,
    pts.ViewedPosts,
    pts.AvgViews,
    pts.AvgScore,
    us.TotalPostsByUser,
    us.TotalScoreByUser,
    us.TotalBadgesByUser,
    vs.VoteTypeId,
    vs.TotalVotes,
    vs.UniquePostsVoted
FROM 
    PostStats pts
JOIN 
    UserStats us ON us.TotalPostsByUser = (SELECT MAX(TotalPostsByUser) FROM UserStats)
JOIN 
    VoteStats vs ON vs.TotalVotes = (SELECT MAX(TotalVotes) FROM VoteStats)
ORDER BY 
    pts.PostTypeId;