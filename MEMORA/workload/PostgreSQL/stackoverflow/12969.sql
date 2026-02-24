WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
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
    CASE 
        WHEN Reputation >= 10000 THEN 'Top Users'
        WHEN Reputation >= 1000 THEN 'Active Users'
        WHEN Reputation >= 100 THEN 'New Users'
        ELSE 'Inactive Users'
    END AS UserLevel,
    COUNT(UserId) AS UserCount,
    SUM(PostCount) AS TotalPosts,
    AVG(AverageScore) AS AvgPostScore,
    SUM(CommentCount) AS TotalComments,
    SUM(VoteCount) AS TotalVotes
FROM 
    UserStats
GROUP BY 
    UserLevel
ORDER BY 
    UserLevel DESC;