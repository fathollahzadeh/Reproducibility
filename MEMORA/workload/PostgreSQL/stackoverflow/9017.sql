
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, OwnerDisplayName, CommentCount, VoteCount 
    FROM 
        RankedPosts
    WHERE 
        rn = 1
    ORDER BY 
        Score DESC, ViewCount DESC 
    LIMIT 10
)
SELECT 
    tp.*,
    CASE 
        WHEN tp.VoteCount >= 100 THEN 'Highly Voted'
        WHEN tp.CommentCount >= 50 THEN 'Popular Discussion'
        ELSE 'Normal'
    END AS PostCategory
FROM 
    TopPosts tp
JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
WHERE 
    ph.CreationDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' AND TIMESTAMP '2024-10-01 12:34:56'
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
