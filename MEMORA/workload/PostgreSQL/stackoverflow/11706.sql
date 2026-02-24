WITH PostCounts AS (
    SELECT 
        pt.Name AS PostType, 
        COUNT(p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN 1 ELSE 0 END) AS TotalViews, 
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        pt.Name
)

SELECT 
    PostType, 
    TotalPosts, 
    TotalViews, 
    TotalComments, 
    TotalVotes
FROM 
    PostCounts
ORDER BY 
    TotalPosts DESC;