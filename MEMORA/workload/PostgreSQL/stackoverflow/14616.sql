WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        MAX(p.Score) AS MaxPostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.AnswerCount,
    us.BadgeCount,
    us.MaxPostScore,
    p.Title AS TopPostTitle
FROM 
    UserStats us
LEFT JOIN 
    Posts p ON us.UserId = p.OwnerUserId AND p.Score = us.MaxPostScore
ORDER BY 
    us.Reputation DESC, us.MaxPostScore DESC;