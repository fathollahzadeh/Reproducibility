WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    up.TotalPosts,
    uv.TotalVotes
FROM 
    Users u
LEFT JOIN 
    UserPosts up ON u.Id = up.UserId
LEFT JOIN 
    UserVotes uv ON u.Id = uv.UserId
ORDER BY 
    u.Reputation DESC;