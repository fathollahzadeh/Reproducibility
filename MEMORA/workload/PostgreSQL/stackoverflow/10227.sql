WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(AVG(v.VoteCount), 0) AS AvgVotes,
        COALESCE(AVG(p.ViewCount), 0) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS VoteCount
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.AvgVotes,
    ups.AvgViewCount,
    u.Reputation
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
ORDER BY 
    u.Reputation DESC
LIMIT 10;