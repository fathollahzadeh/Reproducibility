
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        u.DisplayName AS OwnerDisplayName, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        CreationDate, 
        Score, 
        ViewCount, 
        RankScore, 
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
),
PostAnalysis AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.CommentCount,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostHistory ph ON tp.PostId = ph.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.OwnerDisplayName,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.CommentCount,
    pa.EditCount,
    pa.LastEditDate
FROM 
    PostAnalysis pa
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC, pa.CommentCount DESC;
