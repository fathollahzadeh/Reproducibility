WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        SUM(CASE WHEN p.CommentCount > 0 THEN 1 ELSE 0 END) AS PostsWithComments,
        AVG(p.ViewCount) AS AverageViewCount
    FROM Posts p
    GROUP BY p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        AVG(u.Reputation) AS AverageReputation,
        SUM(u.Views) AS TotalViews
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    p.PostTypeId,
    p.TotalPosts,
    p.PositiveScoreCount,
    p.PostsWithComments,
    p.AverageViewCount,
    u.TotalBadges,
    u.AverageReputation,
    u.TotalViews
FROM PostStats p
JOIN UserStats u ON u.UserId IN (SELECT OwnerUserId FROM Posts WHERE PostTypeId = p.PostTypeId)
ORDER BY p.PostTypeId;