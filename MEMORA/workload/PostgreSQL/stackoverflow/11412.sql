WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(AVG(p.Score), 0) AS AveragePostScore,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)

SELECT 
    ups.UserId,
    ups.TotalPosts,
    ups.AveragePostScore,
    ups.TotalVotes
FROM 
    UserPostStats ups
ORDER BY 
    ups.TotalPosts DESC;