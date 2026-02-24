
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, p.ViewCount
    ORDER BY 
        p.CreationDate DESC
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation
    FROM 
        Users u
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    ur.Reputation,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
ORDER BY 
    rp.ViewCount DESC;
