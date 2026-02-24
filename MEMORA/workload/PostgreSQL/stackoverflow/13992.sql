WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes,
        MAX(p.LastActivityDate) AS LastActivityDate
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
    TotalComments,
    TotalVotes,
    LastActivityDate
FROM 
    PostStats
ORDER BY 
    TotalPosts DESC;