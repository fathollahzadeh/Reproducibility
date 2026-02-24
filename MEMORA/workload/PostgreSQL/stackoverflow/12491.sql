WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.AcceptedAnswerId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.BadgeCount,
    u.TotalBounties,
    u.TotalViews,
    p.PostId,
    p.PostTypeId,
    p.AcceptedAnswerId,
    p.CommentCount,
    p.VoteCount
FROM 
    UserStats u
JOIN 
    PostStats p ON u.UserId = p.AcceptedAnswerId
ORDER BY 
    u.Reputation DESC, u.PostCount DESC;