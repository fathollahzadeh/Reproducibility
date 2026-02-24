WITH UserPostActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        MAX(COALESCE(p.LastActivityDate, p.CreationDate)) AS LastActivity
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
RecentPostActivity AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        TotalScore,
        LastActivity,
        ROW_NUMBER() OVER (PARTITION BY UserId ORDER BY LastActivity DESC) AS rn
    FROM 
        UserPostActivity
)

SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    up.TotalPosts,
    up.TotalScore,
    up.LastActivity
FROM 
    Users u
JOIN 
    RecentPostActivity up ON u.Id = up.UserId
WHERE 
    up.rn = 1  
ORDER BY 
    up.TotalScore DESC,  
    u.Reputation DESC;