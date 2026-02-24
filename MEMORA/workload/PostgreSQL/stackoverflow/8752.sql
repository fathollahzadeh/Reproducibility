
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    tp.VoteCount,
    STRING_AGG(t.TagName, ', ') AS Tags,
    COUNT(c.Id) AS CommentCount,
    COUNT(ph.Id) AS EditHistoryCount
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = tp.PostId
LEFT JOIN 
    Comments c ON c.PostId = tp.PostId
LEFT JOIN 
    PostHistory ph ON ph.PostId = tp.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) 
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.OwnerDisplayName, tp.VoteCount
ORDER BY 
    tp.Score DESC, tp.VoteCount DESC;
