WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.Score,
        p.ViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.Score, p.ViewCount, p.PostTypeId
), UserReputation AS (
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
)
SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.OwnerUserId,
    ur.Reputation,
    ur.BadgeCount,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.Score,
    ps.ViewCount
FROM 
    PostStats ps
JOIN 
    UserReputation ur ON ps.OwnerUserId = ur.UserId
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC;