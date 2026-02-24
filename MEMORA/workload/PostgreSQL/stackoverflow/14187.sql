WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation, u.Views
),

PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
)

SELECT 
    um.UserId,
    um.Reputation,
    um.Views,
    um.PostCount,
    um.CommentCount AS UserCommentCount,
    um.UpVotes,
    um.DownVotes,
    pm.PostId,
    pm.Title,
    pm.ViewCount,
    pm.Score,
    pm.CommentCount AS PostCommentCount,
    pm.VoteCount AS PostVoteCount
FROM 
    UserMetrics um
JOIN 
    PostMetrics pm ON um.UserId = pm.PostId 
ORDER BY 
    um.Reputation DESC, 
    pm.Score DESC;