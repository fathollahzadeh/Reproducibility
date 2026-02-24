
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        (SELECT COUNT(*) FROM Comments WHERE PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id AND VoteTypeId = 2) AS UpVoteCount
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName
    FROM 
        Users u 
    WHERE 
        u.Reputation > 1000
)
SELECT 
    up.DisplayName,
    wp.Title,
    wp.CreationDate,
    wp.Score,
    wp.ViewCount,
    wp.CommentCount,
    wp.UpVoteCount
FROM 
    RankedPosts wp
JOIN 
    UserReputation up ON wp.PostId = up.UserId
WHERE 
    wp.Rank <= 5
ORDER BY 
    wp.Score DESC, wp.ViewCount DESC;
