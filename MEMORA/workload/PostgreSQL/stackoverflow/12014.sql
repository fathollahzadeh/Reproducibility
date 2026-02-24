
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(p.CreationDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, pt.Name
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Date IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.PostType,
    ps.CommentCount,
    ps.VoteCount,
    ps.LastActivity,
    u.Id AS UserId,
    us.BadgeCount,
    us.TotalBadges
FROM 
    PostStatistics ps
JOIN 
    Users u ON ps.PostId = u.AccountId
JOIN 
    UserStatistics us ON u.Id = us.UserId
ORDER BY 
    ps.VoteCount DESC, ps.LastActivity DESC;
