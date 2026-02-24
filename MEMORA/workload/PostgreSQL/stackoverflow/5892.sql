
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.*, 
        ht.Name AS HistoryTypeName
    FROM 
        RankedPosts rp
    JOIN 
        PostHistory ph ON rp.PostId = ph.PostId
    JOIN 
        PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
    WHERE 
        rp.RankScore <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.HistoryTypeName,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostLinks pl ON tp.PostId = pl.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.OwnerDisplayName, tp.CommentCount, tp.HistoryTypeName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
