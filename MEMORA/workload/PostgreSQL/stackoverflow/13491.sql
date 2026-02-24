
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(COALESCE(p.Score, 0)) AS TotalPostScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score AS PostScore,
    ps.ViewCount AS PostViews,
    ps.CommentCount,
    ps.VoteCount,
    us.UserId,
    us.DisplayName AS Author,
    us.Reputation AS AuthorReputation,
    us.BadgeCount,
    us.TotalPostScore,
    us.TotalViews
FROM 
    PostStats ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id 
JOIN 
    UserStats us ON u.Id = us.UserId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;
