WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 3
),
PostCommentCounts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CreationDate,
    u.DisplayName,
    COALESCE(pcc.CommentCount, 0) AS TotalComments,
    ur.Reputation AS UserReputation
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    PostCommentCounts pcc ON tp.PostId = pcc.PostId
INNER JOIN 
    UserReputation ur ON tp.OwnerUserId = ur.UserId
WHERE 
    tp.Score > (SELECT AVG(Score) FROM Posts) 
    AND tp.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
ORDER BY 
    tp.Score DESC
LIMIT 10;