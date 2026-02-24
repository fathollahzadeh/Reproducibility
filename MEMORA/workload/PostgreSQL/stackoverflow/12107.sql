WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalUserPosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore,
        AVG(p.AnswerCount) AS AvgAnswerCount,
        AVG(p.CommentCount) AS AvgCommentCount,
        AVG(p.FavoriteCount) AS AvgFavoriteCount,
        AVG(p.CreationDate::timestamp - p.LastActivityDate::timestamp) AS AvgPostAge 
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
)

SELECT 
    pt.Name AS PostType,
    ps.TotalPosts,
    ps.TotalUserPosts,
    ps.TotalViews,
    ps.AvgScore,
    ps.AvgAnswerCount,
    ps.AvgCommentCount,
    ps.AvgFavoriteCount,
    ps.AvgPostAge
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
ORDER BY 
    ps.TotalPosts DESC;