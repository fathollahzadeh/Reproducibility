
WITH PostCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT v.UserId) AS TotalVotes,
        COUNT(DISTINCT u.Id) AS TotalUsers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    TotalPosts,
    TotalVotes,
    TotalUsers,
    TotalVotes * 1.0 / NULLIF(TotalPosts, 0) AS VotesPerPost,
    TotalUsers * 1.0 / NULLIF(TotalPosts, 0) AS UsersPerPost
FROM 
    PostCounts
ORDER BY 
    TotalPosts DESC;
