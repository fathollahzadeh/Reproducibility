WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    ps.PostType,
    ps.PostCount,
    ps.TotalScore,
    ps.TotalViews,
    us.DisplayName AS User,
    us.Reputation,
    us.BadgeCount
FROM 
    PostStats ps
JOIN 
    UserStats us ON us.Reputation > 0 
ORDER BY 
    ps.PostCount DESC, us.Reputation DESC;