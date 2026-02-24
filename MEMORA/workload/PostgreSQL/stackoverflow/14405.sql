WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        AVG(COALESCE(c.CommentCount, 0)) AS AverageCommentCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    GROUP BY 
        p.PostTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    pst.PostTypeId,
    pst.TotalPosts,
    pst.PositiveScorePosts,
    pst.HighViewCountPosts,
    pst.AverageScore,
    pst.AverageCommentCount,
    AVG(ur.Reputation) AS AverageUserReputation,
    SUM(ur.TotalBadges) AS TotalBadgesEarned
FROM 
    PostStats pst
JOIN 
    UserReputation ur ON ur.UserId IN (SELECT OwnerUserId FROM Posts WHERE PostTypeId = pst.PostTypeId)
GROUP BY 
    pst.PostTypeId, pst.TotalPosts, pst.PositiveScorePosts, pst.HighViewCountPosts, pst.AverageScore, pst.AverageCommentCount
ORDER BY 
    pst.PostTypeId;