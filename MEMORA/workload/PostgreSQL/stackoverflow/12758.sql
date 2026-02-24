WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.Score > 0 THEN 1 END) AS PositiveScorePosts,
        AVG(p.ViewCount) AS AverageViews,
        AVG(p.AnswerCount) AS AverageAnswers,
        AVG(p.CommentCount) AS AverageComments
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(b.Class) AS TotalBadgeClass,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
CommentStats AS (
    SELECT 
        COUNT(c.Id) AS TotalComments,
        AVG(c.Score) AS AverageCommentScore
    FROM 
        Comments c
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.PositiveScorePosts,
    ps.AverageViews,
    ps.AverageAnswers,
    ps.AverageComments,
    us.UserId,
    us.DisplayName,
    us.TotalBadges,
    us.TotalBadgeClass,
    us.TotalBounty,
    cs.TotalComments,
    cs.AverageCommentScore
FROM 
    PostStats ps
CROSS JOIN 
    UserStats us
CROSS JOIN 
    CommentStats cs
ORDER BY 
    ps.TotalPosts DESC, us.TotalBadges DESC;