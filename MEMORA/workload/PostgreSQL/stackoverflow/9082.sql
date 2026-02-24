
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        AnswerCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.*, 
    pt.Name AS PostTypeName,
    ht.Name AS PostHistoryTypeName,
    COUNT(ph.Id) AS RevisionCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostTypes pt ON tp.PostId = pt.Id
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.AnswerCount, tp.OwnerDisplayName, pt.Name, ht.Name
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
