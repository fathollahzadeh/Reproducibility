
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.PostCreationDate, 
        rp.Score, 
        rp.CommentCount, 
        rp.UpvoteCount, 
        rp.DownvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
)
SELECT 
    t.Title,
    t.PostCreationDate,
    t.Score,
    t.CommentCount,
    t.UpvoteCount,
    t.DownvoteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    TopPosts t
JOIN 
    Users u ON t.PostId = u.Id
WHERE 
    u.Reputation > 1000
ORDER BY 
    t.Score DESC, t.CommentCount DESC;
