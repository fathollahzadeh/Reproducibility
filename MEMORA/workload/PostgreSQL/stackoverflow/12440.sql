WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS PostCount, 
        SUM(p.Score) AS TotalScore, 
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        ur.UserId, 
        ur.Reputation, 
        ur.BadgeCount, 
        ps.PostCount, 
        ps.TotalScore, 
        ps.TotalViews
    FROM 
        UserReputation ur
    LEFT JOIN 
        PostStats ps ON ur.UserId = ps.OwnerUserId
)
SELECT 
    ups.UserId,
    ups.Reputation,
    ups.BadgeCount,
    COALESCE(ups.PostCount, 0) AS PostCount,
    COALESCE(ups.TotalScore, 0) AS TotalScore,
    COALESCE(ups.TotalViews, 0) AS TotalViews
FROM 
    UserPostStats ups
ORDER BY 
    ups.Reputation DESC, 
    ups.TotalScore DESC;