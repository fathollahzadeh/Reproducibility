
WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        AVG(p.CommentCount) AS AvgComments,
        AVG(p.FavoriteCount) AS AvgFavorites,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgTimeToActivitySeconds
    FROM 
        Posts p 
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    TotalPosts,
    AvgScore,
    TotalViews,
    TotalAnswers,
    AvgComments,
    AvgFavorites,
    AvgTimeToActivitySeconds
FROM 
    PostMetrics
ORDER BY 
    TotalPosts DESC;
