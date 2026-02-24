
WITH PostStats AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        COUNT(DISTINCT c.Id) AS CommentCount, 
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ps.PostId, 
    ps.Title, 
    ps.CreationDate, 
    ps.ViewCount, 
    ps.CommentCount, 
    ps.VoteCount, 
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.TotalBountyAmount
FROM 
    PostStats ps
JOIN 
    Users u ON ps.PostId = u.Id 
JOIN 
    UserStats us ON us.UserId = u.Id
ORDER BY 
    ps.ViewCount DESC, ps.VoteCount DESC;
