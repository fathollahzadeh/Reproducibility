WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        u.DisplayName AS UserName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalUpvotedPosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        SUM(p.CommentCount) AS TotalComments
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        pt.Name, u.DisplayName
)

SELECT 
    PostType,
    UserName,
    TotalPosts,
    TotalUpvotedPosts,
    TotalViews,
    AverageScore,
    TotalComments
FROM 
    PostStats
ORDER BY 
    TotalPosts DESC, AverageScore DESC;