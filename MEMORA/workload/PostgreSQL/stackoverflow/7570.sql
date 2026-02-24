WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        u.DisplayName AS Owner, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), RecentVotes AS (
    SELECT 
        p.Id AS PostId, 
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month'
    GROUP BY 
        p.Id
), PostComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.ViewCount, 
    rp.Score, 
    rp.Owner, 
    COALESCE(rv.VoteCount, 0) AS VoteCount, 
    COALESCE(pc.CommentCount, 0) AS CommentCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.PostId;