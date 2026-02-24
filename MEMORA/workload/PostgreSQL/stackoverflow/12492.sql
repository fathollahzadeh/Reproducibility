WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id,
        u.DisplayName,
        u.Reputation
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.PostCount,
    ups.TotalScore
FROM 
    UserPostStats ups
ORDER BY 
    ups.Reputation DESC
LIMIT 10;