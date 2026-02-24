WITH PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01' AND p.CreationDate < '2023-12-31'
    GROUP BY 
        p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ps.PostCount,
        ps.AverageScore
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    us.UserId,
    us.Reputation,
    COALESCE(us.PostCount, 0) AS TotalPosts,
    COALESCE(us.AverageScore, 0) AS AvgPostScore
FROM 
    UserStats us
ORDER BY 
    us.Reputation DESC;