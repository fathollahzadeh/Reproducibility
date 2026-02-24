
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(AVG(CASE WHEN v.VoteTypeId = 2 THEN 1.0 ELSE 0.0 END), 0) AS UpVotes,
        COALESCE(AVG(CASE WHEN v.VoteTypeId = 3 THEN 1.0 ELSE 0.0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= '2022-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostsCreated,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    us.UserId,
    us.DisplayName AS PostOwner,
    us.Reputation AS OwnerReputation,
    us.PostsCreated,
    us.TotalViews
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.OwnerUserId = us.UserId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;
