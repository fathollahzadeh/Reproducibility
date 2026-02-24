WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.Score <= 0 THEN 1 ELSE 0 END) AS NegativeScorePosts,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.AnswerCount) AS AvgAnswerCount,
        AVG(p.CommentCount) AS AvgCommentCount
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
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.PositiveScorePosts,
    ps.NegativeScorePosts,
    ps.AvgViewCount,
    ps.AvgAnswerCount,
    ps.AvgCommentCount,
    us.DisplayName AS TopUser,
    us.TotalPosts AS UserPostCount,
    us.TotalBadges,
    us.AvgReputation
FROM 
    PostStats ps
LEFT JOIN 
    UserStats us ON us.TotalPosts = (SELECT MAX(TotalPosts) FROM UserStats)
ORDER BY 
    ps.TotalPosts DESC;