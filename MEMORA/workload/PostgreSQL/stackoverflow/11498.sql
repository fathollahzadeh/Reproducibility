
WITH PostStats AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        u.Reputation AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
),

PostHistoryStats AS (
    SELECT 
        PostId,
        COUNT(*) AS RevisionCount,
        MAX(CreationDate) AS LastUpdated
    FROM 
        PostHistory
    GROUP BY 
        PostId
)

SELECT 
    ps.PostID,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.BadgeCount,
    ps.UserReputation,
    ph.RevisionCount,
    ph.LastUpdated
FROM 
    PostStats ps
LEFT JOIN 
    PostHistoryStats ph ON ps.PostID = ph.PostId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;
