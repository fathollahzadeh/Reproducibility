WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
)

SELECT 
    UserId, 
    Reputation, 
    TotalPosts, 
    TotalComments, 
    TotalVotes
FROM 
    UserStatistics
ORDER BY 
    TotalPosts DESC, 
    TotalComments DESC, 
    TotalVotes DESC
LIMIT 100;