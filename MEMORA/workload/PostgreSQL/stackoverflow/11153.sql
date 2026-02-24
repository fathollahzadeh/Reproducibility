WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.AnswerCount) AS AvgAnswers
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.Id,
    u.DisplayName,
    us.Reputation,
    us.BadgeCount,
    us.TotalBounty,
    ps.PostCount,
    ps.TotalScore,
    ps.TotalViews,
    ps.AvgAnswers
FROM 
    Users u
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
ORDER BY 
    us.Reputation DESC, 
    ps.TotalScore DESC
LIMIT 100;