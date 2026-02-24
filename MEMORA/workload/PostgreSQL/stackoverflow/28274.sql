
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.Score DESC, p.CreationDate DESC) AS RankWithinLocation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, u.Location
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts 
    WHERE 
        RankWithinLocation <= 10 
)
SELECT 
    tp.OwnerDisplayName,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    COUNT(ph.Id) AS EditCount,
    STRING_AGG(ph.Comment, '; ') AS EditComments
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)
GROUP BY 
    tp.OwnerDisplayName, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
